# Set language priorities

Orders the languages according to their priorities.

## Request

    PUT /api/v1/languages/priorities

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

### Input parameters

The following parameter has to be sent with the request for it to be successful:

- term **newLanguagesOrder**: An array containing all active language ids in the new order they should be arranged. The first item will have the highest priority.

## Response

The response contains all active languages in their new order.

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

* ``Language/Detail/UpdatePriorities``
* ``Language/Detail/List``
