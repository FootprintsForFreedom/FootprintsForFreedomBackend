# List waypoints

Lists all waypoint objects in pages.

## Request

    GET /api/v1/waypoints

### Optional query parameters

- term **latitude**: The user's location latitude near which results should be returned.
- term **longitude**: The user's location longitude near which results should be returned.
- term **preferredLanguage**: The language code of the preferred language in which each waypoint object should be returned.

    If the language is available the waypoint will be returned in this language otherwise detail object in the language with the highest priority that is available will be returned.
    
    Default: The language with the highest priority.
- term **per**: The amount of items which should be sent per page. Default: 10
- term **page**: The number of the page which should be returned. Default: 1

> Important: Results are sorted to be as close as possible to the user's location. 
>
> If no location is sent with the request the IP-Address used to send the request will be used to determine the user's approximate location.

## Response

**Content-Type**: `application/json`

```json
{
    "items": {
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
    },
    "userLocation": {
        "longitude": <user-location-longitude>,
        "latitude": <user-location-latitude>
    }
}
```

> Note: The `userLocation` contains either the location sent with the request or the location derived from the IP-Address used to send the respective request. 

## See Also

* ``Waypoint/Request/GetList``
* ``Language/Request/PreferredLanguage``
* ``PageRequest``
* ``Waypoint/Detail/ListWrapper``
* ``Waypoint/Detail/List``
* ``Waypoint/Location``
* ``Page``
* ``PageMetadata``
