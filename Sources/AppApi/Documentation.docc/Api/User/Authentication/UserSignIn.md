# Sign in

Signs a user in and returns a token.

## Request

    POST /api/v1/sign-in

### Input parameters

The following parameters have to be sent with the request for it to be successful:
 
- term **email**: The user's email address.
- term **password**: The password set by the user for his account. 

The parameters can be either sent as `application/json`, `multipart/form-data` or using the HTTP Basic Auth header.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<token-id>",
    "access_token": "<access-token>",
    "user": {
        "id": "<user-id>",
        "name": "<user-name>",
        "email": "<user-email>",
        "school": "<user-school>",
        "verified": <user-verified>,
        "role": "<user-role>"
    }
}
```

> Note: The user object is the same as the one returned when getting the own user: <doc:UserDetailSelf>.

## See Also

* ``User/Account/Login``
* ``User/Token/Detail``
* ``User/Account/Detail``
* ``User/Role``
