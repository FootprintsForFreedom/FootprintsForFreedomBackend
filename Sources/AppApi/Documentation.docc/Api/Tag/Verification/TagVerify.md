# Verify a tag 

Verifies a specified tag detail object so it is visible to everyone.

## Request

    POST /api/v1/tags/<tag-repository-id>/verify/<tag-detail-id>

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<id>",
    "detailId": "<detail-id>",
    "languageCode": "<language-code>",
    "availableLanguageCodes": ["<language-code>", ...],
    "title": "<title>",
    "slug": "<slug>",
    "keywords": [
        "<keyword-1>",
        ...
    ],
}
```

## See Also

* ``Tag/Detail/Detail``
