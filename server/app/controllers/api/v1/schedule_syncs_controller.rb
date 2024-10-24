# frozen_string_literal: true

module Api
  module V1
    class ScheduleSyncsController < ApplicationController
      include Syncs
      include AuditLogger
      before_action :set_sync
      before_action :validate_sync_status
      before_action :validate_sync_schedule_type

      after_action :create_audit_log

      def create
        authorize @sync
        result = ScheduleSync.call(sync: @sync)

        if result.success?
          @audit_resource = @sync.name
          render json: { message: "Sync scheduled successfully" }, status: :ok
        else
          render_error(message: result.message, status: result.status)
        end
      end

      def destroy
        authorize @sync
        result = CancelSync.call(sync: @sync)

        if result.success?
          @audit_resource = @sync.name
          render json: { message: "Sync cancelled successfully" }, status: :ok
        else
          render_error(message: result.message, status: result.status)
        end
      end

      private

      def set_sync
        @sync = current_workspace.syncs.find_by(id: params.dig(:schedule_sync, :sync_id) || params[:sync_id])
        render_error(message: "Sync not found", status: :not_found) unless @sync
      end

      def validate_sync_status
        return unless @sync.disabled?

        render_error(message: "Sync is disabled",
                     status: :failed_dependency)
      end

      def create_audit_log
        audit!(resource_id: params[:id], resource: @audit_resource, payload: @payload)
      end

      def validate_sync_schedule_type
        return if @sync.schedule_type == "manual"

        render_error(message: "Sync Schedule type should be manual",
                     status: :failed_dependency)
      end
    end
  end
end
