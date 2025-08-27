output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_domain" {
  description = "Domain of the Cognito User Pool (if created)"
  value       = var.create_user_pool_domain ? aws_cognito_user_pool_domain.main[0].domain : null
}

output "client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.web_client.id
}

output "client_name" {
  description = "Name of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.web_client.name
}

output "admin_iam_user_name" {
  description = "Name of the IAM user for admin operations (if created)"
  value       = var.create_admin_user ? aws_iam_user.cognito_admin[0].name : null
}

output "admin_iam_user_arn" {
  description = "ARN of the IAM user for admin operations (if created)"
  value       = var.create_admin_user ? aws_iam_user.cognito_admin[0].arn : null
}

output "admin_access_key_id" {
  description = "Access key ID for the admin IAM user (if created)"
  value       = var.create_admin_user ? aws_iam_access_key.cognito_admin[0].id : null
  sensitive   = true
}

output "admin_secret_access_key" {
  description = "Secret access key for the admin IAM user (if created)"
  value       = var.create_admin_user ? aws_iam_access_key.cognito_admin[0].secret : null
  sensitive   = true
}

output "cognito_sms_role_arn" {
  description = "ARN of the IAM role for SMS sending"
  value       = aws_iam_role.cognito_sms.arn
}

output "region" {
  description = "AWS region where the User Pool is created"
  value       = var.aws_region
}

output "env_file_content" {
  description = "Content for .env file (save this to .env in the project root)"
  value = <<-EOT
# AWS Cognito Configuration
COGNITO_USER_POOL_ID=${aws_cognito_user_pool.main.id}
COGNITO_CLIENT_ID=${aws_cognito_user_pool_client.web_client.id}
AWS_REGION=${var.aws_region}

# AWS Admin Credentials (for admin scripts only)
AWS_ACCESS_KEY_ID=${var.create_admin_user ? aws_iam_access_key.cognito_admin[0].id : "REPLACE_WITH_YOUR_ACCESS_KEY"}
AWS_SECRET_ACCESS_KEY=${var.create_admin_user ? aws_iam_access_key.cognito_admin[0].secret : "REPLACE_WITH_YOUR_SECRET_KEY"}
EOT
  sensitive = true
}

output "html_config_update" {
  description = "JavaScript configuration to update in public/index.html"
  value = <<-EOT
// Update these lines in public/index.html (around line 284-285):
const cognitoConfig = {
    UserPoolId: '${aws_cognito_user_pool.main.id}',
    ClientId: '${aws_cognito_user_pool_client.web_client.id}'
};
EOT
}

output "sms_sandbox_setup" {
  description = "SMS Sandbox Configuration Instructions"
  value = <<-EOT

⚠️  SMS MFA SETUP REQUIRED (if using SMS) ⚠️

AWS accounts are in SMS Sandbox by default. To use SMS MFA:

1. Add phone numbers to sandbox (manual process):
   aws sns create-sms-sandbox-phone-number --phone-number +1XXXXXXXXXX

2. Enter the verification code you receive:
   aws sns verify-sms-sandbox-phone-number --phone-number +1XXXXXXXXXX --one-time-password XXXXXX

3. Check sandbox status:
   aws sns get-sms-sandbox-account-status

For production:
- Request sandbox removal: AWS Console → SNS → Text messaging → Request production access
- Increase spending limit: aws sns set-sms-attributes --attributes MonthlySpendLimit=10

Alternative: Use TOTP/Authenticator App instead of SMS (recommended for testing)

Note: Terraform CANNOT automate SMS sandbox verification as it requires interactive SMS codes.
EOT
}