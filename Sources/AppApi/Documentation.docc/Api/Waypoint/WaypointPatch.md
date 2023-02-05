# Patch a waypoint

Patches an existing waypoint object from the given input.

## Request

    PATCH /api/v1/waypoints/<waypoint-repository-id>

This endpoint is only available to verified users.

The user token has to be sent as a `BearerToken` with the request.

### Input parameters

The parameter `idForWaypointDetailToPatch` and at least one of the other following parameters has to be sent with the request for it to be successful:  

- term **title**: The waypoint title.
- term **detailText**: The detail text describing the waypoint.
- term **location**: The location of the waypoint.
- term **idForWaypointDetailToPatch**: The id of an existing waypoint. All parameters not set in this request will be taken from this waypoint.

The parameters can be either sent as `application/json` or `multipart/form-data`.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<waypoint-repository-id>",
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

The patched and returned waypoint will not be visible until it has been verified by a moderator.

## See Also

* ``Waypoint/Detail/Patch``
* ``Waypoint/Detail/Detail``
* ``Tag/Detail/List``
