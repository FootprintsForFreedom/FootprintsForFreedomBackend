# List unverified reports

Lists all unverified reports for a repository.

## Request

    GET /api/v1/tags/<tag-repository-id>/reports/unverified

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

### Optional query parameters

- term **per**: The amount of items which should be sent per page. Default: 10
- term **page**: The number of the page which should be returned. Default: 1

## Response

**Content-Type**: `application/json`

```json
{
    "items": [
        {
            "id": "<report-id>",
            "title": "<report-title>",
            "slug": "<report-slug>"
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
* ``Report/List``
* ``Page``
* ``PageMetadata``
