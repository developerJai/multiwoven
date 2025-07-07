# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

if ENV['LOAD_SEEDS'] == "true"
  # Load all seed files
  puts "Loading seed files..."

  # Load roles first as they're required for user creation
  require_relative 'seeds/roles'

  # Load billing plans
  require_relative 'seeds/billing_plans'

  # Load super admin last
  require_relative 'seeds/super_admin'

  puts "Seed data loaded successfully!"
else
  puts "Skipping seed data loading. Set LOAD_SEEDS=true to load seed data."
end