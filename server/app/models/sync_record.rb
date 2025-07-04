# frozen_string_literal: true

class SyncRecord < ApplicationRecord
  validates :sync_id, presence: true
  validates :sync_run_id, presence: true
  validates :record, presence: true
  validates :fingerprint, presence: true
  validates :action, presence: true
  validates :primary_key, presence: true

  enum :action, %i[destination_insert destination_update]
  enum :status, %i[pending success failed]
  enum :destination_write_status, {
    dest_not_started: 0,
    dest_in_progress: 1,
    dest_written: 2,
    dest_failed: 3,
    dest_skipped: 4
  }, prefix: true

  belongs_to :sync
  belongs_to :sync_run

  scope :written_to_destination, -> { where(destination_write_status: :dest_written) }
  scope :failed_to_write, -> { where(destination_write_status: :dest_failed) }
  scope :not_written, -> { where(destination_write_status: [:dest_not_started, :dest_in_progress]) }
  scope :skipped, -> { where(destination_write_status: :dest_skipped) }

  def mark_as_written!
    update!(
      destination_write_status: :dest_written,
      destination_written_at: Time.current,
      destination_error_message: nil
    )
  end

  def mark_as_write_failed!(error_message)
    update!(
      destination_write_status: :dest_failed,
      destination_written_at: Time.current,
      destination_error_message: error_message
    )
  end

  def mark_as_write_skipped!(reason = nil)
    update!(
      destination_write_status: :dest_skipped,
      destination_written_at: Time.current,
      destination_error_message: reason
    )
  end

  def mark_as_write_in_progress!
    update!(destination_write_status: :dest_in_progress)
  end
end
