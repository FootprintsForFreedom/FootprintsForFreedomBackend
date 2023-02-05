# List repositories with unverified models

Lists all repositories having at least one unverified model.

## Request

    GET /api/v1/media/unverified

> Note: This api endpoint also lists all media repositories with unverified tags.

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

### Optional query parameters

- term **preferredLanguage**: The language code of the preferred language in which each media object should be returned.

    If the language is available the media will be returned in this language otherwise detail object in the language with the highest priority that is available will be returned. 

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
