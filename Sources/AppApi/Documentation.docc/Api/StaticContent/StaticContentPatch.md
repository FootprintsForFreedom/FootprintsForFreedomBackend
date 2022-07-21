# Patch a static content

Patches an existing static content object from the given input.

## Request

    PATCH /api/v1/staticContent/<static-content-repository-id>

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

### Input parameters

The parameter `idForStaticContentDetailToPatch` and at least one of the other following parameters has to be sent with the request for it to be successful:  

- term **moderationTitle**: The localized title describing the the static content to a moderator. 
- term **title**: The localized title visible to users. It can also contain snippets. 
- term **text**: The localized text visible to users. If any snippets are required this text needs to contain those.  
- term **idForStaticContentDetailToPatch**: The id of an existing static content. All parameters not set in this request will be taken from this static content.

The parameters can be either sent as `application/json` or `multipart/form-data`.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<static-content-id>",
    "detailId": "<static-content-detail-id>",
    "title": "<static-content-title>",
    "text": "<static-content-text>",
    "languageCode": "<language-code>",
    "availableLanguageCodes": ["<language-code>", ...]
}
```

## See Also

* ``StaticContent/Detail/Patch``
* ``StaticContent/Detail/Detail``
