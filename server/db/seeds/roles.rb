# frozen_string_literal: true

puts "Creating default roles..."

# Define the Admin role with full permissions
admin_policies = {
  "permissions" => {
    "connector" => { "read" => true, "create" => true, "update" => true, "delete" => true },
    "model" => { "read" => true, "create" => true, "update" => true, "delete" => true },
    "sync" => { "read" => true, "create" => true, "update" => true, "delete" => true },
    "workspace" => { "read" => true, "create" => true, "update" => true, "delete" => true },
    "workspace_user" => { "read" => true, "create" => true, "update" => true, "delete" => true },
    "role" => { "read" => true, "create" => true, "update" => true, "delete" => true },
    "alert" => { "read" => true, "create" => true, "update" => true, "delete" => true }
  }
}

# Create the Admin role if it doesn't exist
admin_role = Role.find_or_create_by(role_name: "Admin") do |role|
  role.role_desc = "Administrator with full access"
  role.policies = admin_policies
  role.role_type = "system"
end

puts "Admin role #{admin_role.persisted? ? 'created' : 'already exists'}"

# Define the Member role with limited permissions
member_policies = {
  "permissions" => {
    "connector" => { "read" => true, "create" => true, "update" => true, "delete" => false },
    "model" => { "read" => true, "create" => true, "update" => true, "delete" => false },
    "sync" => { "read" => true, "create" => true, "update" => true, "delete" => false },
    "workspace" => { "read" => true, "create" => false, "update" => false, "delete" => false },
    "workspace_user" => { "read" => true, "create" => false, "update" => false, "delete" => false },
    "role" => { "read" => true, "create" => false, "update" => false, "delete" => false },
    "alert" => { "read" => true, "create" => true, "update" => true, "delete" => false }
  }
}

# Create the Member role if it doesn't exist
member_role = Role.find_or_create_by(role_name: "Member") do |role|
  role.role_desc = "Regular member with standard access"
  role.policies = member_policies
  role.role_type = "system"
end

puts "Member role #{member_role.persisted? ? 'created' : 'already exists'}"

# Define the Viewer role with read-only permissions
viewer_policies = {
  "permissions" => {
    "connector" => { "read" => true, "create" => false, "update" => false, "delete" => false },
    "model" => { "read" => true, "create" => false, "update" => false, "delete" => false },
    "sync" => { "read" => true, "create" => false, "update" => false, "delete" => false },
    "workspace" => { "read" => true, "create" => false, "update" => false, "delete" => false },
    "workspace_user" => { "read" => true, "create" => false, "update" => false, "delete" => false },
    "role" => { "read" => true, "create" => false, "update" => false, "delete" => false },
    "alert" => { "read" => true, "create" => false, "update" => false, "delete" => false }
  }
}

# Create the Viewer role if it doesn't exist
viewer_role = Role.find_or_create_by(role_name: "Viewer") do |role|
  role.role_desc = "Viewer with read-only access"
  role.policies = viewer_policies
  role.role_type = "system"
end

puts "Viewer role #{viewer_role.persisted? ? 'created' : 'already exists'}"
