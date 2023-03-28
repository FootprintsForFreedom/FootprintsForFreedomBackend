# Request to delete a media tag

Requests a media tag to be deleted.

## Request

    DELETE /api/v1/media/<media-repository-id>/tags/<tag-repository-id>

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

## See Also

* ``Media/Detail/Detail``
* ``Tag/Detail/List``
