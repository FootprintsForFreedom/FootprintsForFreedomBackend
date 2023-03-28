# List deactivated languages

Lists all deactivated language objects.

## Request

    GET /api/v1/languages/deactivated

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

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
