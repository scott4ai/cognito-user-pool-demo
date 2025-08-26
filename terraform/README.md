# Terraform Configuration for AWS Cognito User Pool

This Terraform configuration creates a fully configured AWS Cognito User Pool with the specifications required for the demo application.

## Features

- ✅ Email as username with case-insensitive login
- ✅ Complex password policy (12+ chars, all character types)
- ✅ MFA enforcement (SMS and TOTP)
- ✅ 60-day password expiration
- ✅ Immutable email attributes
- ✅ Users created unverified (must verify email/phone)
- ✅ Admin IAM user with necessary permissions
- ✅ No external identity providers (Cognito as IDP)

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create Cognito and IAM resources

## Quick Start

1. **Initialize Terraform:**
```bash
cd terraform
terraform init
```

2. **Configure Variables:**
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
```

3. **Review Changes:**
```bash
terraform plan
```

4. **Apply Configuration:**
```bash
terraform apply
```

5. **Save Outputs:**
```bash
# Generate .env file for the application
terraform output -raw env_file_content > ../.env

# View HTML config update
terraform output html_config_update
```

## Configuration Options

### Basic Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for resources | `us-east-1` |
| `environment` | Environment name | `dev` |
| `app_name` | Application name | `cognito-demo` |
| `user_pool_name` | Cognito User Pool name | `cognito-demo-user-pool` |

### Security Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `allow_self_signup` | Allow users to self-register | `false` |
| `advanced_security_mode` | Security mode (OFF/AUDIT/ENFORCED) | `AUDIT` |
| `track_devices` | Enable device tracking | `true` |
| `deletion_protection` | Prevent accidental deletion | `ACTIVE` |

### Email Configuration

For production, configure SES:

```hcl
email_sending_account = "DEVELOPER"
ses_email_arn        = "arn:aws:ses:us-east-1:123456789012:identity/noreply@example.com"
ses_from_email       = "noreply@example.com"
```

### Admin User

Set `create_admin_user = true` to automatically create an IAM user with permissions for:
- Creating users
- Setting passwords
- Managing user attributes
- Administering MFA settings

## Outputs

The configuration provides these outputs:

- `user_pool_id` - Cognito User Pool ID
- `client_id` - App client ID for authentication
- `admin_access_key_id` - IAM access key (sensitive)
- `admin_secret_access_key` - IAM secret key (sensitive)
- `env_file_content` - Complete .env file content
- `html_config_update` - JavaScript config for the web demo

## Resource Details

### User Pool Configuration

- **Username:** Email address (case-insensitive)
- **Password Policy:**
  - Minimum 12 characters
  - Requires uppercase, lowercase, numbers, symbols
  - Temporary passwords valid for 7 days
- **MFA:** Required, supporting SMS and TOTP
- **Verification:** Users created unverified
- **Attributes:**
  - Email (required, immutable)
  - Phone number (required, mutable)
  - custom:email_immutable flag

### App Client Configuration

- **No Client Secret** (for public SPAs)
- **Token Validity:**
  - Access: 1 hour
  - ID: 1 hour
  - Refresh: 60 days
- **Auth Flows:**
  - USER_SRP_AUTH
  - REFRESH_TOKEN_AUTH
  - USER_PASSWORD_AUTH
  - ADMIN_USER_PASSWORD_AUTH

## Customization

### Lambda Triggers

Enable Lambda triggers by setting:

```hcl
enable_lambda_triggers = true
lambda_triggers = {
  pre_sign_up         = "arn:aws:lambda:..."
  post_authentication = "arn:aws:lambda:..."
}
```

### Analytics

Enable Pinpoint analytics:

```hcl
enable_analytics           = true
analytics_application_id   = "your-pinpoint-app-id"
analytics_role_arn        = "arn:aws:iam::..."
```

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

⚠️ **Warning:** This will permanently delete the User Pool and all users.

## Troubleshooting

### Common Issues

1. **Permission Denied:**
   - Ensure AWS credentials have Cognito and IAM permissions

2. **User Pool Domain Conflict:**
   - Domain names must be globally unique
   - Try a different prefix if creation fails

3. **SMS Configuration:**
   - SMS requires SNS permissions
   - May need to verify phone numbers in SNS sandbox

## Security Best Practices

- Store terraform.tfstate securely (use remote backend)
- Never commit terraform.tfvars with sensitive data
- Rotate admin IAM credentials regularly
- Enable CloudTrail logging for audit
- Use deletion protection in production
- Configure advanced security mode as ENFORCED for production