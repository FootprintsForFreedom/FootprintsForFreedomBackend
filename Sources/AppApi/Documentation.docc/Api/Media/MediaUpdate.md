# Update a media

Updates an existing media object from the given input.

## Request

    PUT /api/v1/media/<media-repository-id>

This endpoint is only available to verified users.

The user token has to be sent as a `BearerToken` with the request.

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **title**: The media title.
- term **detailText**: The detail text describing the media.
- term **source**: The source of the media and/or copyright information.
- term **languageCode**: The language code for the media title, description and source. 
- term **mediaIdForFile**: The id of an existing media. The updated media will have the same file as this media.

All parameters need to be sent as url parameters.

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

The updated and returned media will not be visible until it has been verified by a moderator.

> Note: All media objects with an image, video or document file also have a thumbnail. For more details see: <doc:MediaThumbnail>

## See Also

* <doc:MediaThumbnail>
* ``Media/Detail/Update``
* ``Media/Detail/Detail``
* ``Tag/Detail/List``
