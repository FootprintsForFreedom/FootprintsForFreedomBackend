# Search tags

Searches all tag objects and returns the result in pages.

## Request

    GET /api/v1/tags/search

### Query parameters

- term **text**: The text which should be searched for. 

    The search filters the tag title, as well as the keywords of the tags.
- term **languageCode**: The language code of the language to be searched.
- term **per**: The amount of items which should be sent per page. Default: 10
- term **page**: The number of the page which should be returned. Default: 1

## Response

**Content-Type**: `application/json`

```json
{
    "items": [
        {
            "id": "<tag-1-id>",
            "title": "<tag-1-title>",
            "slug": "<tag-1-slug>",
        },
        {
            "id": "<tag-2-id>",
            "title": "<tag-2-title>",
            "slug": "<tag-2-slug>",
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
* ``Tag/Detail/List``
* ``Page``
* ``PageMetadata``
