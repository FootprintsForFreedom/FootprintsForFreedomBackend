# Detail a waypoint

Gets a waypoint detail object for the waypoint id or slug.

## Request

    GET /api/v1/waypoints/<waypoint-repository-id>

or

    GET /api/v1/waypoints/find/<waypoint-slug>

### Optional query parameters

- term **preferredLanguage**: The language code of the preferred language in which the waypoint detail should be returned. 

    If the language is available the waypoint will be returned in this language. Otherwise a detail object in the language with the highest priority available will be returned. 

    Default: The language with the highest priority.  

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

If the request is sent with an moderator token, the following additional attribute will be sent in the response: 

```json
"detailStatus": "<detail-status>",
"locationStatus": "<location-status>"
```

## See Also

* ``Language/Request/PreferredLanguage``
* ``Waypoint/Detail/Detail``
* ``Waypoint/Location``
* ``Tag/Detail/List``
