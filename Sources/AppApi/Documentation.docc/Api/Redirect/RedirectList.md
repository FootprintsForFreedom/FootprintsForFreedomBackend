# List redirects

Lists all redirects in pages.

## Request

    GET /api/v1/redirect

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

### Optional query parameters

- term **per**: The amount of items which should be sent per page. Default: 10
- term **page**: The number of the page which should be returned. Default: 1

## Response

**Content-Type**: `application/json`

```json
{
    "items": [
        {
            "id": "<redirect-1-id>",
            "source": "<redirect-1-source>"
            "destination": "<redirect-1-destination>",
        },
        {
            "id": "<redirect-2-id>",
            "source": "<redirect-2-source>"
            "destination": "<redirect-2-destination>",
        },
        ...
    ],
    "metadata": {
        "per": <number-of-items-per-page>,
        "total": <total-number-of-items>,
        "page": <number-of-current-page>
    }
}
```

## See Also

* ``PageRequest``
* ``Redirect/Detail/List``
* ``Page``
* ``PageMetadata``
