# List unverified tags for a waypoint repository

Lists all tags that were added or requested to be deleted but are not yet verified.

## Request 

    GET /api/v1/waypoints/<waypoint-repository-id>/tags/unverified

> Note: To get repositories with unverified tags see: <doc:WaypointListRepositoriesWithUnverifiedModels>.

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

## Response

### Optional query parameters

- term **preferredLanguage**: The language code of the preferred language in which each tag object should be returned. 

    If the language is available the tag will be returned in this language. Otherwise a detail object in the language with the highest priority available will be returned. 

    Default: The language with the highest priority.
- term **per**: The amount of items which should be sent per page. Default: 10
- term **page**: The number of the page which should be returned. Default: 1

## Response

**Content-Type**: `application/json`

```json
{
    "items": [
        {
            "tagId": "<tag-1-id>",
            "title": "<tag-1-title>",
            "slug": "<tag-1-slug>",
            "status": "<tag-1-status>",
            "languageCode": "<tag-1-language-code>"
        },
        ...
    ],
    "metadata": {
        "per": <number-of-items-per-page>,
        "total": <total-number-of-items>,
        "page": <number-of-current-page>
    }
}
```

## See Also

* ``Language/Request/PreferredLanguage``
* ``PageRequest``
* ``Tag/Repository/ListUnverifiedRelation``
* ``Status``
* ``Page``
* ``PageMetadata``
