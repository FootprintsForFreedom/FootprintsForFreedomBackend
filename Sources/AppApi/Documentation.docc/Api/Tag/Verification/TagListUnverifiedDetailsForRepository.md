# List unverified details for a tag repository

Lists all unverified detail models for the specified tag repository.

## Request

    GET /api/v1/tags/<tag-repository-id>/unverified

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
            "detailId": "<tag-detail-1-id>",
            "title": "<tag-detail-1-title>",
            "slug": "<tag-detail-1-slug>",
            "keywords": [
                "<keyword-1>",
                ...
            ],
            "languageCode": "<tag-detail-1-language-code>"
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
* ``Tag/Repository/ListUnverified``
* ``Page``
* ``PageMetadata``
