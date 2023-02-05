#  List languages

Lists all language objects sorted by their priority.

## Request

    GET /api/v1/languages

## Response

**Content-Type**: `application/json`

```json
[
    {
        "id": "<language-1-id>",
        "languageCode": "<language-1-code>",
        "name": "<language-1-name>",
        "officialName": "<official-language-1-name>"
        "isRTL": <is-rtl>
    },
    {
        "id": "<language-2-id>",
        "languageCode": "<language-2-code>",
        "name": "<language-2-name>",
        "officialName": "<official-language-2-name>"
        "isRTL": <is-rtl>
    },
    ...
]
```

## See Also

* ``Language/Detail/List``
