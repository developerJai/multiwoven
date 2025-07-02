# frozen_string_literal: true

module Admin
  class UserSyncsController < Admin::BaseController
    before_action :find_user
    before_action :find_sync, only: [:show, :sync_records]

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
        @syncs = @syncs.where("stream_name ILIKE ?", "%#{params[:name]}%")
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
      @sync_run = SyncRun.find(params[:sync_run_id])
      @sync_records = @sync_run.sync_records
      
      # Apply sorting
      sort_column = params[:sort] || 'created_at'
      sort_direction = params[:direction] || 'desc'
      @sync_records = @sync_records.order("#{sort_column} #{sort_direction}")
      
      # Filter by status if provided
      if params[:status].present?
        @sync_records = @sync_records.where(status: params[:status])
      end
      
      # Get total count before pagination
      @total_records_count = @sync_records.count
      
      # Pagination
      @sync_records = @sync_records.page(params[:page]).per(20)
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
