#  Detail a language

Gets a language detail object for the language code.

## Request

    GET /api/v1/languages/<language-code>

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<language-id>",
    "languageCode": "<language-code>",
    "name": "<language-name>",
    "officialName": "<official-language-name>"
    "isRTL": <is-rtl>
}
```

## See Also

* ``Language/Detail/Detail``
