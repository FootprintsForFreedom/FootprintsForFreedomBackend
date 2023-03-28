# Create a user

Creates a new user.

## Request

    POST /api/v1/users/accounts

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **name**: The user name. 
- term **email**: The user's email address.
- term **password**: The password set by the user for his account. 
- term **school**: The school of the user. *Optional*.

The parameters can be either sent as `application/json` or `multipart/form-data`.

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

* ``User/Account/Create``
* ``User/Account/Detail``
* ``User/Role``
