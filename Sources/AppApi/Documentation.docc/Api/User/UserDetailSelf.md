# Detail own user

Gets the detail object for the own user.

## Request

    GET /api/v1/users/accounts/me

This endpoint is only available when a `BearerToken` is sent with the request. It will always return the user for this token.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<user-id>",
    "name": "<user-name>",
    "email": "<user-email>",
    "school": "<user-school>",
    "verified": <user-verified>,
    "role": "<user-role>"
}
```

## See Also

* ``User/Account/Detail``
* ``User/Role``

