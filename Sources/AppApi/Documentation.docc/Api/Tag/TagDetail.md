# Detail a tag

Gets a tag detail object for the tag id or slug.

## Request

    GET /api/v1/tags/<tag-repository-id>

or

    GET /api/v1/tags/find/<tag-slug>

### Optional query parameters

- term **preferredLanguage**: The language code of the preferred language in which the tag detail should be returned. If the language is available the tag will be returned in this language otherwise detail object in the language with the highest priority that is available will be returned. Default: The language with the highest priority.  

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

If the request is sent with an moderator token, the following additional attribute will be sent in the response: 

```json
"status": "<detail-status>"
```

## See Also

* ``Tag/Detail/Detail``
