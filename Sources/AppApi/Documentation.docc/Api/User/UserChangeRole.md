# Change a user role

Assigns a new role to a user.

## Request

    PUT /api/v1/users/accounts/<user-id>/changeRole

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

> Note: A user cannot change his own role.

### Input parameters

The following parameter has to be sent with the request for it to be successful:

- term **newRole**: The new role for the user. The new role cannot be higher than the role of the user initiating the role change.

The parameter can be either sent as `application/json` or `multipart/form-data`.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<user-id>",
    "name": "<user-name>",
    "school": "<user-school>",
    "verified": <user-verified>,
    "role": "<user-role>"
}
```

## See Also

* ``User/Account/ChangeRole``
* ``User/Account/Detail``
