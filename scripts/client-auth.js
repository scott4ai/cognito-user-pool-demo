import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';
import { cognitoConfig } from '../config/cognito-config.js';
import readline from 'readline';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const question = (query) => new Promise((resolve) => rl.question(query, resolve));
const hiddenQuestion = (query) => new Promise((resolve) => {
  rl.question(query, (answer) => {
    resolve(answer);
  });
  rl.stdoutMuted = true;
  rl.output.write(query);
});

class CognitoAuthClient {
  constructor() {
    this.userPool = new CognitoUserPool({
      UserPoolId: cognitoConfig.UserPoolId,
      ClientId: cognitoConfig.ClientId
    });
  }

  async authenticateUser(email, password) {
    const authenticationDetails = new AuthenticationDetails({
      Username: email,
      Password: password
    });

    const cognitoUser = new CognitoUser({
      Username: email,
      Pool: this.userPool
    });

    return new Promise((resolve, reject) => {
      cognitoUser.authenticateUser(authenticationDetails, {
        onSuccess: (result) => {
          console.log('\n✅ Authentication successful!');
          console.log('   Access Token:', result.getAccessToken().getJwtToken().substring(0, 50) + '...');
          console.log('   ID Token:', result.getIdToken().getJwtToken().substring(0, 50) + '...');
          console.log('   Token Expiration:', new Date(result.getAccessToken().getExpiration() * 1000));
          resolve(result);
        },
        
        onFailure: (err) => {
          console.error('\n❌ Authentication failed:', err.message);
          reject(err);
        },
        
        newPasswordRequired: async (userAttributes, requiredAttributes) => {
          console.log('\n⚠️  New password required (first login)');
          const newPassword = await question('Enter new password: ');
          
          cognitoUser.completeNewPasswordChallenge(newPassword, userAttributes, {
            onSuccess: (result) => {
              console.log('✅ Password changed successfully');
              resolve(result);
            },
            onFailure: (err) => {
              console.error('❌ Password change failed:', err.message);
              reject(err);
            },
            mfaSetup: (challengeName, challengeParameters) => {
              this.handleMFASetup(cognitoUser, resolve, reject);
            },
            totpRequired: (challengeName, challengeParameters) => {
              this.handleTOTPChallenge(cognitoUser, resolve, reject);
            },
            mfaRequired: (challengeName, challengeParameters) => {
              this.handleMFAChallenge(cognitoUser, challengeName, resolve, reject);
            }
          });
        },
        
        mfaSetup: (challengeName, challengeParameters) => {
          this.handleMFASetup(cognitoUser, resolve, reject);
        },
        
        totpRequired: async (challengeName, challengeParameters) => {
          await this.handleTOTPChallenge(cognitoUser, resolve, reject);
        },
        
        mfaRequired: async (challengeName, challengeParameters) => {
          await this.handleMFAChallenge(cognitoUser, challengeName, resolve, reject);
        },
        
        selectMFAType: (challengeName, challengeParameters) => {
          this.selectMFAType(cognitoUser, challengeParameters, resolve, reject);
        }
      });
    });
  }

  async handleMFASetup(cognitoUser, resolve, reject) {
    console.log('\n📱 MFA Setup Required');
    console.log('Choose MFA method:');
    console.log('1. SMS');
    console.log('2. TOTP (Authenticator App)');
    
    const choice = await question('Enter choice (1 or 2): ');
    
    if (choice === '2') {
      cognitoUser.associateSoftwareToken({
        onSuccess: (result) => {
          console.log('\n✅ TOTP setup complete');
          resolve(result);
        },
        onFailure: (err) => {
          console.error('❌ TOTP setup failed:', err);
          reject(err);
        },
        associateSecretCode: async (secretCode) => {
          console.log('\n📱 TOTP Setup:');
          console.log('1. Install an authenticator app (Google Authenticator, Authy, etc.)');
          console.log('2. Add this secret key:', secretCode);
          console.log('3. Or scan QR code with URL: otpauth://totp/CognitoDemo:' + cognitoUser.getUsername() + '?secret=' + secretCode);
          
          const code = await question('\nEnter code from authenticator app: ');
          
          cognitoUser.verifySoftwareToken(code, 'My TOTP Device', {
            onSuccess: (result) => {
              console.log('✅ TOTP device verified successfully');
              resolve(result);
            },
            onFailure: (err) => {
              console.error('❌ TOTP verification failed:', err);
              reject(err);
            }
          });
        }
      });
    } else {
      cognitoUser.enableMFA({
        onSuccess: (result) => {
          console.log('✅ SMS MFA enabled');
          resolve(result);
        },
        onFailure: (err) => {
          console.error('❌ SMS MFA setup failed:', err);
          reject(err);
        }
      });
    }
  }

  async handleTOTPChallenge(cognitoUser, resolve, reject) {
    const totpCode = await question('\n🔐 Enter TOTP code from authenticator app: ');
    
    cognitoUser.sendMFACode(totpCode, {
      onSuccess: (result) => {
        console.log('✅ TOTP verification successful');
        resolve(result);
      },
      onFailure: (err) => {
        console.error('❌ TOTP verification failed:', err);
        reject(err);
      }
    }, 'SOFTWARE_TOKEN_MFA');
  }

  async handleMFAChallenge(cognitoUser, challengeName, resolve, reject) {
    const mfaCode = await question('\n🔐 Enter MFA code: ');
    
    cognitoUser.sendMFACode(mfaCode, {
      onSuccess: (result) => {
        console.log('✅ MFA verification successful');
        resolve(result);
      },
      onFailure: (err) => {
        console.error('❌ MFA verification failed:', err);
        reject(err);
      }
    }, challengeName);
  }

  async selectMFAType(cognitoUser, challengeParameters, resolve, reject) {
    console.log('\n📱 Select MFA Type:');
    const mfaOptions = challengeParameters.MFAS_CAN_CHOOSE;
    mfaOptions.forEach((option, index) => {
      console.log(`${index + 1}. ${option}`);
    });
    
    const choice = await question('Enter choice: ');
    const selectedMfa = mfaOptions[parseInt(choice) - 1];
    
    cognitoUser.sendMFASelectionAnswer(selectedMfa, {
      onSuccess: (result) => {
        resolve(result);
      },
      onFailure: (err) => {
        reject(err);
      },
      totpRequired: async (challengeName, challengeParameters) => {
        await this.handleTOTPChallenge(cognitoUser, resolve, reject);
      },
      mfaRequired: async (challengeName, challengeParameters) => {
        await this.handleMFAChallenge(cognitoUser, challengeName, resolve, reject);
      }
    });
  }

  async signOut(email) {
    const cognitoUser = new CognitoUser({
      Username: email,
      Pool: this.userPool
    });
    
    cognitoUser.signOut();
    console.log('✅ User signed out successfully');
  }

  async refreshSession(email) {
    const cognitoUser = new CognitoUser({
      Username: email,
      Pool: this.userPool
    });

    return new Promise((resolve, reject) => {
      cognitoUser.getSession((err, session) => {
        if (err) {
          console.error('❌ Session refresh failed:', err);
          reject(err);
          return;
        }
        
        if (session.isValid()) {
          console.log('✅ Session is valid');
          console.log('   Access Token:', session.getAccessToken().getJwtToken().substring(0, 50) + '...');
          resolve(session);
        } else {
          console.log('⚠️  Session expired');
          reject(new Error('Session expired'));
        }
      });
    });
  }
}

async function main() {
  console.log('===================================');
  console.log('Cognito Client Authentication Demo');
  console.log('===================================\n');

  if (!cognitoConfig.UserPoolId || !cognitoConfig.ClientId) {
    console.error('❌ Missing required environment variables. Please check .env file');
    process.exit(1);
  }

  const authClient = new CognitoAuthClient();
  
  try {
    console.log('Select action:');
    console.log('1. Sign In');
    console.log('2. Refresh Session');
    console.log('3. Sign Out');
    
    const action = await question('\nEnter choice (1-3): ');
    
    switch (action) {
      case '1':
        const email = await question('Enter email: ');
        const password = await question('Enter password: ');
        
        console.log('\n🔄 Authenticating...');
        await authClient.authenticateUser(email, password);
        
        console.log('\n✅ Authentication workflow complete!');
        console.log('   User is now logged in with valid tokens');
        console.log('   Tokens can be used for API calls');
        break;
        
      case '2':
        const refreshEmail = await question('Enter email: ');
        console.log('\n🔄 Refreshing session...');
        await authClient.refreshSession(refreshEmail);
        break;
        
      case '3':
        const signOutEmail = await question('Enter email: ');
        await authClient.signOut(signOutEmail);
        break;
        
      default:
        console.log('Invalid choice');
    }
    
  } catch (error) {
    console.error('\n❌ Operation failed:', error.message);
  } finally {
    rl.close();
  }
}

main();