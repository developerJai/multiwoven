# frozen_string_literal: true

class AddDestinationWriteStatusToSyncRecords < ActiveRecord::Migration[7.0]
  def change
    add_column :sync_records, :destination_write_status, :integer, default: 0
    add_column :sync_records, :destination_error_message, :text
    add_column :sync_records, :destination_written_at, :datetime
  end
end
