# Update a waypoint

Updates an existing waypoint object from the given input.

## Request

PUT /api/v1/waypoints/<waypoint-repository-id>

This endpoint is only available to verified users.

The user token has to be sent as a `BearerToken` with the request.

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **title**: The waypoint title.
- term **detailText**: The detail text describing the waypoint.
- term **languageCode**: The language code for the waypoint title and description.

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

The updated and returned waypoint will not be visible until it has been verified by a moderator.

## See Also

* ``Waypoint/Detail/Update``
* ``Waypoint/Detail/Detail``
* ``Tag/Detail/List``
