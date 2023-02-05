# Patch a user

Patches an existing user from the given input.

## Request

    PATCH /api/v1/users/accounts/<user-id>

This endpoint is only available to the user himself and admins.

The own or admin user token has to be sent as a `BearerToken` with the request.

### Input parameters

At least one of the other following parameters has to be sent with the request for it to be successful:  

- term **name**: The user name. 
- term **email**: The user's email address.
- term **setSchool**: Wether or not to set the school. 
    
    A `school` value will only be considered if `setSchool` is set to true. If `setSchool` is true but no school value is set, the user's school will also be set to no value. 
- term **school**: The school of the user.

The parameters can be either sent as `application/json` or `multipart/form-data`.

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

If the request is performed by the user himself, his email address will also be returned:

```json
"email": "<user-email>"
```

## See Also

* ``User/Account/Patch``
* ``User/Account/Detail``
