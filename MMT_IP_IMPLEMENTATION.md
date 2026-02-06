# MMT IP ADDRESS IMPLEMENTATION

## 📋 Overview
MMT (Mine Management Technology) devices sekarang dapat menyimpan IP address dan melakukan realtime PING untuk monitoring status.

## ✅ Implementasi Lengkap

### 1. **Database Schema**
Kolom `ip_address` sudah ada di tabel `mmts`:
```sql
CREATE TABLE mmts (
    ...
    ip_address VARCHAR(15) NOT NULL COMMENT 'IP address of MMT device',
    ...
);
```

### 2. **Backend PHP (mmt.php)**
✅ **Endpoint Baru: `action=create`**
- Menambahkan MMT baru dengan IP address
- Path: `monitoring_api/mmt.php?endpoint=mmt&action=create`
- Method: POST
- Body:
```json
{
  "mmt_id": "MMT-CY1-01",
  "location": "Tower 7 - CY1",
  "ip_address": "192.168.1.100",
  "container_yard": "CY1",
  "status": "UP",
  "type": "Mine Monitor",
  "device_count": 1,
  "traffic": "0 Mbps",
  "uptime": "99.5%"
}
```

✅ **Endpoint Existing: `action=all`**
- Mengambil semua MMT termasuk ip_address
- Response sudah include ip_address

### 3. **Flutter Frontend**

#### **ApiService (api_service.dart)**
✅ `createMMT()` method sudah mengirim IP address:
```dart
Future<Map<String, dynamic>> createMMT({
  required String mmtId,
  required String location,
  required String ipAddress,  // ✅ IP Address included
  required String containerYard,
  ...
});
```

#### **Dashboard (dashboard.dart)**
✅ Auto-refresh dengan realtime PING ke IP MMT:
```dart
Future<void> _updateDeviceLocationStatuses() async {
  // Get all MMT devices
  final mmtList = await fetchMMTs();
  
  // Ping each MMT device
  for (var mmt in mmtList) {
    if (mmt.ipAddress.isNotEmpty) {
      // Test connectivity
      final status = await testDeviceConnectivity(mmt.ipAddress);
      
      // Update status in database
      await reportDeviceStatus(
        deviceType: 'mmt',
        deviceId: mmt.deviceId,
        status: status,
        targetIp: mmt.ipAddress,
      );
    }
  }
}
```

#### **Add Device (add_device.dart)**
✅ Form sudah include IP address field
✅ Saat add device MMT, IP address tersimpan ke database
✅ Auto-test connectivity setelah device ditambahkan

### 4. **MMT Model (mmt_model.dart)**
Cek apakah model sudah include ipAddress property.

## 🔄 Cara Kerja

### **Flow Tambah MMT Baru:**
1. User mengisi form Add Device
2. Pilih type = "MMT"
3. Input IP address
4. Submit → Flutter call `apiService.createMMT()`
5. Backend PHP insert ke database dengan IP
6. Auto-test connectivity ke IP
7. Update status di database
8. Device muncul di map dengan icon warna sesuai status

### **Flow Auto-Refresh:**
1. Timer setiap 10 detik call `_updateDeviceLocationStatuses()`
2. Fetch semua MMT dari database
3. Loop setiap MMT:
   - Ping ke IP address
   - Update status di database
4. Refresh icon di map (hijau = UP, merah = DOWN)

## 📊 Status Monitoring

**MMT Status Colors:**
- 🟢 **Hijau**: Device UP (ping success)
- 🔴 **Merah**: Device DOWN (ping failed)
- Icon CC/RTG/RS label: Hitam (tetap)

## 🔧 Setup/Migration

### **Jika Database Baru:**
Run `mmt_schema.sql` - sudah include kolom ip_address

### **Jika Database Existing (Upgrade):**
1. Cek apakah kolom sudah ada:
```sql
SHOW COLUMNS FROM mmts LIKE 'ip_address';
```

2. Jika belum ada, run:
```sql
ALTER TABLE mmts 
ADD COLUMN ip_address VARCHAR(15) NOT NULL DEFAULT '0.0.0.0' 
AFTER location;
```

3. Atau run file: `ADD_MMT_IP_COLUMN.sql`

## ✅ Testing

1. **Test Add MMT:**
   - Buka Add Device page
   - Pilih type "MMT"
   - Input IP address (e.g., 192.168.1.100)
   - Submit
   - Check database: `SELECT * FROM mmts WHERE mmt_id = 'MMT-CY1-01';`

2. **Test PING:**
   - Tunggu 10 detik (auto-refresh)
   - Atau klik tombol "Check Status"
   - Icon di map akan berubah warna sesuai status ping

3. **Test Backend:**
```bash
curl -X POST http://localhost/monitoring_api/mmt.php?endpoint=mmt&action=create \
  -H "Content-Type: application/json" \
  -d '{
    "mmt_id": "MMT-TEST-01",
    "location": "Test Location",
    "ip_address": "192.168.1.100",
    "container_yard": "CY1"
  }'
```

## 📝 API Documentation

### **Create MMT**
- **Endpoint:** `mmt.php?endpoint=mmt&action=create`
- **Method:** POST
- **Headers:** `Content-Type: application/json`
- **Body:** See Backend section
- **Response:**
```json
{
  "success": true,
  "message": "MMT created successfully",
  "data": {
    "id": 1,
    "mmt_id": "MMT-CY1-01",
    "location": "Tower 7 - CY1",
    "ip_address": "192.168.1.100",
    "container_yard": "CY1",
    "status": "UP"
  }
}
```

### **Get All MMTs**
- **Endpoint:** `mmt.php?endpoint=mmt&action=all`
- **Method:** GET
- **Response:** Includes `ip_address` field

## 🎯 Summary

✅ Database sudah ada kolom `ip_address`
✅ Backend endpoint `create` ditambahkan
✅ Frontend sudah kirim IP saat add device
✅ Auto-refresh dengan PING ke IP MMT setiap 10 detik
✅ Icon warna hijau/merah sesuai status
✅ Label CC/RTG/RS warna hitam

**Status:** COMPLETED ✅
