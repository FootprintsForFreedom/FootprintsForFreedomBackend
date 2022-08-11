# Detail a media

Gets a media detail object for the media id or slug.

## Request

    GET /api/v1/media/<media-repository-id>

or

    GET /api/v1/media/find/<media-slug>

### Optional query parameters

- term **preferredLanguage**: The language code of the preferred language in which the media detail should be returned. If the language is available the media will be returned in this language otherwise detail object in the language with the highest priority that is available will be returned. Default: The language with the highest priority.  

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<id>",
    "languageCode": "<language-code>",
    "availableLanguageCodes": ["<language-code>", ...],
    "title": "<title>",
    "slug": "<slug>",
    "detailText": "<detail-text>",
    "source": "<source>",
    "group": "<file-group>",
    "filePath": "<file-path>",
    "detailId": "<detail-id>",
    "tags": [
        {
            "id": "<tag-id>",
            "title": "<tag-title>",
            "slug": "<tag-slug>"
        },
        ...
    ]
}
```

> Note: The tag objects are the same as those returned when listing tags: <doc:TagList>.

If the request is sent with an moderator token, the following additional attribute will be sent in the response: 

```json
"status": "<detail-status>"
```

> Note: All media objects with an image, video or document file also have a thumbnail. For more details see: <doc:MediaThumbnail>

## See Also

* <doc:MediaThumbnail>
* ``Media/Detail/Detail``
* ``Tag/Detail/List``
