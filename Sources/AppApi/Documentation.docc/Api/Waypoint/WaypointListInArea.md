# List in area

Lists all waypoints in the specified area in pages.

## Request

    GET /api/v1/waypoints/in

### Query parameters

- term **topLeftLatitude**: The top left latitude of the relevant area.
- term **topLeftLongitude**: The top left longitude of the relevant area.
- term **bottomRightLatitude**: The bottom right latitude of the relevant area.
- term **bottomRightLongitude**: The bottom right longitude of the relevant area.
- term **preferredLanguage**: The language code of the preferred language in which each waypoint object should be returned.
- term **per**: The amount of items which should be sent per page. Default: 10
- term **page**: The number of the page which should be returned. Default: 1

## Response

**Content-Type**: `application/json`

```json
{
    "items": [
        {
            "id": "<waypoint-1-id>",
            "title": "<waypoint-1-title>",
            "slug": "<waypoint-1-slug>",
            "location": {
                "longitude": <waypoint-1-longitude>,
                "latitude": <waypoint-1-latitude>
            },
        },
        {
            "id": "<waypoint-2-id>",
            "title": "<waypoint-2-title>",
            "slug": "<waypoint-2-slug>",
            "location": {
                "longitude": <waypoint-2-longitude>,
                "latitude": <waypoint-2-latitude>
            },
        }
    ],
    "metadata": {
        "per": <number-of-items-per-page>,
        "total": <total-number-of-items>,
        "page": <number-of-current-page>
    }
}
```

## See Also

* ``Waypoint/Request/ListInArea``
* ``Language/Request/PreferredLanguage``
* ``PageRequest``
* ``Waypoint/Detail/List``
* ``Waypoint/Location``
* ``Page``
* ``PageMetadata``
