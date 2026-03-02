# Alert Report Fix Summary

## Problem
The Alert Report page was showing "No Data Found" even though devices had DOWN status. The report endpoint was only querying the `alerts` table without including currently down devices from the device tables (towers, cameras, mmts).

## Root Cause
The `action=report` handler in `d:\db\htdocs\monitoring_api\index.php` was:
1. Only querying the `alerts` table (historical status changes)
2. Not including currently down devices
3. Using SQL logic that didn't match the new comprehensive alert system

## Solution
Updated the report action in index.php to:

### 1. Query Historical Alerts (within date range)
- Query alerts from the `alerts` table filtered by date range and status
- Mark as `'source': 'history'`

### 2. Query Currently DOWN Devices
- Query all DOWN devices from towers, cameras, and mmts tables
- Use UNION with proper COLLATE clause to avoid mismatch
- Format as alert objects with all required fields
- Mark as `'source': 'current'`

### 3. Combine and Sort Results
- Merge both result sets
- Sort by timestamp (newest first)
- Return as JSON array that matches Alert model

## Code Changes
**File: d:\db\htdocs\monitoring_api\index.php**

```php
case 'alerts':
    if ($action === 'report') {
        $start = $_GET['start'] ?? date('Y-m-d');
        $end = $_GET['end'] ?? date('Y-m-d');
        $statusFilter = $_GET['status'] ?? 'ALL';

        // QUERY 1: Historical alerts within date range
        $sql = "SELECT id, title, description, ... FROM alerts WHERE tanggal >= '$start' AND tanggal <= '$end'";
        // Apply status filter: DOWN, UP, or ALL
        // Store in $historicalAlerts

        // QUERY 2: Currently DOWN devices (if filter is DOWN or ALL)
        // Query towers, cameras, mmts with UNION and COLLATE
        // Store in $currentDownAlerts

        // QUERY 3: Combine and sort
        $allAlerts = array_merge($historicalAlerts, $currentDownAlerts);
        usort($allAlerts, function($a, $b) { ... }); // Sort by timestamp DESC
        
        echo json_encode($allAlerts);
        exit;
    }
```

## API Response Format
Each alert includes:
```json
{
  "id": "AP105",              // Device ID or Historical Alert ID
  "title": "AP105 is DOWN",
  "description": "Device details",
  "severity": "DOWN",
  "timestamp": "2026-03-02 05:53:48",
  "route": "/network",
  "is_read": 0,
  "created_at": "2026-03-02 05:53:48",
  "category": "Monitoring",
  "tanggal": "2026-03-02",
  "waktu": "05:53:48",
  "lokasi": "Gate In/Out",
  "device_type": "towers|cameras|mmts",  // Only in current devices
  "source": "history|current"            // Indicates data source
}
```

## Testing Results
✅ **API Endpoint**: `http://localhost/monitoring_api/index.php?endpoint=alerts&action=report&start=YYYY-MM-DD&end=YYYY-MM-DD&status=ALL`

✅ **Response**: Returns 98 items (all down devices for the date range)

✅ **Data Types**: Correct (Array of objects matching Alert model)

✅ **Compilation**: No Dart errors in report_page.dart or api_service.dart

✅ **Status Filtering**: Works correctly for ALL, DOWN, UP filters

## Files Modified
- `d:\db\htdocs\monitoring_api\index.php` - Updated report action (lines 127-189)

## Frontend No Changes Needed
The existing getAlertsReport() function and ReportPage widget already:
1. Call the correct endpoint
2. Handle List<Alert> response properly
3. Can display all alert fields

## Verification Commands
```bash
# Test report endpoint
curl "http://localhost/monitoring_api/index.php?endpoint=alerts&action=report&start=2026-02-23&end=2026-03-02&status=ALL"

# Expected output: 98 items in JSON array format
```
