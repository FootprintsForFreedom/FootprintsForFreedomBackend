# Change password

Updates the password for a user.

## Request

    PUT /api/v1/users/accounts/<user-id>/updatePassword

This endpoint is only available to the user himself.

The own user token has to be sent as a `BearerToken` with the request.

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **currentPassword**: The current password set by the user for his account. 
- term **newPassword**: The new password set by the user for his account.

The parameters can be either sent as `application/json` or `multipart/form-data`.

> Important: The new password needs to contain at least
>
> * one uppercase letter
> * one lowercase letter
> * one digit
> * six characters in total

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

* ``User/Account/ChangePassword``
* ``User/Account/Detail``
