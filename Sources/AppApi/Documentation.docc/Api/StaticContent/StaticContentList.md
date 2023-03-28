# List static content

Lists all static content objects in pages.

## Request

    GET /api/v1/staticContent

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

### Optional query parameters

- term **preferredLanguage**: The language code of the preferred language in which each static content object should be returned.

    If the language is available the static content will be returned in this language. Otherwise a detail object in the language with the highest priority available will be returned. 

    Default: The language with the highest priority.
- term **per**: The amount of items which should be sent per page. Default: 10
- term **page**: The number of the page which should be returned. Default: 1

## Response

**Content-Type**: `application/json`

```json
{
    "items": [
        {
            "id": "<static-content-1-id>",
            "slug": "<static-content-1-slug>"
        },
        {
            "id": "<static-content-2-id>",
            "slug": "<static-content-2-slug>"
        },
        ...
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
* ``StaticContent/Detail/List``
* ``Page``
* ``PageMetadata``
