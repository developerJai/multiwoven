# frozen_string_literal: true

module Admin
  class UserSyncsController < Admin::BaseController
    before_action :find_user
    before_action :find_sync, only: [:show, :sync_show, :sync_records, :sync_run_records, :sync_logs, :sync_run_logs]

    def syncs_index
      @syncs = Sync.all
      load_syncs_data
    end

    def index
      @syncs = Sync.where(workspace_id: @user.workspace_users.pluck(:workspace_id))
      load_syncs_data
    end


    def sync_show
      load_sync_runs_data
    end

    def show
      load_sync_runs_data
    end
    
    def sync_records
      load_sync_run_records_data
    end

    def sync_run_records
      load_sync_run_records_data
    end

    def sync_logs
      load_sync_run_logs_data
    end

    def sync_run_logs
      load_sync_run_logs_data
    end

    private

    def find_user
      @user = User.find_by_id(params[:user_id])
    end

    def find_sync
      @sync = Sync.find(params[:id])
    end

    def load_syncs_data
      # Apply sorting
      sort_column = params[:sort] || 'created_at'
      sort_direction = params[:direction] || 'desc'
      @syncs = @syncs.order("#{sort_column} #{sort_direction}")

      @connectors = Connector.where(connector_type: ['source', 'destination']).pluck(:connector_name).uniq.sort.map { |connector| [connector, connector] }
      @connectors.unshift(['All', ''])
      # Filter by status if provided
      if params[:status].present?
        @syncs = @syncs.where(status: params[:status])
      end
      
      # Filter by name (stream_name) if provided
      if params[:name].present?
        @syncs = @syncs.joins(:source, :destination).where("syncs.name ILIKE (?) OR destinations_syncs.name ILIKE (?) OR connectors.name ILIKE (?)", "%#{params[:name]}%", "%#{params[:name]}%", "%#{params[:name]}%")
      end

      if params[:connector].present?
        @syncs = @syncs.joins(:source, :destination).where("destinations_syncs.connector_name = ? or connectors.connector_name = ?", params[:connector], params[:connector])
      end
      
      # Pagination
      @syncs = @syncs.page(params[:page]).per(50)
    end

    def load_sync_runs_data
      @sync_runs = @sync.sync_runs
      # Apply sorting
      sort_column = params[:sort] || 'created_at'
      sort_direction = params[:direction] || 'desc'
      @sync_runs = @sync_runs.order("#{sort_column} #{sort_direction}")
      
      # Filter by status if provided
      if params[:status].present?
        @sync_runs = @sync_runs.where(status: params[:status])
      end
      
      # Pagination
      @sync_runs = @sync_runs.page(params[:page]).per(20)
      
      # Get status sequence information
      @status_sequence = SyncRun.statuses.keys
      @current_status_index = @status_sequence.index(@sync_runs.first.status) if @sync_runs.first
    end

    def load_sync_run_records_data
      @sync_run = @sync.sync_runs.find(params[:sync_run_id])
      @sync_records = @sync_run.sync_records

      # Filter by status if provided
      if params[:status].present?
        @sync_records = @sync_records.where(status: params[:status])
      end
      
      # Filter by destination write status if provided
      if params[:destination_write_status].present?
        @sync_records = @sync_records.where(destination_write_status: params[:destination_write_status])
      end
      
      # Apply sorting
      sort_column = params[:sort] || 'created_at'
      sort_direction = params[:direction] || 'desc'
      @sync_records = @sync_records.order("#{sort_column} #{sort_direction}")

      # Get total count before pagination
      @total_records_count = @sync_records.count
      
      # Pagination
      @sync_records = @sync_records.page(params[:page]).per(20)
    end

    def load_sync_run_logs_data
      @sync_run = @sync.sync_runs.find(params[:sync_run_id])
      @sync_logs = @sync_run.sync_run_worker_logs
      
      # Apply sorting
      sort_column = params[:sort] || 'created_at'
      sort_direction = params[:direction] || 'asc'
      @sync_logs = @sync_logs.order("#{sort_column} #{sort_direction}")
      
      # Filter by log level if provided
      if params[:log_message].present?
        @sync_logs = @sync_logs.where("log_message ILIKE ?", "%#{params[:log_message]}%")
      end
      
      # Get total count before pagination
      @total_logs_count = @sync_logs.count
      
      # Pagination
      @sync_logs = @sync_logs.page(params[:page]).per(params[:per_page] || 50)
    end
  end
end
