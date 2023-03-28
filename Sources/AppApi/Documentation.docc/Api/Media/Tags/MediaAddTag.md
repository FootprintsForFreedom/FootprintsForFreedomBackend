# Add tag to media

Adds a tag to a media object.

## Request

    POST /api/v1/media/<media-repository-id>/tags/<tag-repository-id>

This endpoint is only available to verified users.

The user token has to be sent as a `BearerToken` with the request.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<id>",
    "languageCode": "<language-code>",
    "availableLanguageCodes": ["<language-code>", ...],
    "title": "<title>",
    "slug": "<slug>",
    "detailText": "<detail-text>",
    "source": "<source>",
    "group": "<file-group>",
    "filePath": "<file-path>",
    "detailId": "<detail-id>",
    "tags": [
        {
            "id": "<tag-id>",
            "title": "<tag-title>",
            "slug": "<tag-slug>"
        },
        ...
    ]
}
```

> Note: The tag objects are the same as those returned when listing tags: <doc:TagList>.

The added tag will not be visible in the retuned detail and other details of the media object until it was verified by a moderator. 

## See Also

* ``Media/Detail/Detail``
* ``Tag/Detail/List``
