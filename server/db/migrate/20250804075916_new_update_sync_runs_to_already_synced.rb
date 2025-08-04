class NewUpdateSyncRunsToAlreadySynced < ActiveRecord::Migration[7.1]
  def up
    # Safety first - make sure the already_synced status exists
    unless SyncRun.statuses.key?("already_synced")
      puts "Migration skipped: already_synced status does not exist in SyncRun model"
      return
    end

    # Find all SyncRun records where:
    # 1. total_query_rows is positive
    # 2. total_query_rows equals skipped_rows
    # 3. current status is 'success'
    sync_runs_to_update = SyncRun.where("total_query_rows > 0 AND total_query_rows = skipped_rows AND status = ?", SyncRun.statuses[:success])
    
    # Update these records to have the 'already_synced' status
    count = sync_runs_to_update.update_all(status: SyncRun.statuses[:already_synced])
    
    puts "Updated #{count} SyncRun records to 'already_synced' status"
  end

  def down
    # Revert any SyncRun with 'already_synced' status back to 'success'
    unless SyncRun.statuses.key?("already_synced")
      puts "Migration skipped: already_synced status does not exist in SyncRun model"
      return
    end

    count = SyncRun.where(status: SyncRun.statuses[:already_synced]).update_all(status: SyncRun.statuses[:success])
    puts "Reverted #{count} SyncRun records from 'already_synced' to 'success' status"
  end
end
