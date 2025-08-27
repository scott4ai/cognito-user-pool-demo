# CloudFormation Deployment for AWS Cognito User Pool

This CloudFormation template creates the same AWS Cognito infrastructure as the Terraform configuration.

## Quick Start

### Deploy via AWS CLI:
```bash
cd cloudformation

# Deploy with default parameters
aws cloudformation create-stack \
  --stack-name cognito-demo-stack \
  --template-body file://cognito-stack.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM

# Monitor stack creation
aws cloudformation describe-stacks \
  --stack-name cognito-demo-stack \
  --query 'Stacks[0].StackStatus'

# Get outputs after creation
aws cloudformation describe-stacks \
  --stack-name cognito-demo-stack \
  --query 'Stacks[0].Outputs'
```

### Deploy via AWS Console:
1. Go to CloudFormation in AWS Console
2. Click "Create Stack" → "With new resources"
3. Upload `cognito-stack.yaml`
4. Fill in parameters or use defaults
5. Check "I acknowledge that AWS CloudFormation might create IAM resources"
6. Create stack

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `Environment` | dev | Environment name (dev/staging/production) |
| `AppName` | cognito-demo | Application name |
| `UserPoolName` | cognito-demo-user-pool | Name for the User Pool |
| `AllowSelfSignup` | false | Allow users to self-register |
| `AdvancedSecurityMode` | AUDIT | Security mode (OFF/AUDIT/ENFORCED) |
| `TrackDevices` | true | Enable device tracking |
| `DeletionProtection` | ACTIVE | Prevent accidental deletion |
| `CreateAdminUser` | true | Create IAM admin user |
| `EmailSendingAccount` | COGNITO_DEFAULT | Email service (COGNITO_DEFAULT/DEVELOPER) |

## Create Admin Users

After stack creation, you can use the Node.js admin registration script:

```bash
# Create admin user (requires REAL, verifiable email and phone)
# Both email and phone will receive verification codes
node scripts/admin-register.js user@example.com +1234567890
```

⚠️ **IMPORTANT**: Use real, verifiable email and phone numbers as both will receive verification codes that must be confirmed.

## Get Configuration for App

After stack creation, get your configuration:

```bash
# Get all outputs
aws cloudformation describe-stacks \
  --stack-name cognito-demo-stack \
  --query 'Stacks[0].Outputs' \
  --output table

# Get specific values for .env file
USER_POOL_ID=$(aws cloudformation describe-stacks \
  --stack-name cognito-demo-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`UserPoolId`].OutputValue' \
  --output text)

CLIENT_ID=$(aws cloudformation describe-stacks \
  --stack-name cognito-demo-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`ClientId`].OutputValue' \
  --output text)

echo "COGNITO_USER_POOL_ID=$USER_POOL_ID"
echo "COGNITO_CLIENT_ID=$CLIENT_ID"
```

## Using SES for Email

To use Amazon SES instead of Cognito default email:

1. Verify your domain/email in SES
2. Update parameters:
```json
{
  "ParameterKey": "EmailSendingAccount",
  "ParameterValue": "DEVELOPER"
},
{
  "ParameterKey": "SESEmailArn",
  "ParameterValue": "arn:aws:ses:region:account:identity/verified@domain.com"
},
{
  "ParameterKey": "SESFromEmail",
  "ParameterValue": "noreply@domain.com"
}
```

## Update Stack

To update an existing stack:

```bash
aws cloudformation update-stack \
  --stack-name cognito-demo-stack \
  --template-body file://cognito-stack.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM
```

## Delete Stack

To delete all resources:

```bash
# First, disable deletion protection if enabled
aws cloudformation update-stack \
  --stack-name cognito-demo-stack \
  --template-body file://cognito-stack.yaml \
  --parameters ParameterKey=DeletionProtection,ParameterValue=INACTIVE \
  --use-previous-template

# Then delete the stack
aws cloudformation delete-stack \
  --stack-name cognito-demo-stack
```

## Differences from Terraform

This CloudFormation template provides identical functionality to the Terraform configuration with these implementation differences:

1. **Random String Generation**: Uses a Lambda function for the external ID
2. **Conditionals**: Uses CloudFormation Conditions instead of Terraform conditionals
3. **Outputs**: Returns similar outputs but formatted for CloudFormation

## Troubleshooting

### Stack Creation Failed
- Check CloudFormation Events tab for specific error
- Ensure you have permissions for IAM operations (CAPABILITY_NAMED_IAM)
- Verify parameter values are valid

### Lambda Function Issues
- The template creates a temporary Lambda for random string generation
- Ensure Lambda service is available in your region

### IAM User Creation
- Requires IAM permissions
- Access keys are shown only once in outputs
- Save them immediately or retrieve via CLI

## Best Practices

1. **Use Parameter Store**: Store sensitive outputs in Parameter Store
```bash
aws ssm put-parameter \
  --name /cognito-demo/user-pool-id \
  --value "$USER_POOL_ID" \
  --type String
```

2. **Tag Resources**: All resources are tagged automatically

3. **Monitor with CloudWatch**: Set up alarms for user pool metrics

4. **Regular Updates**: Keep the stack updated with security patches