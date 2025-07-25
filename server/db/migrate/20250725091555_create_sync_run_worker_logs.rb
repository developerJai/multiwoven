class CreateSyncRunWorkerLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :sync_run_worker_logs do |t|
      t.text :log_message
      t.references :sync_run, null: false, foreign_key: true

      t.timestamps
    end
  end
end
