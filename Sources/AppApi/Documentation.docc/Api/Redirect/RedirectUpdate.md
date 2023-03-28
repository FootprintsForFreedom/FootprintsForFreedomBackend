# Update a redirect

Updates an existing redirect from the given input.

## Request

    PUT /api/v1/redirects/<redirect-id>

This endpoint is only available to admins.

The admin user token has to be sent as a `BearerToken` with the request.

> Important: Changes to redirects don't need to be verified, they take effect immediately.

> Warning: Redirects exist to ensure old url paths still point to their respective content. Editing a redirect might cause those links to break. **Proceed with caution.**

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **source**: The url path from which to redirect from.
- term **destination**: The url path to which to redirect.

> important: 
>
> The `source` must not be the `source` or `destination` of another redirect. 
>
> The `destination` must not be the `source` of another redirect.

> note: The `source` and `destination` input parameters can contain leading and trailing slashes (`/`). However, the response content will always be stripped of these.

The parameters can be either sent as `application/json` or `multipart/form-data`.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<redirect-id>",
    "source": "<redirect-source>"
    "destination": "<redirect-destination>",
}
```

## See Also

* ``Redirect/Detail/Create``
* ``Redirect/Detail/Detail``
