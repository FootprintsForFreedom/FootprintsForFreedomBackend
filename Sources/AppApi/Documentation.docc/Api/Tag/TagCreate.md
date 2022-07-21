# Create a tag

Creates a tag object from the given input for the specified waypoint.

## Request

    POST /api/v1/tags

This endpoint is only available to verified users.

The user token has to be sent as a `BearerToken` with the request.

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **title**: The tag title.
- term **keywords**: The keywords connected to this tag.
- term **languageCode**: The language code for the tag title and keywords.

The parameters can be either sent as `application/json` or `multipart/form-data`.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<id>",
    "detailId": "<detail-id>",
    "languageCode": "<language-code>",
    "availableLanguageCodes": ["<language-code>", ...],
    "title": "<title>",
    "slug": "<slug>",
    "keywords": [
        "<keyword-1>",
        ...
    ],
}
```

The created and returned tag will not be visible until it has been verified by a moderator.

## See Also

* ``Tag/Detail/Create``
* ``Tag/Detail/Detail``
