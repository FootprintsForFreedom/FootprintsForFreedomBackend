# Verify a waypoint report

Verifies a waypoint report.

## Request

    POST /api/v1/waypoints/<waypoint-repository-id>/reports/verify/<waypoint-report-id>

This endpoint is only available to moderators.

The moderator token has to be sent as a `BearerToken` with the request.

## Response

**Content-Type**: `application/json`

```json
{
    "id": "<waypoint-repository-id>",
    "title": "<report-title>",
    "slug": "<report-slug>",
    "reason": "<report-reason>",
    "status": "<report-status>",
    "reportId": "<report-id>",
    "visibleDetail": {
        <waypoint-detail-object>
    }
}
```

The `<waypoint-detail-object>` is the same as the detail object returned when detailing waypoint: <doc:WaypointDetail>

## See Also

* ``Report/Detail``
* ``Waypoint/Detail/Detail``
