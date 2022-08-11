# Create a media

Creates a media object from the given input for the specified waypoint.

## Request

    POST /api/v1/media

This endpoint is only available to verified users.

The user token has to be sent as a `BearerToken` with the request.

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **file**: The media file to be uploaded.
- term **title**: The media title.
- term **detailText**: The detail text describing the media.
- term **source**: The source of the media and/or copyright information.
- term **languageCode**: The language code for the media title, description and source.
- term **waypointId**: The id for the waypoint to which the media belongs.

The file has to be sent as the request body and the request content type has to be the content type of the file.

All other parameters need to be sent as url parameters.

### Media types

Currently the following media types are supported:

* video/quicktime
* video/mpeg
* video/mp4
* audio/mpeg
* audio/wav
* audio/vnd.wave
* image/png
* image/jpeg
* application/pdf

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

The created and returned media will not be visible until it has been verified by a moderator.

> Note: All media objects with an image, video or document file also have a thumbnail. For more details see: <doc:MediaThumbnail>

## See Also

* <doc:MediaThumbnail>
* ``Media/Detail/Create``
* ``Media/Detail/Detail``
* ``Tag/Detail/List``
