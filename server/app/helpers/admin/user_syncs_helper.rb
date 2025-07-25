# frozen_string_literal: true

module Admin
  module UserSyncsHelper
    def sync_status_color(status)
      case status
      when 'healthy'
        'success'
      when 'pending'
        'warning'
      when 'failed'
        'danger'
      when 'disabled'
        'secondary'
      when 'aborted'
        'dark'
      else
        'info'
      end
    end

    def sync_run_status_color(status)
      case status
      when 'success'
        'success'
      when 'pending', 'started', 'querying', 'queued'
        'warning'
      when 'in_progress'
        'primary'
      when 'failed'
        'danger'
      when 'paused'
        'info'
      when 'canceled'
        'dark'
      else
        'secondary'
      end
    end

    def sync_run_status_info(status)
      case status
      when 'success'
        'Sync Run completed all of the activities successfully'
      when 'pending'
        "Sync Run is not started yet means its not transfered to Temporal Worker to load activities"
      when 'started'
        "Sync Run reached to the temporal worker to load activities: : Workflow Start sync_workflow.rb -> Fetch Sync fetch_sync_activity.rb loads sync from DB. -> Create Sync Run create_sync_run_activity.rb Creates a new SyncRun record in the DB, linked to the Sync"
      when 'querying'
        "Sync Run is in querying: Extracting the data -> Running extractor_activity.rb Fetching all the data from source and for each row a SyncRecord is creating with status: pending"
      when 'queued'
        "Sync Run is in queued to start Loading data using loader_activity.rb"
      when 'in_progress'
        "Sync Run is in in_progress to Load Data Running loader_activity.rb -> Each SyncRecord is processing to send data to the destination"
      when 'failed'
        "Sync Run failed to load data to the destination"
      when 'paused'
        "Sync Run is paused"
      when 'canceled'
        "Sync Run is canceled"
      else
        "Sync Run is in unknown state"
      end
    end
  end
end
