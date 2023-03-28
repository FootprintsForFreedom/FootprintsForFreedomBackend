# Delete a tag

Deletes a tag object with all details in all languages.

## Request

    DELETE /api/v1/tags/<tag-repository-id>

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

## Response

If the deletion was successful a HTTP Status code `204 - no Content` will be returned.
