import dotenv from 'dotenv';
dotenv.config();

export const cognitoConfig = {
  UserPoolId: process.env.COGNITO_USER_POOL_ID,
  ClientId: process.env.COGNITO_CLIENT_ID,
  Region: process.env.AWS_REGION || 'us-east-1'
};

export const adminConfig = {
  region: process.env.AWS_REGION || 'us-east-1',
  userPoolId: process.env.COGNITO_USER_POOL_ID,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  }
};

export const passwordPolicy = {
  minimumLength: 12,
  requireUppercase: true,
  requireLowercase: true,
  requireNumbers: true,
  requireSymbols: true,
  temporaryPasswordValidityDays: 7
};

export const mfaConfig = {
  mfaConfiguration: 'ON',
  mfaMethods: ['SMS', 'TOTP']
};