# Detail tag changes

Details the changes between two tag objects.

## Request

    GET /api/v1/tags/<tag-repository-id>/changes

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

### Required query parameters

- term **from**: The tag detail which serves as the source of the changes.
- term **to**: The tag detail which serves as the destination of the changes.

Both details need to be of the same language.

## Response

**Content-Type**: `application/json`

```json
{
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
    "equalKeywords": [<equal-keyword-1>, ...],
    "deletedKeywords": [<deleted-keyword-1>, ...],
    "insertedKeywords": [<inserted-keyword-1>, ...],
}
```

The `diff`s consist of an array of items labeled as `delete`, `insert` and `delete` detailing how the text has changed in the order of the differences. 

## See Also

* ``DetailChangesObject``
* ``Tag/Repository/Changes``
