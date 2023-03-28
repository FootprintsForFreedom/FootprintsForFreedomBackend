# Detail a user

Gets a user detail object for the user id.

## Request

    GET /api/v1/users/accounts/<user-id>

## Response

**Content-Type**: `application/json`

The exact detail object varies on the role of the requesting user. Without any authentication the following detail object is returned:

```json
{
    "id": "<user-id>",
    "name": "<user-name>",
    "school": "<user-school>"
}
```

If the request is performed with an admin token, the following parameters will be returned additionally:

```json
"verified": <user-verified>,
"role": "<user-role>"
```

If the request is performed by the user himself, his email address will also be returned:

```json
"email": "<user-email>"
```

## See Also

* ``User/Account/Detail``
* ``User/Role``
