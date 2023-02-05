# List unverified locations for a waypoint repository

Lists all unverified location models for the specified waypoint repository.

## Request

    GET /api/v1/waypoints/<waypoint-repository-id>/locations/unverified

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
            "locationId": "<waypoint-location-1-id>",
            "location": {
                "longitude": <waypoint-1-longitude>,
                "latitude": <waypoint-1-latitude>
            },
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
* ``Waypoint/Repository/ListUnverifiedLocations``
* ``Page``
* ``PageMetadata``
