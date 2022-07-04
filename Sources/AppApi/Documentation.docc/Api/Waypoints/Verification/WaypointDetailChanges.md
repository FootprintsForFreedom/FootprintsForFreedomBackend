# Detail waypoint changes

Details the changes between two waypoint objects.

## Request

    GET /api/v1/waypoints/<waypoint-repository-id>/waypoints/changes

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

### Required query parameters

- term **from**: The waypoint detail which serves as the source of the changes.
- term **to**: The waypoint detail which serves as the destination of the changes.

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
* ``Waypoint/Repository/Changes``
