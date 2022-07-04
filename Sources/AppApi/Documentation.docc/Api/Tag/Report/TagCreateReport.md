# Create a tag report

Creates a new report for a tag repository.

## Request

    POST /api/v1/tags/<tag-repository-id>/reports

This endpoint is only available to verified users.

The user token has to be sent as a `BearerToken` with the request.

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **title**: The report title.
- term **reason**: The reason to report the tag.
- term **visibleDetailId**: The currently visible detail id. This is so it is known to which language this report belongs and wether the tag has since been updated.

The parameters can be either sent as `application/json` or `multipart/form-data`.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<tag-repository-id>",
    "title": "<report-title>",
    "slug": "<report-slug>",
    "reason": "<report-reason>",
    "status": "<report-status>",
    "reportId": "<report-id>",
    "visibleDetail": {
        <tag-detail-object>
    }
}
```

The `<tag-detail-object>` is the same as the detail object returned when detailing tag: <doc:TagDetail>

## See Also

* ``Report/Create``
* ``Report/Detail``
* ``Tag/Detail/Detail``
