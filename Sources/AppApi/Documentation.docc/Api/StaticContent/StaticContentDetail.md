# Detail a static content

Gets a static content detail object for the static content id or slug.

## Request

    GET /api/v1/staticContent/<static-content-id>

or 

    GET /api/v1/staticContent/<static-content-slug>

### Optional query parameters

- term **preferredLanguage**: The language code of the preferred language in which the static content detail should be returned. If the language is available the static content will be returned in this language otherwise detail object in the language with the highest priority that is available will be returned. Default: The language with the highest priority.  

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
If the request is sent with an admin token, the following additional attribute will be sent in the response: 

```json
"moderationTitle": "<static-content-moderation-title>",
"requiredSnippets": [
    "<snippet-name>",
    ...
]
```

## See Also

* ``StaticContent/Detail/Detail``
