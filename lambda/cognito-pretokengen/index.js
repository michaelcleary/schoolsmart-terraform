'use strict';

/**
 * Cognito Pre-Token Generation V2 trigger.
 *
 * Adds `role` and `contactId` as custom claims to the Cognito access token so
 * the API server can authorise requests without a DynamoDB lookup per request.
 *
 * Role resolution order:
 *   1. cognito:groups (set for admin-created users via AdminAddUserToGroup)
 *   2. custom:role attribute (set for users migrated from legacy DynamoDB)
 */
exports.handler = async (event) => {
  const attrs = event.request.userAttributes ?? {};
  const groups = event.request.groupConfiguration?.groupsToOverride ?? [];

  const role = groups[0] ?? attrs['custom:role'] ?? '';
  const contactId = attrs['custom:contactId'] ?? '';

  event.response = {
    claimsAndScopeOverrideDetails: {
      accessTokenGeneration: {
        claimsToAddOrOverride: {
          role: role,
          contactId: contactId,
        },
        claimsToSuppress: [],
        scopesToAdd: [],
        scopesToSuppress: [],
      },
    },
  };

  return event;
};
