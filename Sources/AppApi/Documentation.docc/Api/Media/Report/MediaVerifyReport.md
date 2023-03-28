# Verify a media report

Verifies a media report.

## Request

    POST /api/v1/media/<media-repository-id>/reports/verify/<media-report-id>

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<media-repository-id>",
    "title": "<report-title>",
    "slug": "<report-slug>",
    "reason": "<report-reason>",
    "status": "<report-status>",
    "reportId": "<report-id>",
    "visibleDetail": {
        <media-detail-object>
    }
}
```

The `<media-detail-object>` is the same as the detail object returned when detailing media: <doc:MediaDetail>

## See Also

* ``Report/Detail``
* ``Media/Detail/Detail``
