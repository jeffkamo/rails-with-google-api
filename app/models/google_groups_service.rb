require 'google/apis/admin_directory_v1'
require 'googleauth'

class GoogleGroupsService
  Admin = Google::Apis::AdminDirectoryV1

  # Custom error classes for better error handling
  class AuthenticationError < StandardError; end
  class GroupNotFoundError < StandardError; end
  class PermissionError < StandardError; end
  class APIError < StandardError; end

  def initialize(user_email)
    @user_email = user_email
    @service = Admin::DirectoryService.new
    @service.authorization = authorize
  rescue => e
    raise AuthenticationError, "Failed to initialize Google Groups service: #{e.message}"
  end

  def list_group_members(group_email)
    validate_group_email(group_email)
    
    members = []
    page_token = nil
    
    begin
      response = @service.list_members(group_email, page_token: page_token)
      members.concat(response.members) if response.members
      page_token = response.next_page_token
    end while page_token
    
    members
  rescue Google::Apis::ClientError => e
    handle_google_api_error(e)
  rescue Google::Apis::ServerError => e
    raise APIError, "Google API server error: #{e.message}"
  rescue Google::Apis::AuthorizationError => e
    raise PermissionError, "Authorization failed: #{e.message}"
  rescue => e
    raise APIError, "Unexpected error: #{e.message}"
  end

  private

  def authorize
    scopes = ['https://www.googleapis.com/auth/admin.directory.group.readonly']
    
    # Validate that credentials exist
    unless Rails.application.credentials.google&.service_account
      raise AuthenticationError, "Google service account credentials not found in Rails credentials"
    end
    
    service_account_creds = Rails.application.credentials.google.service_account
    
    # Create credentials object from the stored credentials
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(service_account_creds.to_json),
      scope: scopes
    )
    
    # Set the user to impersonate (domain-wide delegation)
    authorizer.sub = @user_email
    authorizer.fetch_access_token!
    authorizer
  rescue Google::Auth::Error => e
    raise AuthenticationError, "Google authentication failed: #{e.message}"
  rescue => e
    raise AuthenticationError, "Failed to authorize service account: #{e.message}"
  end

  def validate_group_email(email)
    unless email&.include?('@')
      raise ArgumentError, "Invalid group email format: #{email}"
    end
  end

  def handle_google_api_error(error)
    case error.status_code
    when 400
      raise ArgumentError, "Invalid request: #{error.message}"
    when 401
      raise PermissionError, "Unauthorized: #{error.message}"
    when 403
      if error.message.include?('not found')
        raise GroupNotFoundError, "Google Group not found or access denied: #{error.message}"
      else
        raise PermissionError, "Access forbidden: #{error.message}"
      end
    when 404
      raise GroupNotFoundError, "Google Group not found: #{error.message}"
    when 429
      raise APIError, "Rate limit exceeded: #{error.message}"
    when 500..599
      raise APIError, "Google API server error (#{error.status_code}): #{error.message}"
    else
      raise APIError, "Google API error (#{error.status_code}): #{error.message}"
    end
  end
end
