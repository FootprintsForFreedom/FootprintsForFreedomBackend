#  Patch a language

Patches an existing language object from the given input.

## Request

    PATCH /api/v1/languages/<language-id>

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

### Input parameters

At least one of the following parameters has to be sent with the request for it to be successful:

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

* ``Language/Detail/Patch``
* ``Language/Detail/Detail``
