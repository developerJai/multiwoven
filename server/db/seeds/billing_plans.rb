# frozen_string_literal: true

puts "Creating default billing plans..."

# Check if the Billing::Plan model exists
if defined?(Billing::Plan)
  # Create the Starter plan if it doesn't exist
  starter_plan = Billing::Plan.find_or_create_by(name: "Starter") do |plan|
    plan.amount = 0 # Free plan
    plan.interval = "month"
    plan.status = "active"
    plan.currency = "usd"
    
    # Set limits
    plan.max_rows_synced = 10000
    plan.max_feedback_count = 100
    
    # Add any additional settings in the addons JSON field
    plan.addons = {
      max_sources: 3,
      max_destinations: 3,
      max_syncs: 3
    }
  end

  puts "Starter plan #{starter_plan.persisted? ? 'created' : 'already exists'}"
else
  puts "Billing::Plan model not found. Skipping billing plan creation."
end
