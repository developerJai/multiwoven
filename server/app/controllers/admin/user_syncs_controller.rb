# frozen_string_literal: true

module Admin
  class UserSyncsController < Admin::BaseController
    before_action :find_user
    before_action :find_sync, only: [:show, :sync_records, :sync_logs]

    def index
      @syncs = Sync.where(workspace_id: @user.workspace_users.pluck(:workspace_id))
      
      # Apply sorting
      sort_column = params[:sort] || 'created_at'
      sort_direction = params[:direction] || 'desc'
      @syncs = @syncs.order("#{sort_column} #{sort_direction}")
      
      # Filter by status if provided
      if params[:status].present?
        @syncs = @syncs.where(status: params[:status])
      end
      
      # Filter by name (stream_name) if provided
      if params[:name].present?
        @syncs = @syncs.where("name ILIKE ?", "%#{params[:name]}%")
      end
      
      # Pagination
      @syncs = @syncs.page(params[:page]).per(20)
    end

    def show
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
    
    def sync_records
      # @sync is already set by the find_sync before_action
      @sync_run = @sync.sync_runs.find(params[:sync_run_id])
      @sync_records = @sync_run.sync_records
      
      # Apply sorting
      sort_column = params[:sort] || 'created_at'
      sort_direction = params[:direction] || 'desc'
      @sync_records = @sync_records.order("#{sort_column} #{sort_direction}")
      
      # Filter by status if provided
      if params[:status].present?
        @sync_records = @sync_records.where(status: params[:status])
      end
      
      # Filter by destination write status if provided
      if params[:destination_write_status].present?
        @sync_records = @sync_records.where(destination_write_status: params[:destination_write_status])
      end
      
      # Get total count before pagination
      @total_records_count = @sync_records.count
      
      # Pagination
      @sync_records = @sync_records.page(params[:page]).per(20)
    end

    def sync_logs
      # @sync is already set by the find_sync before_action
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
      @sync_logs = @sync_logs.page(params[:page]).per(50)
    end

    private

    def find_user
      @user = User.find(params[:user_id])
    end

    def find_sync
      @sync = Sync.find(params[:id])
    end
  end
end
