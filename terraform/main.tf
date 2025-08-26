terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.default_tags
  }
}

resource "aws_cognito_user_pool" "main" {
  name = var.user_pool_name

  # Username configuration - Email as username
  username_attributes      = ["email"]
  auto_verified_attributes = [] # No auto-verification - users must verify
  
  # Case insensitive email
  username_configuration {
    case_sensitive = false
  }

  # Password policy - Complex requirements
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # MFA Configuration
  mfa_configuration = "ON"
  
  software_token_mfa_configuration {
    enabled = true
  }

  sms_configuration {
    external_id    = "cognito-sms-external-id-${random_string.external_id.result}"
    sns_caller_arn = aws_iam_role.cognito_sms.arn
    sns_region     = var.aws_region
  }

  # Account recovery - Email only
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Email configuration
  email_configuration {
    email_sending_account = var.email_sending_account
    
    # Use SES if specified
    source_arn            = var.email_sending_account == "DEVELOPER" ? var.ses_email_arn : null
    from_email_address    = var.email_sending_account == "DEVELOPER" ? var.ses_from_email : null
    reply_to_email_address = var.email_sending_account == "DEVELOPER" ? var.ses_reply_to_email : null
  }

  # User attribute schema
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = false  # Immutable email
    developer_only_attribute = false
    
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                     = "phone_number"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false
    
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  # Custom attribute for email immutability flag
  schema {
    name                     = "email_immutable"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false
    
    string_attribute_constraints {
      min_length = 0
      max_length = 256
    }
  }

  # Admin create user config - Users created unverified
  admin_create_user_config {
    allow_admin_create_user_only = var.allow_self_signup ? false : true
    
    invite_message_template {
      email_subject = "Your temporary password for ${var.app_name}"
      email_message = "Your username is {username} and temporary password is {####}. Please change it on first login and verify your email."
      sms_message   = "Your username is {username} and temporary password is {####}"
    }
  }

  # Verification message templates
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Verify your email for ${var.app_name}"
    email_message        = "Your verification code is {####}"
    sms_message          = "Your verification code is {####}"
  }

  # User pool add-ons
  user_pool_add_ons {
    advanced_security_mode = var.advanced_security_mode
  }

  # Device tracking
  device_configuration {
    challenge_required_on_new_device      = var.track_devices
    device_only_remembered_on_user_prompt = false
  }

  # Lambda triggers (optional)
  dynamic "lambda_config" {
    for_each = var.enable_lambda_triggers ? [1] : []
    
    content {
      pre_sign_up                    = var.lambda_triggers.pre_sign_up
      custom_message                 = var.lambda_triggers.custom_message
      post_authentication            = var.lambda_triggers.post_authentication
      post_confirmation              = var.lambda_triggers.post_confirmation
      pre_authentication             = var.lambda_triggers.pre_authentication
      define_auth_challenge          = var.lambda_triggers.define_auth_challenge
      create_auth_challenge          = var.lambda_triggers.create_auth_challenge
      verify_auth_challenge_response = var.lambda_triggers.verify_auth_challenge_response
      user_migration                 = var.lambda_triggers.user_migration
      pre_token_generation           = var.lambda_triggers.pre_token_generation
    }
  }

  # Deletion protection
  deletion_protection = var.deletion_protection

  tags = merge(
    var.default_tags,
    {
      Name        = var.user_pool_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_cognito_user_pool_client" "web_client" {
  name         = "${var.app_name}-web-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # No client secret for public clients (SPA/Mobile)
  generate_secret = false

  # Refresh token expiration - 60 days to match password expiration
  refresh_token_validity = 60
  
  # Access token expiration - 1 hour
  access_token_validity = 1
  
  # ID token expiration - 1 hour  
  id_token_validity = 1

  # Token validity units
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # OAuth flows disabled (using direct Cognito SDK)
  allowed_oauth_flows                  = []
  allowed_oauth_flows_user_pool_client = false
  allowed_oauth_scopes                 = []
  
  # Callback URLs (not used for direct SDK integration)
  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  # Supported identity providers
  supported_identity_providers = ["COGNITO"]

  # Explicit auth flows for SDK
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Read and write attributes
  read_attributes = [
    "email",
    "email_verified",
    "phone_number",
    "phone_number_verified",
    "custom:email_immutable"
  ]

  write_attributes = [
    "email",
    "phone_number"
  ]

  # Enable token revocation
  enable_token_revocation = true
  
  # Enable propagate additional user context data
  enable_propagate_additional_user_context_data = false

  # Analytics configuration (optional)
  dynamic "analytics_configuration" {
    for_each = var.enable_analytics ? [1] : []
    
    content {
      application_id   = var.analytics_application_id
      application_arn  = var.analytics_application_arn
      external_id      = "analytics-external-id-${random_string.external_id.result}"
      role_arn         = var.analytics_role_arn
      user_data_shared = var.analytics_user_data_shared
    }
  }

  depends_on = [aws_cognito_user_pool.main]
}

resource "aws_cognito_user_pool_domain" "main" {
  count = var.create_user_pool_domain ? 1 : 0
  
  domain       = var.user_pool_domain
  user_pool_id = aws_cognito_user_pool.main.id
}

# IAM role for SMS sending
resource "aws_iam_role" "cognito_sms" {
  name = "${var.user_pool_name}-cognito-sms-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cognito-idp.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "cognito-sms-external-id-${random_string.external_id.result}"
          }
        }
      }
    ]
  })

  tags = var.default_tags
}

resource "aws_iam_role_policy" "cognito_sms" {
  name = "${var.user_pool_name}-cognito-sms-policy"
  role = aws_iam_role.cognito_sms.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

# Random string for external IDs
resource "random_string" "external_id" {
  length  = 16
  special = false
}

# Optional: Admin IAM user for admin operations
resource "aws_iam_user" "cognito_admin" {
  count = var.create_admin_user ? 1 : 0
  
  name = "${var.user_pool_name}-admin"
  path = "/cognito/"

  tags = merge(
    var.default_tags,
    {
      Purpose = "Cognito Admin Operations"
    }
  )
}

resource "aws_iam_user_policy" "cognito_admin" {
  count = var.create_admin_user ? 1 : 0
  
  name = "${var.user_pool_name}-admin-policy"
  user = aws_iam_user.cognito_admin[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminDeleteUser",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminSetUserPassword",
          "cognito-idp:AdminSetUserMFAPreference",
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminListGroupsForUser",
          "cognito-idp:AdminAddUserToGroup",
          "cognito-idp:AdminRemoveUserFromGroup",
          "cognito-idp:AdminResetUserPassword",
          "cognito-idp:AdminEnableUser",
          "cognito-idp:AdminDisableUser",
          "cognito-idp:AdminConfirmSignUp",
          "cognito-idp:ListUsers",
          "cognito-idp:ListGroups"
        ]
        Resource = aws_cognito_user_pool.main.arn
      }
    ]
  })
}

resource "aws_iam_access_key" "cognito_admin" {
  count = var.create_admin_user ? 1 : 0
  
  user = aws_iam_user.cognito_admin[0].name
}