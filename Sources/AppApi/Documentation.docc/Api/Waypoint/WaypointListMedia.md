# List media for waypoint

Lists all media objects for a waypoint repository in pages.

## Request

    GET /api/v1/waypoints/<waypoint-repository-id>/media

### Optional query parameters

- term **preferredLanguage**: The language code of the preferred language in which each media object should be returned. 

    If the language is available the media will be returned in this language. Otherwise a detail object in the language with the highest priority available will be returned. 
    
    Default: The language with the highest priority.
- term **per**: The amount of items which should be sent per page. Default: 10
- term **page**: The number of the page which should be returned. Default: 1

## Response

**Content-Type**: `application/json`

```json
{
    "items": [
        {
            "id": "<media-1-id>",
            "title": "<media-1-title>",
            "slug": "<media-1-slug>",
            "group": "<media-file-1-group>"
        },
        {
            "id": "<media-2-id>",
            "title": "<media-2-title>",
            "slug": "<media-2-slug>",
            "group": "<media-file-2-group>"
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
* ``Media/Detail/List``
* ``Page``
* ``PageMetadata``
