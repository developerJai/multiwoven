# frozen_string_literal: true

module ReverseEtl
  module Loaders
    class Standard < Base
      THREAD_COUNT = (ENV["SYNC_LOADER_THREAD_POOL_SIZE"] || "5").to_i
      def write(sync_run_id, activity)
        sync_run = SyncRun.find(sync_run_id)

        return log_error(sync_run) unless sync_run.may_progress?

        # change state queued to in_progress
        sync_run.progress!

        sync = sync_run.sync
        sync_config = sync.to_protocol
        sync_config.sync_run_id = sync_run.id.to_s

        if sync_config.stream.batch_support && !sync_run.test?
          process_batch_records(sync_run, sync, sync_config, activity)
        else
          process_individual_records(sync_run, sync, sync_config, activity)
        end
      end

      private

      def process_individual_records(sync_run, sync, sync_config, activity)
        client = sync.destination.connector_client.new

        sync_run.sync_records.pending.find_in_batches do |sync_records|
          # concurrent request rate limit
          concurrency = sync_config.stream.request_rate_concurrency || THREAD_COUNT
          
          # For Google Sheets, process records serially to avoid race conditions
          # For all other destinations, use parallel processing for better performance
          if sync.destination.connector_name == "GoogleSheets"
            # Process Google Sheets records serially
            sync_run.add_worker_log("Processing #{sync_records.count} individual records serially for Google Sheets")

            sync_records.each_with_index do |sync_record, index|
              sync_run.add_worker_log("Processing individual record #{index + 1}/#{sync_records.count}")

              process_individual_record(sync_record, sync, sync_config, client, sync_run)
            end
          else
            # Use parallel processing for all other destinations
            Parallel.each(sync_records, in_threads: concurrency) do |sync_record|
              process_individual_record(sync_record, sync, sync_config, client, sync_run)
            end
          end

          heartbeat(activity, sync_run)
        end
      end

      # Process a single record (extracted to avoid code duplication)
      def process_individual_record(sync_record, sync, sync_config, client, sync_run)
        # Mark record as in progress for destination write
        sync_record.mark_as_write_in_progress!
        
        transformer = Transformers::UserMapping.new
        record = transformer.transform(sync, sync_record)
        
        begin
          report = handle_response(client.write(sync_config, [record], sync_record.action), sync_run)
          update_sync_record_logs_and_status(report, sync_record)
          
          # Update destination write status based on success/failure
          if report.tracking.success.positive?
            sync_record.mark_as_written!
          else
            error_message = extract_error_message(report)
            sync_record.mark_as_write_failed!(error_message)
          end
        rescue Activities::LoaderActivity::FullRefreshFailed
          raise
        rescue StandardError => e
          # Update destination write status to failed with error message
          sync_record.mark_as_write_failed!(e.message)
          
          Rails.logger.error({
            error_message: e.message,
            sync_run_id: sync_run.id,
            sync_id: sync_run.sync_id,
            stack_trace: Rails.backtrace_cleaner.clean(e.backtrace)
          }.to_s)
        end
      end

      def process_batch_records(sync_run, sync, sync_config, activity)
        transformer = Transformers::UserMapping.new
        client = sync.destination.connector_client.new
        batch_size = sync_config.stream.batch_size

        # track sync record status
        successfull_sync_records = []
        failed_sync_records = []

        # For Google Sheets, process records serially to avoid race conditions
        # For all other destinations, use parallel processing for better performance
        if sync.destination.connector_name == "GoogleSheets"
          # Process Google Sheets records in batches but without parallelism

          total_records = sync_run.sync_records.pending.count
          total_batches = (total_records.to_f / batch_size).ceil
          sync_run.add_worker_log("Total batches to process: #{total_batches} of total #{total_records} records with batch size #{batch_size} maximum records in a batch")

          sync_run.sync_records.pending.find_in_batches(batch_size: batch_size).with_index(1) do |sync_records, batch_number|
            sync_run.add_worker_log("--------batch number #{batch_number} of #{total_batches} with #{sync_records.count} records----------")
            process_batch(sync_records, sync, sync_config, transformer, client, 
                          successfull_sync_records, failed_sync_records, sync_run)
          end
        else
          # Use parallel processing for all other destinations
          Parallel.each(sync_run.sync_records.pending.find_in_batches(batch_size:),
                        in_threads: THREAD_COUNT) do |sync_records|
            process_batch(sync_records, sync, sync_config, transformer, client, 
                          successfull_sync_records, failed_sync_records, sync_run)
          end
        end
        
        update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records)
        heartbeat(activity, sync_run)
      end

      # Process a batch of records (extracted to avoid code duplication)
      def process_batch(sync_records, sync, sync_config, transformer, client, 
                        successfull_sync_records, failed_sync_records, sync_run)
        # Mark all records in batch as in progress for destination write
        sync_record_ids = sync_records.map(&:id)
        SyncRecord.where(id: sync_record_ids).update_all(destination_write_status: :dest_in_progress) # rubocop:disable Rails/SkipsModelValidations
        
        transformed_records = sync_records.map { |sync_record| transformer.transform(sync, sync_record) }
        
        begin
          report = handle_response(client.write(sync_config, transformed_records), sync_run)
          
          if report.tracking.success.zero?
            failed_sync_records.concat(sync_records.map(&:id))
            
            # Extract error message from report if available
            error_message = extract_error_message(report)
            
            # Update destination write status for failed records
            SyncRecord.where(id: sync_records.map(&:id)).update_all( # rubocop:disable Rails/SkipsModelValidations
              destination_write_status: :dest_failed,
              destination_written_at: Time.current,
              destination_error_message: error_message
            )
          else
            successfull_sync_records.concat(sync_records.map(&:id))
            
            # Update destination write status for successful records
            SyncRecord.where(id: sync_records.map(&:id)).update_all( # rubocop:disable Rails/SkipsModelValidations
              destination_write_status: :dest_written,
              destination_written_at: Time.current,
              destination_error_message: nil
            )
          end
        rescue Activities::LoaderActivity::FullRefreshFailed
          raise
        rescue StandardError => e
          failed_sync_records.concat(sync_records.map(&:id))
          
          # Update destination write status for failed records
          SyncRecord.where(id: sync_records.map(&:id)).update_all( # rubocop:disable Rails/SkipsModelValidations
            destination_write_status: :dest_failed,
            destination_written_at: Time.current,
            destination_error_message: e.message
          )
        end
      end

      def handle_response(report, sync_run)
        is_multiwoven_tracking_message = report.is_a?(Multiwoven::Integrations::Protocol::MultiwovenMessage) &&
                                         report.type == "tracking" &&
                                         report.tracking.is_a?(Multiwoven::Integrations::Protocol::TrackingMessage)
        raise_non_retryable_error(report, sync_run) unless is_multiwoven_tracking_message
        report
      end

      def raise_non_retryable_error(report, sync_run)
        sync_run.failed!
        Rails.logger.error({
          error_message: "Full refresh failed type:#{report.control.type} status: #{report.control.status}",
          sync_run_id: sync_run.id,
          stack_trace: nil
        }.to_s)
        raise Activities::LoaderActivity::FullRefreshFailed, "Full refresh failed (non-retryable)"
      end

      def update_sync_record_logs_and_status(report, sync_record)
        status = report.tracking.success.zero? ? "failed" : "success"
        sync_record.update(logs: get_sync_records_logs(report), status:)
      end

      def get_sync_records_logs(report)
        return unless report.tracking.respond_to?(:logs) && report.tracking.logs&.first&.message.present?

        JSON.parse(report.tracking.logs.first.message)
      end

      def update_sync_records_status(sync_run, successfull_sync_records, failed_sync_records)
        sync_run.sync_records.where(id: successfull_sync_records).update_all(status: "success") # rubocop:disable Rails/SkipsModelValidations
        sync_run.sync_records.where(id: failed_sync_records).update_all(status: "failed") # rubocop:disable Rails/SkipsModelValidations
      end
      
      def extract_error_message(report)
        return "Unknown error" unless report.tracking.respond_to?(:logs) && report.tracking.logs&.first&.message.present?
        
        begin
          logs = JSON.parse(report.tracking.logs.first.message)
          return logs.dig("error", "message") || logs.to_s
        rescue JSON::ParserError
          return report.tracking.logs.first.message.to_s
        end
      end

      def heartbeat(activity, sync_run)
        response = activity.heartbeat
        return unless response.cancel_requested

        sync_run.failed!
        Rails.logger.error({
          error_message: "Cancel activity request received",
          sync_run_id: sync_run.id,
          sync_id: sync_run.sync_id,
          stack_trace: nil
        }.to_s)
        raise StandardError, "Cancel activity request received"
      end

      def log_error(sync_run)
        Rails.logger.error({
          error_message: "SyncRun cannot progress from its current state: #{sync_run.status}",
          sync_run_id: sync_run.id,
          stack_trace: nil
        }.to_s)
      end
    end
  end
end