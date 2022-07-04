# Detail media changes

Details the changes between two media objects.

## Request

    GET /api/v1/media/<media-repository-id>/changes

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

### Required query parameters

- term **from**: The media detail which serves as the source of the changes.
- term **to**: The media detail which serves as the destination of the changes.

Both details need to be of the same language.

## Response

**Content-Type**: `application/json`

```json
{
    "fromGroup": "<from-media-file-group>",
    "toGroup": "<to-media-file-group>",
    "fromFilePath": "<from-media-file-path>",
    "toFilePath": "<to-media-file-path>",
    "fromUser": {
      "id": "<from-user-id>",
      "name": "<from-user-name>",
      "school": "<from-user-school>"
    },
    "toUser": {
        "id": "<to-user-id>",
        "name": "<to-user-name>",
        "school": "<to-user-school>"
    },
    "titleDiff": [
        {
            "delete": {
                "text": "<deleted-text>"
            }
        },
        {
            "insert": {
                "text": "<inserted-text>"
            }
        }
    ],
    "sourceDiff": [
        {
            "equal": {
                "text": "<equal-text>"
            }
        }
    ],
    "detailTextDiff": [
        {
            "equal": {
                "text": "<equal-text>"
            }
        }
    ]
}
```

The `diff`s consist of an array of items labeled as `delete`, `insert` and `delete` detailing how the text has changed in the order of the differences. 

## See Also

* ``DetailChangesObject``
* ``Media/Repository/Changes``
