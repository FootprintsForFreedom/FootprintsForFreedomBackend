# Delete a static content

Deletes a static content object with all details in all languages.

## Request

> Warning: Since other parts of the backend application or frontend applications might depend on certain static content objects, deleting those could lead to problems. **Proceed with caution.**

    DELETE /api/v1/staticContent/<static-content-repository-id>

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

## Response

If the deletion was successful a HTTP Status code `204 - no Content` will be returned.
