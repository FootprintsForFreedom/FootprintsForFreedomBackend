# Verify a waypoint tag

Verifies a waypoint tag so it is visible to everyone.

## Request

    POST /api/v1/waypoints/<waypoint-repository-id>/tags/verify/<tag-repository-id>

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<id>",
    "detailId": "<detail-id>",
    "locationId": "<location-id>",
    "languageCode": "<language-code>",
    "availableLanguageCodes": ["<language-code>", ...],
    "title": "<title>",
    "slug": "<slug>",
    "detailText": "<detail-text>",
    "location": {
        "longitude": <longitude>,
        "latitude": <latitude>
    },
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

* ``Waypoint/Detail/Detail``
* ``Tag/Detail/List``
