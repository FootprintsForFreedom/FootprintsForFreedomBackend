# Request email verification

Requests a verification token for the user's email address.

## Request

    POST /api/v1/users/accounts/<user-id>/requestVerification

This endpoint is only available to the user himself and the email cannot yet be verified.

The own user token has to be sent as a `BearerToken` with the request.

## Response

If the request email verification was successful a HTTP Status code `200 - OK` will be returned.

The user will also receive an email containing a link with a token to verify his email address. The token embedded in the link will only be valid for 24 hours.
