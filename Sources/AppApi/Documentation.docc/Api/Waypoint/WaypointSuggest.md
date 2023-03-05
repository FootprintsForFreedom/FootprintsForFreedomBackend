# Suggest waypoints

Suggests an unpaged list of waypoint objects for auto-complete/search-as-you-type functionality. 

## Request

    GET /api/v1/waypoints/suggest

### Query parameters

- term **text**: The text which should be used as starting point for the suggestion. 

    The suggestion filters only the waypoint title.
- term **languageCode**: The language code of the language to be suggested for.

## Response

**Content-Type**: `application/json`

```json
[
    {
        "id": "<waypoint-1-id>",
        "title": "<waypoint-1-title>",
        "slug": "<waypoint-1-slug>",
        "detailText": "<waypoint-1-detail-text>"
        "location": {
            "longitude": <waypoint-1-longitude>,
            "latitude": <waypoint-1-latitude>
        },
        "languageCode": "waypoint-1-language-code>"
    },
    {
        "id": "<waypoint-2-id>",
        "title": "<waypoint-2-title>",
        "slug": "<waypoint-2-slug>",
        "detailText": "<waypoint-2-detail-text>"
        "location": {
            "longitude": <waypoint-2-longitude>,
            "latitude": <waypoint-2-latitude>
        },
        "languageCode": "waypoint-2-language-code>"
    }
]
```

## See Also

* ``DefaultSearchContext``
* ``Waypoint/Detail/List``
* ``Waypoint/Location``
