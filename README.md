# Google Groups API - Usage Guide

This guide explains how to use the `GoogleGroupsService` class to retrieve Google Groups members via the Rails console.

## Prerequisites

- ✅ Google Cloud Project with Admin SDK API enabled
- ✅ Service account with domain-wide delegation configured
- ✅ Google Workspace domain with admin privileges
- ✅ Service account credentials stored in Rails encrypted credentials

## Basic Usage

### 1. Open Rails Console

```bash
cd /path/to/your/rails-app
bin/rails console
```

### 2. Initialize the Service

```ruby
# Replace with an actual admin email from your Google Workspace domain
admin_email = 'admin@yourdomain.com'
service = GoogleGroupsService.new(admin_email)
```

### 3. List Group Members

```ruby
# Replace with an actual Google Group email
group_email = 'your-group@yourdomain.com'
members = service.list_group_members(group_email)

# Display results
members.each do |member|
  puts "#{member.email} - Role: #{member.role}"
end
```

## Complete Example

```ruby
# In Rails console
begin
  # Initialize service with admin email
  service = GoogleGroupsService.new('admin@yourdomain.com')
  
  # Get members of a specific group
  group_email = 'marketing-team@yourdomain.com'
  members = service.list_group_members(group_email)
  
  puts "Found #{members.count} members in #{group_email}:"
  members.each_with_index do |member, index|
    puts "#{index + 1}. #{member.email} (#{member.role})"
  end
  
rescue GoogleGroupsService::GroupNotFoundError => e
  puts "❌ Group not found: #{e.message}"
rescue GoogleGroupsService::PermissionError => e
  puts "❌ Permission denied: #{e.message}"
rescue GoogleGroupsService::AuthenticationError => e
  puts "❌ Authentication failed: #{e.message}"
rescue GoogleGroupsService::APIError => e
  puts "❌ API error: #{e.message}"
end
```

## Error Handling

The service provides specific error classes for different failure scenarios:

### Error Types

- **`GoogleGroupsService::AuthenticationError`** - Credential or authentication issues
- **`GoogleGroupsService::GroupNotFoundError`** - Group doesn't exist or isn't accessible
- **`GoogleGroupsService::PermissionError`** - Insufficient permissions
- **`GoogleGroupsService::APIError`** - General API failures

### Common Error Scenarios

```ruby
# Group not found
begin
  service = GoogleGroupsService.new('admin@yourdomain.com')
  members = service.list_group_members('nonexistent-group@yourdomain.com')
rescue GoogleGroupsService::GroupNotFoundError => e
  puts "Group doesn't exist: #{e.message}"
end

# Permission denied
begin
  service = GoogleGroupsService.new('regular-user@yourdomain.com')  # Not an admin
  members = service.list_group_members('some-group@yourdomain.com')
rescue GoogleGroupsService::PermissionError => e
  puts "Need admin privileges: #{e.message}"
end

# Invalid email format
begin
  service = GoogleGroupsService.new('admin@yourdomain.com')
  members = service.list_group_members('invalid-email-format')
rescue ArgumentError => e
  puts "Invalid email: #{e.message}"
end
```

## Member Object Properties

Each member object returned by `list_group_members` has the following properties:

```ruby
members = service.list_group_members('your-group@yourdomain.com')
members.each do |member|
  puts "Email: #{member.email}"
  puts "Role: #{member.role}"           # e.g., "MEMBER", "MANAGER", "OWNER"
  puts "Type: #{member.type}"           # e.g., "USER", "GROUP", "CUSTOMER"
  puts "Status: #{member.status}"       # e.g., "ACTIVE", "SUSPENDED"
  puts "Delivery Settings: #{member.delivery_settings}" if member.delivery_settings
  puts "---"
end
```

## Advanced Usage

### Filtering Members by Role

```ruby
members = service.list_group_members('your-group@yourdomain.com')

# Get only managers and owners
managers = members.select { |m| ['MANAGER', 'OWNER'].include?(m.role) }
puts "Managers and Owners: #{managers.map(&:email).join(', ')}"

# Get only regular members
regular_members = members.select { |m| m.role == 'MEMBER' }
puts "Regular Members: #{regular_members.map(&:email).join(', ')}"
```

### Counting Members by Type

```ruby
members = service.list_group_members('your-group@yourdomain.com')

# Count by member type
type_counts = members.group_by(&:type).transform_values(&:count)
puts "Member types: #{type_counts}"

# Count by role
role_counts = members.group_by(&:role).transform_values(&:count)
puts "Roles: #{role_counts}"
```

## Troubleshooting

### Common Issues

1. **"Client is unauthorized" error**
   - Verify domain-wide delegation is configured correctly
   - Check that the OAuth scope is set to `https://www.googleapis.com/auth/admin.directory.group.readonly`
   - Ensure the service account has the correct Client ID

2. **"Group not found" error**
   - Verify the group email address is correct
   - Check that the group exists in your Google Workspace
   - Ensure the admin user has access to the group

3. **"Permission denied" error**
   - Verify the user email is from your Google Workspace domain
   - Check that the user has admin privileges
   - Ensure the service account has proper domain-wide delegation

### Debug Mode

To get more detailed error information, you can catch and inspect the full error:

```ruby
begin
  service = GoogleGroupsService.new('admin@yourdomain.com')
  members = service.list_group_members('your-group@yourdomain.com')
rescue => e
  puts "Error class: #{e.class}"
  puts "Error message: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
end
```

## Security Notes

- Never commit the service account JSON key file to version control
- Use Rails encrypted credentials to store sensitive information
- Regularly rotate service account keys
- Use the principle of least privilege for service account permissions
- Monitor API usage and set up alerts for unusual activity

## Support

If you encounter issues not covered in this guide:

1. Check the Google Admin SDK API documentation
2. Verify your Google Workspace admin console settings
3. Review the Rails application logs for detailed error messages
4. Ensure all prerequisites are properly configured
