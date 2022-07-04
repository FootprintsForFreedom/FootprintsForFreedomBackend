# Create a waypoint report

Creates a new report for a waypoint repository.

## Request

    POST /api/v1/waypoints/<waypoint-repository-id>/reports

This endpoint is only available to verified users.

The user token has to be sent as a `BearerToken` with the request.

### Input parameters

The following parameters have to be sent with the request for it to be successful:

- term **title**: The report title.
- term **reason**: The reason to report the waypoint.
- term **visibleDetailId**: The currently visible detail id. This is so it is known to which language this report belongs and wether the waypoint has since been updated.

The parameters can be either sent as `application/json` or `multipart/form-data`.

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

* ``Report/Create``
* ``Report/Detail``
* ``Waypoint/Detail/Detail``
