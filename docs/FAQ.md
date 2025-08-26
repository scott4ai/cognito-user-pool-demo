# Frequently Asked Questions & Important Information

## VPC Requirements

**Q: Does this solution require a VPC?**

**A: No, AWS Cognito does not require a VPC.** Cognito is a fully managed service that operates outside of your VPC. It's accessible via public AWS APIs and doesn't need VPC configuration, subnets, or security groups.

### When VPCs might be involved:
- **Lambda triggers**: If you use Lambda functions as Cognito triggers and those functions need to access VPC resources
- **API Gateway**: If your application APIs are in a private VPC
- **Application servers**: Your backend services may be in a VPC, but Cognito itself doesn't require it

## Callback URLs Explanation

**Q: What are the callback URLs in the configuration?**

```yaml
callback_urls = [
  "http://localhost:8080/callback",
  "http://localhost:3000/callback"
]
```

**A: These are OAuth 2.0 redirect URIs, but they're NOT used in this demo.**

### Why they're configured:
1. **Future compatibility**: If you later enable OAuth flows or hosted UI
2. **Development flexibility**: Common ports for local development (8080 for general web servers, 3000 for React)
3. **No harm when unused**: They don't affect the direct SDK authentication we're using

### In this demo:
- We use direct Cognito SDK authentication (not OAuth flows)
- The callback URLs are essentially placeholders
- Authentication happens directly in JavaScript without redirects

## User Pool Add-ons & Advanced Security

**Q: What does the advanced_security_mode do?**

```hcl
user_pool_add_ons {
  advanced_security_mode = var.advanced_security_mode  # AUDIT by default
}
```

**A: Advanced Security provides risk-based authentication and protection:**

### Three modes:
1. **OFF**: No advanced security features
2. **AUDIT** (recommended for testing): 
   - Logs security events without blocking
   - Monitor suspicious activities
   - No additional cost for audit logs
3. **ENFORCED** (production):
   - Actively blocks suspicious sign-ins
   - Requires CAPTCHA for risky authentications
   - Additional AWS charges apply

### Features when enabled:
- Compromised credentials detection
- Adaptive authentication
- IP address tracking
- Device fingerprinting
- Risk scoring for sign-in attempts

## Email Registration Strategies

**Q: Which email addresses can I use for testing? How do I handle Cognito's email limits?**

### Testing Email Strategies:

#### 1. **Gmail Plus Addressing** (Recommended)
```
youremail+test1@gmail.com
youremail+test2@gmail.com
youremail+demo1@gmail.com
```
- All deliver to your main Gmail inbox
- Each is treated as unique by Cognito
- Works with other providers supporting plus addressing

#### 2. **Gmail Dot Trick**
```
your.email@gmail.com
y.ouremail@gmail.com
you.remail@gmail.com
```
- Gmail ignores dots, but Cognito sees them as different
- Limited variations possible

#### 3. **Temporary Email Services** (Development only)
- 10minutemail.com
- temp-mail.org
- guerrillamail.com
- **Warning**: Some may be blocked by Cognito

#### 4. **Custom Domain with Catch-all** (Best for teams)
- Set up a domain with catch-all email
- Create unlimited test addresses: test1@yourdomain.com, test2@yourdomain.com
- All emails go to one inbox

### Cognito Email Limits & Solutions:

#### Default Cognito Email Limits:
- **Daily limit**: 50 emails per AWS account (sandbox mode)
- **Verification emails**: Count against this limit
- **Rate limiting**: May stop sending after repeated registrations

#### Solutions to Email Limits:

##### 1. **Configure Amazon SES** (Recommended for production)
```hcl
email_sending_account = "DEVELOPER"
ses_email_arn = "arn:aws:ses:region:account:identity/verified@domain.com"
```
Benefits:
- Much higher sending limits
- Better deliverability
- Custom from addresses
- Detailed analytics

##### 2. **Request Limit Increase**
- Contact AWS Support
- Explain your use case
- Can increase to thousands per day

##### 3. **Admin-Created Users**
```javascript
// Use admin script with MessageAction: 'SUPPRESS'
// No verification email sent
```

##### 4. **Implement Email Verification Bypass** (Dev only)
```javascript
// Admin script marks email as verified
{
  Name: 'email_verified',
  Value: 'false'  // Change to 'true' for testing
}
```

### Preventing Registration Issues:

#### Problem: Cognito stops sending verification emails after multiple attempts

#### Solutions:

1. **Wait Period**
   - Wait 24 hours between registration attempts with same email
   - Cognito has anti-abuse mechanisms

2. **Clean User Deletion**
```bash
aws cognito-idp admin-delete-user \
  --user-pool-id YOUR_POOL_ID \
  --username user@example.com
```

3. **Use Different Email Variations**
   - Rotate through gmail+variations
   - Maintains continuous testing ability

4. **Implement Retry Logic**
```javascript
// In client code
const MAX_RETRIES = 3;
const RETRY_DELAY = 5000; // 5 seconds

async function registerWithRetry(email, password, retries = 0) {
  try {
    await register(email, password);
  } catch (error) {
    if (error.code === 'LimitExceededException' && retries < MAX_RETRIES) {
      await new Promise(resolve => setTimeout(resolve, RETRY_DELAY));
      return registerWithRetry(email, password, retries + 1);
    }
    throw error;
  }
}
```

5. **Development Best Practices**
   - Keep a pool of test emails
   - Document which emails are in use
   - Regular cleanup of test users
   - Use admin creation for predictable testing

## CloudFormation vs Terraform

**Q: Should I use CloudFormation or Terraform?**

### CloudFormation:
- ✅ Native AWS service
- ✅ No additional tools needed
- ✅ IAM integration built-in
- ✅ Stack rollback on failure
- ❌ AWS-only
- ❌ More verbose syntax

### Terraform:
- ✅ Multi-cloud support
- ✅ Cleaner HCL syntax
- ✅ Better state management
- ✅ Extensive community modules
- ❌ Requires Terraform installation
- ❌ State file management needed

### Recommendation:
- **CloudFormation**: If you're AWS-only and want native integration
- **Terraform**: If you need multi-cloud or prefer HCL syntax

## Security Considerations

### MFA Enforcement Timing
- MFA is enforced AFTER email/phone verification
- Users created unverified must verify before MFA setup
- First login flow: Verify → Change Password → Setup MFA

### Password Expiration Implementation
- 60-day expiration via refresh token validity
- After 60 days, users must re-authenticate
- Consider implementing password history to prevent reuse

### Email Immutability
- Email set as `mutable: false` in schema
- Custom attribute `email_immutable` for additional tracking
- Once set, email cannot be changed (security feature)

## Common Issues & Solutions

### Issue: "TooManyRequestsException"
**Solution**: Implement exponential backoff or wait 5 minutes

### Issue: No verification email received
**Solutions**:
1. Check spam folder
2. Verify email sending limits not exceeded
3. Try different email provider
4. Use admin creation with verified flag

### Issue: MFA setup failing
**Solution**: Ensure phone number format includes country code (+1234567890)

### Issue: Password change required loop
**Solution**: Ensure new password meets all complexity requirements

## Production Recommendations

1. **Use SES for emails** - Better reliability and higher limits
2. **Enable CloudTrail** - Audit all Cognito operations
3. **Set up CloudWatch alarms** - Monitor failed logins, user pool limits
4. **Implement rate limiting** - Protect against brute force
5. **Use secrets manager** - Don't hardcode credentials
6. **Enable advanced security** - Set to ENFORCED for production
7. **Regular backups** - Export user data regularly
8. **Test disaster recovery** - Practice user pool restoration