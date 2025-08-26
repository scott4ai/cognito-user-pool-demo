import { CognitoIdentityProviderClient, AdminCreateUserCommand, AdminSetUserPasswordCommand, AdminUpdateUserAttributesCommand } from '@aws-sdk/client-cognito-identity-provider';
import { adminConfig } from '../config/cognito-config.js';
import readline from 'readline';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const question = (query) => new Promise((resolve) => rl.question(query, resolve));

class AdminUserRegistration {
  constructor() {
    this.client = new CognitoIdentityProviderClient({
      region: adminConfig.region,
      credentials: adminConfig.credentials
    });
  }

  generateSecurePassword() {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#$%^&*()_+-=[]{}|;:,.<>?';
    const all = uppercase + lowercase + numbers + symbols;
    
    let password = '';
    password += uppercase[Math.floor(Math.random() * uppercase.length)];
    password += lowercase[Math.floor(Math.random() * lowercase.length)];
    password += numbers[Math.floor(Math.random() * numbers.length)];
    password += symbols[Math.floor(Math.random() * symbols.length)];
    
    for (let i = 4; i < 16; i++) {
      password += all[Math.floor(Math.random() * all.length)];
    }
    
    return password.split('').sort(() => 0.5 - Math.random()).join('');
  }

  async createUser(email, temporaryPassword, phoneNumber) {
    try {
      const createUserParams = {
        UserPoolId: adminConfig.userPoolId,
        Username: email,
        UserAttributes: [
          {
            Name: 'email',
            Value: email
          },
          {
            Name: 'email_verified',
            Value: 'false'  // User must verify email
          },
          {
            Name: 'phone_number',
            Value: phoneNumber
          },
          {
            Name: 'phone_number_verified',
            Value: 'false'  // User must verify phone
          }
        ],
        TemporaryPassword: temporaryPassword,
        MessageAction: 'SUPPRESS',
        DesiredDeliveryMediums: ['EMAIL']
      };

      const createUserCommand = new AdminCreateUserCommand(createUserParams);
      const createUserResponse = await this.client.send(createUserCommand);
      
      console.log('✅ User created successfully:', createUserResponse.User.Username);
      console.log('   Status:', createUserResponse.User.UserStatus);
      
      const setPasswordParams = {
        UserPoolId: adminConfig.userPoolId,
        Username: email,
        Password: temporaryPassword,
        Permanent: false
      };

      const setPasswordCommand = new AdminSetUserPasswordCommand(setPasswordParams);
      await this.client.send(setPasswordCommand);
      
      console.log('✅ Temporary password set successfully');
      console.log('   Email:', email);
      console.log('   Temporary Password:', temporaryPassword);
      console.log('   Phone Number:', phoneNumber);
      console.log('\n⚠️  Important: User must verify email and phone number');
      console.log('⚠️  User must change password on first login');
      console.log('⚠️  MFA will be enforced after verification and password change');
      
      return createUserResponse.User;
    } catch (error) {
      console.error('❌ Error creating user:', error.message);
      if (error.name === 'UsernameExistsException') {
        console.log('   User with this email already exists');
      }
      throw error;
    }
  }

  async markEmailAsImmutable(email) {
    try {
      const params = {
        UserPoolId: adminConfig.userPoolId,
        Username: email,
        UserAttributes: [
          {
            Name: 'custom:email_immutable',
            Value: 'true'
          }
        ]
      };

      const command = new AdminUpdateUserAttributesCommand(params);
      await this.client.send(command);
      console.log('✅ Email marked as immutable');
    } catch (error) {
      console.log('⚠️  Note: custom:email_immutable attribute may need to be configured in User Pool');
    }
  }
}

async function main() {
  console.log('=================================');
  console.log('Cognito Admin User Registration');
  console.log('=================================\n');

  if (!adminConfig.userPoolId || !adminConfig.credentials.accessKeyId) {
    console.error('❌ Missing required environment variables. Please check .env file');
    process.exit(1);
  }

  try {
    const email = await question('Enter user email: ');
    const phoneNumber = await question('Enter phone number (format: +1234567890): ');
    
    if (!email || !email.includes('@')) {
      throw new Error('Invalid email address');
    }

    if (!phoneNumber || !phoneNumber.startsWith('+')) {
      throw new Error('Phone number must start with + and country code');
    }

    const admin = new AdminUserRegistration();
    const temporaryPassword = admin.generateSecurePassword();
    
    console.log('\n🔄 Creating user...\n');
    const user = await admin.createUser(email, temporaryPassword, phoneNumber);
    
    await admin.markEmailAsImmutable(email);
    
    console.log('\n=================================');
    console.log('User Registration Complete');
    console.log('=================================');
    console.log('\n📋 Next Steps:');
    console.log('1. Share the temporary password securely with the user');
    console.log('2. User must verify email and phone number');
    console.log('3. User must log in and change password');
    console.log('4. User will set up MFA after verification');
    console.log('5. Password will expire after 60 days');
    
  } catch (error) {
    console.error('\n❌ Registration failed:', error.message);
  } finally {
    rl.close();
  }
}

main();