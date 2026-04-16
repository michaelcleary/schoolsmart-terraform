'use strict';

/**
 * Cognito User Migration trigger.
 *
 * Fires when a user attempts to sign in and is not found in the Cognito User
 * Pool.  Validates the credentials against the legacy DynamoDB users table and,
 * if valid, returns the attributes Cognito needs to create the user.
 *
 * NOTE: AdminAddUserToGroup cannot be called here because the Cognito user does
 * not yet exist at the time this trigger fires.  Instead, role is stored as the
 * `custom:role` attribute and the Pre-Token Generation Lambda synthesises the
 * `role` claim for the access token.
 */

const { DynamoDBClient, GetItemCommand } = require('@aws-sdk/client-dynamodb');
const bcrypt = require('bcryptjs');

const dynamo = new DynamoDBClient({ region: process.env.AWS_REGION });

exports.handler = async (event) => {
  // Only handle password-based authentication migration
  if (event.triggerSource !== 'UserMigration_Authentication') {
    return event;
  }

  const { userName } = event;
  const password = event.request?.password;
  const tableName = process.env.USERS_TABLE;

  try {
    const result = await dynamo.send(new GetItemCommand({
      TableName: tableName,
      Key: { username: { S: userName } },
    }));

    if (!result.Item) {
      throw new Error('User not found');
    }

    const user = {
      password:  result.Item.password?.S,
      status:    result.Item.status?.S,
      role:      result.Item.role?.S ?? '',
      contactId: result.Item.contactId?.S ?? '',
      email:     result.Item.email?.S ?? '',
    };

    if (user.status !== 'active') {
      throw new Error('Account inactive');
    }

    if (!user.password || !bcrypt.compareSync(password, user.password)) {
      throw new Error('Invalid credentials');
    }

    event.response.userAttributes = {
      email:               user.email,
      email_verified:      'true',
      'custom:contactId':  user.contactId,
      'custom:role':       user.role,
    };
    event.response.finalUserStatus = 'CONFIRMED';
    event.response.messageAction   = 'SUPPRESS';

    console.log(`Migrated user: ${userName}, role: ${user.role}`);
    return event;

  } catch (err) {
    // Always surface as Bad credentials to prevent user enumeration
    console.error(`Migration failed for ${userName}: ${err.message}`);
    throw new Error('Bad credentials');
  }
};
