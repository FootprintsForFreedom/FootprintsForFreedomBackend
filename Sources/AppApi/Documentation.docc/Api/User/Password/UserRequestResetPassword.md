# Request password reset

Requests a link with which to reset the user password when it was forgotten.

## Request

    POST /api/v1/users/accounts/resetPassword

### Input parameters

The following parameter has to be sent with the request for it to be successful:

- term **email**: The email address for the user who forgot his password. 

The parameters can be either sent as `application/json` or `multipart/form-data`.

## Response

If the request reset password was successful a HTTP Status code `200 - OK` will be returned.

The user will also receive an email containing a link with a token to reset his password. The token embedded in the link will only be valid for 24 hours.

## See Also

- ``User/Account/ResetPasswordRequest``
