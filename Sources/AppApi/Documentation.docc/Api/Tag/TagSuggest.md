# Suggest tags

Suggests an unpaged list of tag objects for auto-complete/search-as-you-type functionality. 

## Request

    GET /api/v1/tags/suggest

### Query parameters

- term **text**: The text which should be used as starting point for the suggestion. 

    The suggestion filters only the tag title.
- term **languageCode**: The language code of the language to be suggested for.

## Response

**Content-Type**: `application/json`

```json
[
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
]
```

## See Also

* ``DefaultSearchContext``
* ``Tag/Detail/List``
