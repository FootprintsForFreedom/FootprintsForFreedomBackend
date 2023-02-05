# Detail a redirect

Gets a redirect for redirect id.

## Request

    GET /api/v1/redirect/<redirect-id>

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<redirect-id>",
    "source": "<redirect-source>"
    "destination": "<redirect-destination>",
}
```
## See Also

* ``Redirect/Detail/Detail``
