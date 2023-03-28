# Verify a tag report

Verifies a tag report.

## Request

    POST /api/v1/tags/<tag-repository-id>/reports/verify/<tag-report-id>

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

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

* ``Report/Detail``
* ``Tag/Detail/Detail``
