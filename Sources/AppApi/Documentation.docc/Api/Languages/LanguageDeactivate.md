# Deactivate a language

Deactivates an active language so it is no longer listed.

## Request

    PUT /api/v1/languages/<language-id>/deactivate

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
