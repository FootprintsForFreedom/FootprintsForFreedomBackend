# Patch a tag

Patches an existing tag object from the given input.

## Request

    PATCH /api/v1/tags/<tag-repository-id>

This endpoint is only available to verified users.

The user token has to be sent as a `BearerToken` with the request.

### Input parameters

The parameter `idForTagToPatch` and at least one of the other following parameters has to be sent with the request for it to be successful:  

- term **title**: The tag title.
- term **detailText**: The detail text describing the tag.
- term **location**: The location of the tag.
- term **idForTagDetailToPatch**: The id of an existing tag. All parameters not set in this request will be taken from this tag.

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

The patched and returned tag will not be visible until it has been verified by a moderator.

## See Also

* ``Tag/Detail/Patch``
* ``Tag/Detail/Detail``
