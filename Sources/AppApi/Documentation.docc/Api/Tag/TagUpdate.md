# Update a tag

Updates an existing tag object from the given input.

## Request

PUT /api/v1/tags/<tag-repository-id>

This endpoint is only available to verified users.

The user token has to be sent as a `BearerToken` with the request.

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **title**: The tag title.
- term **detailText**: The detail text describing the tag.
- term **languageCode**: The language code for the tag title and description.

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

The updated and returned tag will not be visible until it has been verified by a moderator.

## See Also

* ``Tag/Detail/Update``
* ``Tag/Detail/Detail``
