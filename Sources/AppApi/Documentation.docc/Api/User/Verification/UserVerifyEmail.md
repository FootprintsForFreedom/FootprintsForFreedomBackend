# Verify email

Verifies the email address of an user.

## Request 

    POST /api/v1/user/accounts/<user-id>/verify

### Required query parameters

- term **token**: The verification token for the user email.

> Note: The user gets a verification link with the token embedded after creating an account. To request an additional email verification link see: <doc:UserRequestVerifyEmail>.

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

> Note: If the the `BearerToken` of the user has not been sent with the request certain parameters will not be sent.

## See Also

* ``User/Account/Verification``
* ``User/Account/Create``
* ``User/Account/Detail``
* ``User/Role``
