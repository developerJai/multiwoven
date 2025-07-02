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
  end
end
