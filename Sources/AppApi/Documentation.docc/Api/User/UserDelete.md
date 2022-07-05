# Delete a user

Deletes a user.

## Request

    DELETE /api/v1/users/accounts/<user-id>

This endpoint is only available to the user himself and admins.

The own or admin user token has to be sent as a `BearerToken` with the request.

## Response

If the deletion was successful a HTTP Status code `204 - no Content` will be returned.
