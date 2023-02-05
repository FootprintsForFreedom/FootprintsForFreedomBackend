# List media

Lists all media objects in pages.

## Request

    GET /api/v1/media

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
            "group": "<media-file-1-group>",
            "thumbnailFilePath": "<media-file-1-thumbnail-path>"
        },
        {
            "id": "<media-2-id>",
            "title": "<media-2-title>",
            "slug": "<media-2-slug>",
            "group": "<media-file-2-group>",
            "thumbnailFilePath": "<media-file-2-thumbnail-path>"
        }
    ],
    "metadata": {
        "per": <number-of-items-per-page>,
        "total": <total-number-of-items>,
        "page": <number-of-current-page>
    }
}
```

> Note: All media objects with an image, video or document file also have a thumbnail. For more details see: <doc:MediaThumbnail>

## See Also

* <doc:MediaThumbnail>
* ``Language/Request/PreferredLanguage``
* ``PageRequest``
* ``Media/Detail/List``
* ``Page``
* ``PageMetadata``
