# Reset password

Resets the user password when it has been forgotten.

## Request

    POST /api/v1/users/accounts/<user-id>/resetPassword

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **token**: The token for the user to reset his password. 
- term **newPassword**: The new password set by the user for his account.

The parameters can be either sent as `application/json` or `multipart/form-data`.

> Note: The new password needs to contain at least
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

If the request is performed by the user himself, his email address will also be returned:

```json
"email": "<user-email>"
```

## See Also

* ``User/Account/ResetPassword``
* ``User/Account/Detail``
