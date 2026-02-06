# Dynamic Device Monitoring Implementation

## Overview
Sistem monitoring diperbarui untuk mendukung IP address yang berbeda-beda per device. Setiap device sekarang memiliki status connectivity yang dinamis berdasarkan IP-nya sendiri, bukan hardcoded ke IP tertentu.

## Changes Made

### 1. Add Device Page (`add_device.dart`)
**Fitur Baru:**
- Setelah device berhasil ditambahkan ke database, sistem akan otomatis test connectivity ke IP device tersebut
- Status device akan di-update secara realtime berdasarkan hasil test
- Setiap device type (Tower, CCTV, MMT) mendapat perlakuan yang sama

**Code Flow:**
```
User inputs device info (with IP address)
        ↓
Create device in database
        ↓
Test connectivity to that device's IP (not hardcoded IP)
        ↓
Update device status based on connectivity result (UP/DOWN)
```

### 2. Network Monitoring Pages (`network.dart`, `network_cy2.dart`, `network_cy3.dart`)
**Perubahan:**
- `_triggerRealtimePing()` sekarang loop melalui setiap tower
- Untuk setiap tower, test connectivity ke IP tower itu (dari field `ipAddress`)
- Update status individual untuk setiap tower berdasarkan test result

**Behavior:**
- Tower dengan IP yang accessible → Status UP
- Tower dengan IP yang tidak accessible → Status DOWN
- Setiap 10 detik, sistem refresh semua status berdasarkan konektivitas real device

## API Integration

### Device Ping Endpoint (`device_ping.php`)
```php
// Test connectivity to specific IP
GET /index.php?endpoint=device-ping&action=test&ip=192.168.1.100
Response: {
  "success": true,
  "data": {
    "target_ip": "192.168.1.100",
    "status": "UP|DOWN",
    "connected": true|false,
    "timestamp": "2026-02-04 08:27:17"
  }
}

// Report device status update
POST /index.php?endpoint=device-ping&action=report
Body: {
  "type": "Tower|CCTV|MMT",
  "device_id": "T-CY1-01",
  "status": "UP|DOWN",
  "target_ip": "192.168.1.100"
}
```

### Api Service Methods
```dart
// Test connectivity to specific IP
await apiService.testDeviceConnectivity(targetIp: '192.168.1.100')

// Report device status
await apiService.reportDeviceStatus(
  deviceType: 'Tower',
  deviceId: 'T-CY1-01',
  status: 'UP',
  targetIp: '192.168.1.100'
)
```

## Example Scenarios

### Scenario 1: Adding New Tower
1. User navigates to "Add Device"
2. Fills form:
   - Device ID: `T-CY1-27`
   - IP Address: `192.168.100.50`
   - Location: Tower 27 - CY1
3. System creates tower in database
4. System tests connectivity to `192.168.100.50`
5. If reachable → Status set to UP
6. If not reachable → Status set to DOWN
7. Every 10 seconds, status updates based on real connectivity

### Scenario 2: Dynamic Status Change
1. Tower T-CY1-08 added with IP 192.168.100.100 (connected to WiFi A)
2. Initial status: UP
3. Device switches to WiFi B (different network)
4. Next ping cycle tests 192.168.100.100 → fails
5. Status changes to DOWN automatically
6. Device switches back to WiFi A
7. Next ping cycle tests 192.168.100.100 → succeeds
8. Status changes back to UP

### Scenario 3: Multiple Devices, Different IPs
- T-CY1-01: 192.168.1.10 (UP)
- T-CY1-02: 10.0.0.5 (DOWN - unreachable)
- T-CY2-01: 172.16.0.20 (UP)
- Each device tested independently with its own IP

## Implementation Details

### Add Device Flow
```dart
// After device created in database
if (apiResult['success'] == true && deviceIpAddress.isNotEmpty) {
  // Test connectivity
  final connectivityTest = await apiService.testDeviceConnectivity(
    targetIp: deviceIpAddress,
  );
  
  // Update status based on test result
  if (connectivityTest['success'] == true) {
    final testStatus = connectivityTest['data']['status'];
    await apiService.reportDeviceStatus(
      deviceType: _selectedDeviceType,
      deviceId: deviceId,
      status: testStatus,
      targetIp: deviceIpAddress,
    );
  }
}
```

### Realtime Monitoring Loop
```dart
Future<void> _triggerRealtimePing() async {
  for (final tower in towers) {
    if (tower.ipAddress.isEmpty) continue;
    
    // Test each tower's own IP
    final testResult = await apiService.testDeviceConnectivity(
      targetIp: tower.ipAddress,  // ← Per-device IP
    );
    
    // Update each tower individually
    await apiService.reportDeviceStatus(
      deviceType: 'Tower',
      deviceId: tower.towerId,
      status: testResult['data']['status'],
      targetIp: tower.ipAddress,  // ← Per-device IP
    );
  }
}
```

## Benefits

1. **Per-Device IP Support**: Setiap device bisa punya IP berbeda
2. **Accurate Status**: Status reflects actual connectivity device, bukan server
3. **Dynamic Updates**: Status berubah otomatis sesuai konektivitas real-time
4. **Independent Testing**: Tidak ada hardcoded IP, fleksibel untuk network apapun
5. **Realtime Feedback**: User lihat status akurat dalam 10 detik

## Testing

### Test 1: Add Device with Reachable IP
```bash
# Scenario: Add tower dengan IP yang accessible
Expected: Status immediately becomes UP
Verify: Check database, tower status = UP
```

### Test 2: Add Device with Unreachable IP
```bash
# Scenario: Add tower dengan IP yang tidak reachable
Expected: Status immediately becomes DOWN
Verify: Check database, tower status = DOWN
```

### Test 3: Dynamic Status Change
```bash
# Scenario: 
# 1. Add tower with accessible IP → UP
# 2. Disconnect from network
# 3. Wait 10 seconds
Expected: Status changes to DOWN
Verify: Check database, tower status updated to DOWN
```

### Test 4: Multiple Devices
```bash
# Scenario: Add 3 towers dengan IP berbeda
# T1: 192.168.1.100 (accessible)
# T2: 10.0.0.1 (not accessible)
# T3: 172.16.0.50 (accessible)
Expected: T1 UP, T2 DOWN, T3 UP
Verify: Check dashboard, status matches
```

## Database Fields Used

```sql
-- towers table
id, device_id, tower_id, ip_address, status, container_yard, ...

-- cameras table
id, device_id, camera_id, ip_address, status, container_yard, ...

-- mmts table
id, device_id, mmt_id, ip_address, status, container_yard, ...
```

## Notes

- IP address field harus diisi saat add device (form validation)
- System akan skip device tanpa IP address
- Test connectivity timeout: 2 detik per device
- Small delay (100ms) antara test untuk avoid server overload
- Database update delay: 500ms untuk ensure konsistensi

## Future Enhancements

1. Configurable timeout per device type
2. Ping history dan trend analysis
3. Network segment detection (automatic IP grouping)
4. Custom port testing (not just port 80)
5. Device health dashboard dengan metrics
6. Automatic alert saat status change
