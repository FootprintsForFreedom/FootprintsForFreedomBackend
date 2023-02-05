#  List unused languages

Lists all languages not yet created. 

## Request

    Get /api/v1/languages/unused

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

## Response

**Content-Type**: `application/json`

```json
[
    {
        "name": "<language-1-name>",
        "languageCode": "<language-1-code>",
        "officialName": "<official-language-1-name>"
    },
    {
        "name": "<language-2-name>",
        "languageCode": "<language-2-code>",
        "officialName": "<official-language-2-name>"
    }
]
```

## See Also

* ``Language/Detail/ListUnused``
