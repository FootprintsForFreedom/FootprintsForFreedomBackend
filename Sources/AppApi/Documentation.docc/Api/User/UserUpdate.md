# Update a user

Updates an existing user from the given input.

## Request 

    PUT /api/v1/users/accounts/<user-id>

This endpoint is only available to the user himself and admins.

The own or admin user token has to be sent as a `BearerToken` with the request.

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **name**: The user name. 
- term **email**: The user's email address.
- term **school**: The school of the user. *Optional*. If no value is set the user's school will be set to no value.

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

* ``User/Account/Update``
* ``User/Account/Detail``
