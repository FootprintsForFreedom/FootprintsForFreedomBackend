# Delete a redirect

Deletes a redirect object.

## Request

> Warning: Redirects exist to ensure old url paths still point to their respective content. Removing a redirect might cause those links to break. **Proceed with caution.**

    DELETE /api/v1/redirects/<redirect-id>

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

## Response

If the deletion was successful a HTTP Status code `204 - no Content` will be returned.
