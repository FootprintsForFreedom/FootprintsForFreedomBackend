# List users

Lists all users in pages.

## Request 

    GET /api/v1/users/accounts

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

## Response

**Content-Type**: `application/json`

```json
{
    "items": [
        {
            "id": "<user-1-id>",
            "name": "<user-1-name>",
            "school": "<user-1-school>",
            "verified": <user-1-verified>,
            "role": "<user-1-role>"
        },
        {
            "id": "<user-2-id>",
            "name": "<user-2-name>",
            "school": "<user-2-school>",
            "verified": <user-2-verified>,
            "role": "<user-2-role>"
        },
        ...
    ],
    "metadata": {
        "per": <number-of-items-per-page>,
        "total": <total-number-of-items>,
        "page": <number-of-current-page>
    }
}
```

## See Also

* ``User/Account/List``
* ``User/Role``