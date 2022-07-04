# Verify a waypoint 

Verifies a specified waypoint detail object so it is visible to everyone.

## Request

    POST /api/v1/waypoints/<waypoint-repository-id>/waypoints/verify/<waypoint-detail-id>

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

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
    "status": "<detail-status>"
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

The tag objects are the same as those returned when listing tags: <doc:TagList>.

## See Also

* ``Waypoint/Detail/Detail``
