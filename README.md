# AWS Cognito Authentication Demo

A thin JavaScript application demonstrating AWS Cognito user pool integration with admin registration and client authentication capabilities. React-compatible but implemented in vanilla JavaScript.

## Features

- **Direct Cognito Integration** - Cognito as IDP, not broker
- **Immutable Email Identity** - Email as primary identifier
- **Complex Password Policy** - 12+ chars, uppercase, lowercase, numbers, symbols
- **Password Expiration** - 60-day rotation requirement
- **Multi-Factor Authentication** - SMS and TOTP support
- **Admin User Registration** - Creates unverified users requiring email/phone verification
- **Client Authentication** - Full auth flow with MFA

## Prerequisites

1. AWS Account with Cognito User Pool configured
2. Node.js 18+ installed
3. AWS CLI configured (for admin operations)

## Cognito User Pool Setup

Choose one of three options to set up your Cognito User Pool:

### Option 1: Using Terraform

Use the provided Terraform configuration to automatically provision your Cognito User Pool:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

terraform init
terraform plan
terraform apply

# Save the outputs for your .env file
terraform output -raw env_file_content > ../.env
```

### Option 2: Using CloudFormation

Deploy using AWS CloudFormation:

```bash
cd cloudformation

# Deploy the stack
aws cloudformation create-stack \
  --stack-name cognito-demo-stack \
  --template-body file://cognito-stack.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM

# Get outputs after creation
aws cloudformation describe-stacks \
  --stack-name cognito-demo-stack \
  --query 'Stacks[0].Outputs'
```

### Option 3: Manual Setup

Configure your User Pool with:

1. **Sign-in Options:**
   - Email as username
   - Case insensitive email

2. **Password Policy:**
   - Minimum length: 12
   - Require uppercase, lowercase, numbers, symbols
   - Temporary password validity: 7 days

3. **MFA Configuration:**
   - MFA required
   - SMS and TOTP methods enabled

4. **Account Recovery:**
   - Email only (no phone)

5. **Attributes:**
   - Required: email, phone_number
   - Email and phone verification required (users created unverified)

6. **App Client Settings:**
   - No secret key (for public client)
   - Auth flows: USER_SRP_AUTH, ALLOW_REFRESH_TOKEN_AUTH

## Installation

```bash
# Clone and install dependencies
npm install

# Copy environment template
cp .env.example .env

# Edit .env with your Cognito configuration
```

## Configuration

Update `.env` with your Cognito details:

```env
COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
COGNITO_CLIENT_ID=XXXXXXXXXXXXXXXXXXXXXXXXXX
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

For the HTML demo, update `public/index.html` lines 284-285:
```javascript
const cognitoConfig = {
    UserPoolId: 'YOUR_USER_POOL_ID',
    ClientId: 'YOUR_CLIENT_ID'
};
```

## Usage

### Admin User Registration

Register users with temporary passwords (unverified):

```bash
npm run admin:register
```

This script:
- Creates an unverified user with email and phone
- Generates secure temporary password
- Marks email as immutable
- Suppresses welcome emails
- User must verify email and phone before use
- User must change password on first login

### Client Authentication

Test the authentication flow:

```bash
npm run client:auth
```

Options:
1. **Sign In** - Full auth with MFA
2. **Refresh Session** - Token renewal
3. **Sign Out** - Clear session

### Web Demo

Launch the browser-based demo:

```bash
npm run serve
```

Visit http://localhost:8080/public/

Features:
- Sign in with email/password
- First-time password change
- MFA setup and verification
- Session management
- Token display

## Project Structure

```
cognito-demo/
├── config/
│   └── cognito-config.js      # Cognito configuration
├── scripts/
│   ├── admin-register.js      # Admin user registration
│   └── client-auth.js         # Client authentication
├── public/
│   └── index.html             # Web demo interface
├── terraform/                 # Terraform deployment option
│   ├── main.tf                # Terraform Cognito resources
│   ├── variables.tf           # Terraform variables
│   ├── outputs.tf             # Terraform outputs
│   └── terraform.tfvars.example # Example configuration
├── cloudformation/            # CloudFormation deployment option
│   ├── cognito-stack.yaml    # CloudFormation template
│   └── parameters.json       # Stack parameters
├── docs/
│   └── FAQ.md                # Detailed FAQ and troubleshooting
├── package.json              # Dependencies
├── .env.example             # Environment template
└── README.md                # Documentation
```

## React Integration

This demo uses vanilla JavaScript but is React-compatible. To integrate:

1. Install the same dependencies in your React app
2. Import authentication modules:
```javascript
import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';
```
3. Use the authentication logic in React components
4. Store tokens in context or state management
5. Add route protection with auth checks

## Security Notes

- Never commit `.env` files
- Use AWS IAM roles in production
- Store tokens securely (httpOnly cookies recommended)
- Implement token refresh before expiration
- Add rate limiting for auth attempts
- Use HTTPS in production
- Rotate admin credentials regularly

## Authentication Flow

1. **Initial Sign-In (Unverified Users):**
   - Enter email/password
   - Verify email and phone if not verified
   - Handle newPasswordRequired (first login)
   - Complete MFA setup
   - Receive tokens

2. **Subsequent Sign-Ins:**
   - Enter email/password
   - Complete MFA challenge
   - Receive tokens

3. **Token Management:**
   - Access token: API authorization
   - ID token: User identity
   - Refresh token: Session renewal

## Important Information

### VPC Requirements
**This solution does NOT require a VPC.** Cognito is a fully managed service accessible via public APIs.

### Email Testing Strategies
For testing without hitting Cognito email limits:
- Use Gmail plus addressing: `youremail+test1@gmail.com`
- Configure Amazon SES for higher limits
- See `docs/FAQ.md` for detailed email strategies

### Security Features Explained
- **Callback URLs**: Configured for future OAuth compatibility (not used in SDK auth)
- **Advanced Security Mode**: Set to AUDIT for monitoring, ENFORCED for production
- **MFA Timing**: Enforced after email/phone verification

## Troubleshooting

- **InvalidParameterException:** Check User Pool configuration
- **UserNotFoundException:** Verify user exists and email format
- **NotAuthorizedException:** Check password or MFA code
- **ExpiredCodeException:** Request new verification code
- **TooManyRequestsException:** Rate limit hit, wait before retry
- **No verification email:** Check `docs/FAQ.md` for email limit solutions

## Additional Documentation

- **[Detailed FAQ](docs/FAQ.md)** - Comprehensive answers about VPC, emails, security
- **[Terraform Guide](terraform/README.md)** - Infrastructure as Code with Terraform
- **[CloudFormation Guide](cloudformation/README.md)** - AWS native deployment

## License

MIT