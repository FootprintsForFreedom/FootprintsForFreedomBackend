# Sign out

Signs a user out and deletes all tokens for this user.

## Request

    POST /api/v1/sign-out

> Warning: This endpoint will delete all tokens for this user. This means that all sessions for this user will be signed-out.

This endpoint is only available to users.

The user token has to be sent as a `BearerToken` with the request.

## Response

If the sign out was successful a HTTP Status code `200 - OK` will be returned.

