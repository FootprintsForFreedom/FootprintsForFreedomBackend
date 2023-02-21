# List repositories with unverified models

Lists all repositories having at least one unverified waypoint.

## Request

    GET /api/v1/waypoints/unverified

> Note: This api endpoint also lists all waypoint repositories with unverified tags.

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

### Optional query parameters

- term **preferredLanguage**: The language code of the preferred language in which each waypoint object should be returned. 

    If the language is available the waypoint will be returned in this language. Otherwise a detail object in the language with the highest priority available will be returned. 
    
    Default: The language with the highest priority.
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

* ``Language/Request/PreferredLanguage``
* ``PageRequest``
* ``Waypoint/Detail/List``
* ``Waypoint/Location``
* ``Page``
* ``PageMetadata``
