# Suggest media

Suggests an unpaged list of media objects for auto-complete/search-as-you-type functionality. 

## Request

    GET /api/v1/media/suggest

### Query parameters

- term **text**: The text which should be used as starting point for the suggestion.

    The suggestion filters only the media title.
- term **languageCode**: The language code of the language to be suggested for.

## Response

**Content-Type**: `application/json`

```json
[
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
]
```

## See Also

* ``DefaultSearchContext``
* ``Media/Detail/List``
