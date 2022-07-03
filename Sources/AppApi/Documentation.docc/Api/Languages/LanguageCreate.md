# Create a language

Creates a language object from the given input.

## Request

    POST /api/v1/languages/

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **languageCode**: A unique language code identifying the language. Ideally in the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format.
- term **name**: The language's unique name.
- term **isRTL**: A boolean value indicating wether or not the language is right-to-left or not.

The parameters can be either sent as `application/json` or `multipart/form-data`.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<language-id>",
    "languageCode": "<language-code>",
    "name": "<language-name>",
    "isRTL": <is-rtl>
}
```

## See Also

* ``Language/Language/Create``
* ``Language/Language/Detail``
