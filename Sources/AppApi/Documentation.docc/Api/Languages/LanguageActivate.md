# Activate a language

Activates a previously deactivated language so it is listed again.

## Request

    PUT /api/v1/languages/<language-id>/activate

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

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
