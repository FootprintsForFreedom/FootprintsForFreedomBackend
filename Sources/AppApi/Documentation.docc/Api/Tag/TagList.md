# List tags

Lists all tag objects in pages.

## Request

    GET /api/v1/tags

### Optional query parameters

- term **preferredLanguage**: The language code of the preferred language in which each tag object should be returned.

    If the language is available the tag will be returned in this language otherwise detail object in the language with the highest priority that is available will be returned. 
    
    Default: The language with the highest priority.
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

* ``Language/Request/PreferredLanguage``
* ``PageRequest``
* ``Tag/Detail/List``
* ``Page``
* ``PageMetadata``
