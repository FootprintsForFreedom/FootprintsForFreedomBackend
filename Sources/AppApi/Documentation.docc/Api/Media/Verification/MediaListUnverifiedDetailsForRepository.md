# List unverified details for a media repository

Lists all unverified detail models for the specified media repository.

## Request

    GET /api/v1/media/<media-repository-id>/unverified

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
            "detailId": "<media-detail-1-id>",
            "title": "<media-detail-1-title>",
            "slug": "<media-detail-1-slug>",
            "detailText": "<media-detail-1-detail-text>",
            "languageCode": "<media-detail-1-language-code>"
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
* ``Media/Repository/ListUnverified``
* ``Page``
* ``PageMetadata``
