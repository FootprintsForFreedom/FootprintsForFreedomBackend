# Search waypoints

Searches all waypoint objects and returns the result in pages.

## Request

    GET /api/v1/waypoints/search

### Query parameters

- term **text**: The text which should be searched for. 

    The search filters the waypoint title, detail text and all titles of connected tags as well as the keywords of the tags.
- term **languageCode**: The language code of the language to be searched.
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
    ],
    "metadata": {
        "per": <number-of-items-per-page>,
        "total": <total-number-of-items>,
        "page": <number-of-current-page>
    }
}
```

## See Also

* ``DefaultSearchContext``
* ``PageRequest``
* ``Waypoint/Detail/List``
* ``Waypoint/Location``
* ``Page``
* ``PageMetadata``
