# Search media

Searches all media objects and returns the result in pages.

## Request

    GET /api/v1/media/search

### Query parameters

- term **text**: The text which should be searched for. The search filters the media title, detail text and all titles of connected tags as well as the keywords of the tags.
- term **languageCode**: The language code of the language to be searched.
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
* ``Media/Detail/List``
