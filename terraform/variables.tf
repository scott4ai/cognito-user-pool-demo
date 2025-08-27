variable "aws_region" {
  description = "AWS region for the Cognito User Pool"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "cognito-demo"
}

variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
  default     = "cognito-demo-user-pool"
}

variable "user_pool_domain" {
  description = "Domain prefix for the Cognito User Pool (must be unique across all AWS)"
  type        = string
  default     = ""
}

variable "create_user_pool_domain" {
  description = "Whether to create a Cognito User Pool domain"
  type        = bool
  default     = false
}

variable "allow_self_signup" {
  description = "Whether to allow users to sign up themselves (false = admin-only)"
  type        = bool
  default     = false
}

variable "email_sending_account" {
  description = "Email sending account type (COGNITO_DEFAULT or DEVELOPER)"
  type        = string
  default     = "COGNITO_DEFAULT"
  
  validation {
    condition     = contains(["COGNITO_DEFAULT", "DEVELOPER"], var.email_sending_account)
    error_message = "Email sending account must be either COGNITO_DEFAULT or DEVELOPER."
  }
}

variable "ses_email_arn" {
  description = "SES email identity ARN (required if email_sending_account is DEVELOPER)"
  type        = string
  default     = ""
}

variable "ses_from_email" {
  description = "From email address for SES (required if email_sending_account is DEVELOPER)"
  type        = string
  default     = ""
}

variable "ses_reply_to_email" {
  description = "Reply-to email address for SES"
  type        = string
  default     = ""
}

variable "callback_urls" {
  description = "List of allowed callback URLs for the app client"
  type        = list(string)
  default     = ["http://localhost:8080/callback", "http://localhost:3000/callback"]
}

variable "logout_urls" {
  description = "List of allowed logout URLs for the app client"
  type        = list(string)
  default     = ["http://localhost:8080/", "http://localhost:3000/"]
}

variable "advanced_security_mode" {
  description = "Advanced security mode (OFF, AUDIT, or ENFORCED)"
  type        = string
  default     = "AUDIT"
  
  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.advanced_security_mode)
    error_message = "Advanced security mode must be OFF, AUDIT, or ENFORCED."
  }
}

variable "track_devices" {
  description = "Whether to track devices for added security"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the User Pool. Set to INACTIVE for development/testing to allow easy cleanup"
  type        = string
  default     = "INACTIVE"
  
  validation {
    condition     = contains(["ACTIVE", "INACTIVE"], var.deletion_protection)
    error_message = "Deletion protection must be either ACTIVE or INACTIVE."
  }
}

variable "create_admin_user" {
  description = "Whether to create an IAM user for admin operations"
  type        = bool
  default     = true
}

variable "enable_lambda_triggers" {
  description = "Whether to enable Lambda triggers"
  type        = bool
  default     = false
}

variable "lambda_triggers" {
  description = "Lambda function ARNs for various Cognito triggers"
  type = object({
    pre_sign_up                    = optional(string)
    custom_message                 = optional(string)
    post_authentication            = optional(string)
    post_confirmation              = optional(string)
    pre_authentication             = optional(string)
    define_auth_challenge          = optional(string)
    create_auth_challenge          = optional(string)
    verify_auth_challenge_response = optional(string)
    user_migration                 = optional(string)
    pre_token_generation           = optional(string)
  })
  default = {}
}

variable "enable_analytics" {
  description = "Whether to enable analytics configuration"
  type        = bool
  default     = false
}

variable "analytics_application_id" {
  description = "Application ID for analytics"
  type        = string
  default     = ""
}

variable "analytics_application_arn" {
  description = "Application ARN for analytics"
  type        = string
  default     = ""
}

variable "analytics_role_arn" {
  description = "IAM role ARN for analytics"
  type        = string
  default     = ""
}

variable "analytics_user_data_shared" {
  description = "Whether to share user data with analytics"
  type        = bool
  default     = false
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "CognitoDemo"
    ManagedBy = "Terraform"
  }
}