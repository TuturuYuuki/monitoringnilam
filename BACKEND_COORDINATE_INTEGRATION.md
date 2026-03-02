# 🔌 Backend Coordinate Integration Guide

**Status**: Ready for Implementation  
**Target Endpoints**: `/towers`, `/cameras`  
**Database Fields Required**: `latitude`, `longitude`  
**Date**: March 2, 2026

---

## 📋 **Overview**

The Flutter app now supports a PNG layout-based map system (`NilamLayoutMap`) that displays devices on a custom terminal layout image instead of Google Maps. This requires the backend API to return geographic coordinates (latitude/longitude) for each device.

---

## 🗄️ **Database Schema Changes**

### **Required for Towers Table**
```sql
-- Add coordinates columns to towers table
ALTER TABLE towers ADD COLUMN latitude DOUBLE NULL DEFAULT NULL;
ALTER TABLE towers ADD COLUMN longitude DOUBLE NULL DEFAULT NULL;

-- Add indexes for faster queries
CREATE INDEX idx_tower_coordinates ON towers(latitude, longitude);
```

### **Required for Cameras Table**
```sql
-- Add coordinates columns to cameras table  
ALTER TABLE cameras ADD COLUMN latitude DOUBLE NULL DEFAULT NULL;
ALTER TABLE cameras ADD COLUMN longitude DOUBLE NULL DEFAULT NULL;

-- Add indexes for faster queries
CREATE INDEX idx_camera_coordinates ON cameras(latitude, longitude);
```

---

## 📍 **Coordinate Data**

### **Reference Bounding Box (TPK Nilam Area)**
```
Latitude Range:  -7.210500 (South) to -7.203500 (North)
Longitude Range: 112.721500 (West) to 112.725800 (East)

PNG Dimensions: 1400 × 900 pixels (placeholder - adjust to actual PNG size)
```

### **Tower Coordinates** (26 total)
All coordinates are available in the project:
- See: `COORDINATES_BACKUP.md` - Human-readable markdown format
- See: `coordinates_backup.json` - Structured JSON format
- See: `lib/constants/coordinates_backup.dart` - Dart constants

**Sample Tower Data**:
```json
{
  "id": 1,
  "tower_id": "Tower 1",
  "tower_number": 1,
  "location": "TPK Nilam - CY2",
  "ip_address": "192.168.1.101",
  "status": "UP",
  "container_yard": "CY2",
  "latitude": -7.209459,
  "longitude": 112.724717,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### **Camera Coordinates** (4 total - CC01 to CC04)
```json
{
  "id": 1,
  "camera_id": "CC01",
  "location": "CC01 - CY1",
  "ip_address": "192.168.1.201",
  "status": "UP",
  "type": "Fixed",
  "container_yard": "CY1",
  "area_type": "Entry",
  "latitude": -7.204768,
  "longitude": 112.723299,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

---

## 🔗 **API Endpoint Updates**

### **GET /towers**
**Current Response**:
```json
{
  "towers": [
    {
      "id": 1,
      "tower_id": "Tower 1",
      "tower_number": 1,
      "location": "TPK Nilam - CY2",
      "ip_address": "192.168.1.101",
      "status": "UP",
      "container_yard": "CY2",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

**Updated Response** (Add coordinates):
```json
{
  "towers": [
    {
      "id": 1,
      "tower_id": "Tower 1",
      "tower_number": 1,
      "location": "TPK Nilam - CY2",
      "ip_address": "192.168.1.101",
      "status": "UP",
      "container_yard": "CY2",
      "latitude": -7.209459,
      "longitude": 112.724717,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### **GET /cameras**
**Updated Response** (Add coordinates):
```json
{
  "cameras": [
    {
      "id": 1,
      "camera_id": "CC01",
      "location": "CC01 - CY1",
      "ip_address": "192.168.1.201",
      "status": "UP",
      "type": "Fixed",
      "container_yard": "CY1",
      "area_type": "Entry",
      "latitude": -7.204768,
      "longitude": 112.723299,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

---

## 💻 **PHP Implementation Example**

### **towers.php** (GET endpoint)
```php
<?php
// Existing code...

$sql = "SELECT 
          id, 
          tower_id, 
          tower_number, 
          location, 
          ip_address, 
          status, 
          container_yard,
          latitude,          // NEW FIELD
          longitude,         // NEW FIELD
          created_at, 
          updated_at 
        FROM towers 
        ORDER BY tower_number ASC";

$result = $conn->query($sql);
$towers = [];

while ($row = $result->fetch_assoc()) {
    $towers[] = [
        'id' => $row['id'],
        'tower_id' => $row['tower_id'],
        'tower_number' => $row['tower_number'],
        'location' => $row['location'],
        'ip_address' => $row['ip_address'],
        'status' => $row['status'],
        'container_yard' => $row['container_yard'],
        'latitude' => $row['latitude'] ? (float)$row['latitude'] : null,    // NEW
        'longitude' => $row['longitude'] ? (float)$row['longitude'] : null,  // NEW
        'created_at' => $row['created_at'],
        'updated_at' => $row['updated_at']
    ];
}

echo json_encode(['towers' => $towers]);
?>
```

### **cameras.php** (GET endpoint)
```php
<?php
// Existing code...

$sql = "SELECT 
          id, 
          camera_id, 
          location, 
          ip_address, 
          status, 
          type, 
          container_yard,
          area_type,
          latitude,          // NEW FIELD
          longitude,         // NEW FIELD
          created_at, 
          updated_at 
        FROM cameras 
        ORDER BY camera_id ASC";

$result = $conn->query($sql);
$cameras = [];

while ($row = $result->fetch_assoc()) {
    $cameras[] = [
        'id' => $row['id'],
        'camera_id' => $row['camera_id'],
        'location' => $row['location'],
        'ip_address' => $row['ip_address'],
        'status' => $row['status'],
        'type' => $row['type'],
        'container_yard' => $row['container_yard'],
        'area_type' => $row['area_type'],
        'latitude' => $row['latitude'] ? (float)$row['latitude'] : null,    // NEW
        'longitude' => $row['longitude'] ? (float)$row['longitude'] : null,  // NEW
        'created_at' => $row['created_at'],
        'updated_at' => $row['updated_at']
    ];
}

echo json_encode(['cameras' => $cameras]);
?>
```

---

## 🧪 **Testing**

### **Test Coordinate Parsing**
```bash
# After updating backend, test with:
curl http://your-api/towers | jq '.towers[0] | {id, tower_id, latitude, longitude}'

# Should return:
# {
#   "id": 1,
#   "tower_id": "Tower 1",
#   "latitude": -7.209459,
#   "longitude": 112.724717
# }
```

### **Test Flutter App**
Once backend returns coordinates:

1. **Coordinate Validation**
   - App will parse lat/lng from API response
   - Models validate coordinate ranges

2. **PNG Layout Map Activation**
   - Uncomment in `dashboard.dart` line ~2045:
   ```dart
   NilamLayoutMap(
     markers: _buildDeviceMarkersForLayoutMap(),
     layoutImagePath: 'assets/images/nilam_layout.png',
     showDebugGrid: false,
     showCoordinateLabels: false,
     onMarkerTap: (marker) {
       print('📍 Tapped: ${marker.name}');
     },
   )
   ```

3. **Debug Features**
   - Set `showDebugGrid: true` to visualize pixel grid
   - Set `showCoordinateLabels: true` to see pixel coordinates
   - Check [layout_mapper.dart](lib/utils/layout_mapper.dart) for calibration tools

---

## 🎯 **Flutter Integration Points**

### **Models Updated**
- `lib/models/tower_model.dart` - Added `latitude`, `longitude` fields
- `lib/models/camera_model.dart` - Added `latitude`, `longitude` fields

### **Helper Function Ready**
- `lib/dashboard.dart` - `_buildDeviceMarkersForLayoutMap()` converts tower/camera data to marker objects with pixel coordinates

### **Map System Ready**
- `lib/widgets/nilam_layout_map.dart` - Custom PNG-based map widget
- `lib/utils/layout_mapper.dart` - Geographic ↔ Pixel coordinate converter
- `lib/models/device_marker.dart` - Device marker data with type/status

### **PNG Image Required**
- Place `nilam_layout.png` at: `assets/images/nilam_layout.png`
- Update PNG dimensions in [layout_mapper.dart](lib/utils/layout_mapper.dart):
  ```dart
  static const double PNG_WIDTH = 1400;    // Update to actual width
  static const double PNG_HEIGHT = 900;    // Update to actual height
  ```

---

## ✅ **Implementation Checklist**

- [ ] Add `latitude` and `longitude` columns to `towers` table
- [ ] Add `latitude` and `longitude` columns to `cameras` table
- [ ] Create database indexes for coordinates
- [ ] Update `/towers` API endpoint to return coordinates
- [ ] Update `/cameras` API endpoint to return coordinates
- [ ] Test API endpoints return `null` safe coordinates
- [ ] Update Flutter app with PNG layout image
- [ ] Activate NilamLayoutMap in dashboard (uncomment lines)
- [ ] Test markers display correctly on PNG layout
- [ ] Calibrate coordinate system if needed

---

## 📞 **Questions?**

See related documentation:
- [COORDINATES_BACKUP.md](COORDINATES_BACKUP.md) - All coordinate reference data
- [layout_mapper.dart](lib/utils/layout_mapper.dart) - Coordinate conversion details
- [nilam_layout_map.dart](lib/widgets/nilam_layout_map.dart) - Map widget implementation

**Status**: 🟢 Ready to implement
