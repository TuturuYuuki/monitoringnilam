# 🐛 BUG REPORT: Hardcoded IP Address dalam Create Device

**Laporan Tanggal**: February 5, 2026  
**Status**: 🔴 CRITICAL - IP yang diinput user tidak tersimpan, selalu menggunakan hardcoded IP  
**Assigned To**: Backend Developer

---

## 📌 RINGKASAN MASALAH

User melaporkan bahwa saat menambah device dengan IP yang berbeda, database **selalu menyimpan IP `10.2.71.60`** padahal user memasukkan IP yang berbeda.

### ❌ Contoh Kasus:
- User input: IP `192.168.1.100`
- Database save: IP `10.2.71.60` ❌

---

## 🔍 INVESTIGASI & TEMUAN

### ✅ File yang Sudah Diperiksa

#### 1. **Frontend (Dart/Flutter)** - ✅ CLEAN
**File**: [lib/services/api_service.dart](lib/services/api_service.dart)

**Status**: Frontend mengirim IP dengan benar ke backend:

**Lines 835-863 - `createTower()` untuk Access Point/Tower:**
```dart
Future<Map<String, dynamic>> createTower({
  required String towerId,
  required String location,
  required String ipAddress,  // ✅ IP dari parameter
  required String containerYard,
  ...
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl?endpoint=network&action=create'),
    body: jsonEncode({
      'tower_id': towerId,
      'location': location,
      'ip_address': ipAddress,  // ✅ Benar, diambil dari parameter
      'container_yard': containerYard,
      ...
    }),
  );
}
```

**Lines 874-898 - `createCamera()` untuk CCTV:**
```dart
Future<Map<String, dynamic>> createCamera({
  required String cameraId,
  required String location,
  required String ipAddress,  // ✅ IP dari parameter
  required String containerYard,
  ...
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl?endpoint=cctv&action=create'),
    body: jsonEncode({
      'camera_id': cameraId,
      'location': location,
      'ip_address': ipAddress,  // ✅ Benar, diambil dari parameter
      'container_yard': containerYard,
      ...
    }),
  );
}
```

**Lines 914-945 - `createMMT()` untuk MMT:**
```dart
Future<Map<String, dynamic>> createMMT({
  required String mmtId,
  required String location,
  required String ipAddress,  // ✅ IP dari parameter
  required String containerYard,
  ...
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl?endpoint=mmt&action=create'),
    body: jsonEncode({
      'mmt_id': mmtId,
      'location': location,
      'ip_address': ipAddress,  // ✅ Benar, diambil dari parameter
      'container_yard': containerYard,
      ...
    }),
  );
}
```

**Kesimpulan**: Frontend Flutter sudah benar, parameter `ip_address` dikirimkan ke backend sesuai input user.

---

#### 2. **Backend PHP - MMT** - ✅ CLEAN  
**File**: [mmt.php](mmt.php)

**Lines 293-370 - `createMMT()` function:**
```php
function createMMT($conn) {
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    // Validate required fields
    if (!isset($data['mmt_id']) || !isset($data['location']) || 
        !isset($data['ip_address']) || !isset($data['container_yard'])) {
        throw new Exception('Required fields: mmt_id, location, ip_address, container_yard');
    }
    
    $mmtId = $data['mmt_id'];
    $location = $data['location'];
    $ipAddress = $data['ip_address'];  // ✅ Ambil dari request body
    $containerYard = $data['container_yard'];
    ...
    
    // Insert dengan $ipAddress dari request
    $stmt->bind_param("sissssiss", 
        $mmtId, $mmtNumber, $location, $ipAddress, $status,  // ✅ $ipAddress digunakan
        $type, $containerYard, $deviceCount, $traffic, $uptime);
    
    $stmt->execute();
}
```

**Kesimpulan**: Backend MMT sudah benar, menggunakan `$ipAddress` dari request body.

---

#### 3. **Backend PHP - Network/Tower & CCTV** - ⚠️ FILE TIDAK DITEMUKAN

**Status**: File `network.php` dan `cctv.php` tidak ditemukan di workspace!

Frontend mengirim request ke:
- Network: `$baseUrl?endpoint=network&action=create`
- CCTV: `$baseUrl?endpoint=cctv&action=create`

Namun file PHP yang menangani endpoint ini **TIDAK ADA di workspace**.

**Kemungkinan**:
1. File ada di server lokal (XAMPP/local server) tapi tidak disinkronkan ke workspace
2. Ada file router `index.php` yang mengarahkan request ke file lain
3. File ini perlu dibuat

---

### 🔴 HARDCODED IP DITEMUKAN

**File**: [lib/services/api_service.dart](lib/services/api_service.dart)

**Lines 954-982 - `testDeviceConnectivity()` & `reportDeviceStatus()`:**
```dart
// ❌ HARDCODED IP pada parameter default!
Future<Map<String, dynamic>> testDeviceConnectivity({
    String targetIp = '10.2.71.60',  // ⚠️ DEFAULT HARDCODED
}) async { ... }

Future<Map<String, dynamic>> reportDeviceStatus({
    required String deviceType,
    required String deviceId,
    required String status,
    String targetIp = '10.2.71.60',  // ⚠️ DEFAULT HARDCODED
}) async { ... }
```

**Penjelasan**: IP `10.2.71.60` ini adalah IP untuk testing connectivity SETELAH device dibuat, bukan untuk menyimpan IP device itu sendiri.

**Tidak ada masalah** dengan hardcoded IP ini jika parameter `targetIp` dipass dengan benar dari pemanggil function.

---

## 🎯 ROOT CAUSE ANALYSIS

Berdasarkan investigasi, ada 3 kemungkinan penyebab masalah:

### **Kemungkinan 1: Backend Network/CCTV Tidak Ada ⚠️ MOST LIKELY**

File `network.php` dan `cctv.php` yang menangani create request untuk tower dan camera **tidak ada di workspace**.

Jika file ini ada di server lokal, kemungkinan:
- **Tidak menggunakan `$_POST['ip_address']` atau `$data['ip_address']`**
- Menggunakan hardcoded IP atau default value yang salah
- Ada bug dalam extract parameter dari request

---

### **Kemungkinan 2: API Request Tidak Mencapai Backend**

Frontend mengirim request tapi:
- Request berhasil tapi response gagal parse
- Request di-block oleh CORS
- Request tidak sampai ke backend yang benar

---

### **Kemungkinan 3: Database Column Tidak Ada**

Tabel `cameras` atau `towers` mungkin **tidak punya kolom `ip_address`**.

**Untuk MMT**: Kolom `ip_address` sudah ada ✅ (didefinisikan di [mmt_schema.sql](mmt_schema.sql))

**Untuk Tower/Network**: Perlu dicek struktur table `towers`

**Untuk Camera/CCTV**: Perlu dicek struktur table `cameras`

---

## 📋 CHECKLIST INVESTIGASI LANJUTAN

### Untuk Backend Developers:

- [ ] **Cari file `network.php`**
  - Lokasi kemungkinan: `/xampp/htdocs/monitoring_api/network.php`
  - Atau `/var/www/html/monitoring_api/network.php` (Linux)
  - Atau local server yang digunakan

- [ ] **Cari file `cctv.php`**
  - Lokasi kemungkinan: `/xampp/htdocs/monitoring_api/cctv.php`
  - Atau `/var/www/html/monitoring_api/cctv.php` (Linux)

- [ ] **Verifikasi struktur database:**
  ```sql
  -- Untuk Tower
  SHOW COLUMNS FROM towers;
  -- Pastikan ada kolom: ip_address VARCHAR(15) atau sejenis
  
  -- Untuk Camera
  SHOW COLUMNS FROM cameras;
  -- Pastikan ada kolom: ip_address VARCHAR(15) atau sejenis
  ```

- [ ] **Verifikasi function di `network.php` (jika sudah ditemukan):**
  ```php
  function createNetwork($conn) {
      $input = file_get_contents('php://input');
      $data = json_decode($input, true);
      
      // HARUS mengambil dari $data['ip_address']
      $ipAddress = $data['ip_address'];  // ✅ CORRECT
      
      // Insert dengan parameter yang tepat
      $stmt->bind_param(..., $ipAddress, ...);  // ✅ CORRECT
  }
  ```

- [ ] **Verifikasi function di `cctv.php` (jika sudah ditemukan):**
  - Sama dengan checklist network.php

---

## 🛠️ REKOMENDASI FIX

### **Step 1: Cari File Backend (PRIORITAS UTAMA)**

Lokasi yang harus dicek:

1. **XAMPP Local Server** (Windows):
   ```
   C:\xampp\htdocs\monitoring_api\network.php
   C:\xampp\htdocs\monitoring_api\cctv.php
   C:\xampp\htdocs\monitoring_api\index.php  (file router)
   ```

2. **Linux Server**:
   ```
   /var/www/html/monitoring_api/network.php
   /var/www/html/monitoring_api/cctv.php
   /var/www/html/monitoring_api/index.php
   ```

3. **Custom Server Location**:
   - Cek konfigurasi server yang digunakan
   - Cek `phpMyAdmin` untuk lokasi file

---

### **Step 2: Jika File Ditemukan**

**Untuk `network.php` - Perbaiki fungsi `createNetwork()`:**

```php
function createNetwork($conn) {
    try {
        $input = file_get_contents('php://input');
        $data = json_decode($input, true);
        
        // Validate required fields
        if (!isset($data['tower_id']) || !isset($data['location']) || 
            !isset($data['ip_address']) || !isset($data['container_yard'])) {
            throw new Exception('Required fields: tower_id, location, ip_address, container_yard');
        }
        
        // ✅ PENTING: Ambil ip_address dari request
        $towerId = $data['tower_id'];
        $location = $data['location'];
        $ipAddress = $data['ip_address'];  // <-- JANGAN HARDCODED!
        $containerYard = $data['container_yard'];
        $status = isset($data['status']) ? $data['status'] : 'UP';
        $deviceCount = isset($data['device_count']) ? (int)$data['device_count'] : 0;
        $traffic = isset($data['traffic']) ? $data['traffic'] : '0 Mbps';
        $uptime = isset($data['uptime']) ? $data['uptime'] : '0%';
        
        // Insert dengan parameter yang benar
        $stmt = $conn->prepare("INSERT INTO towers 
            (tower_id, location, ip_address, status, container_yard, 
             device_count, traffic, uptime, created_at, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())");
        
        if (!$stmt) {
            throw new Exception($conn->error);
        }
        
        // Pastikan $ipAddress dipass ke bind_param
        $stmt->bind_param("sssissss", 
            $towerId, $location, $ipAddress, $status, $containerYard,
            $deviceCount, $traffic, $uptime);
        
        if ($stmt->execute()) {
            $newId = $conn->insert_id;
            echo json_encode([
                'success' => true,
                'message' => 'Tower created successfully',
                'data' => [
                    'id' => $newId,
                    'tower_id' => $towerId,
                    'ip_address' => $ipAddress,  // Return yang diterima
                    'status' => $status
                ]
            ]);
        } else {
            throw new Exception($stmt->error);
        }
        $stmt->close();
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
}
```

**Untuk `cctv.php` - Perbaiki fungsi `createCamera()`:**

Sama seperti template `network.php`, ganti dengan nama field yang sesuai:
- `tower_id` → `camera_id`
- `towers` → `cameras`

---

### **Step 3: Jika File Tidak Ada / Perlu Dibuat**

**Buat file `network.php`:**

```php
<?php
/**
 * NETWORK/TOWER ENDPOINTS
 * File: network.php
 * Path: monitoring_api/network.php
 */

// Database connection
if (!isset($conn)) {
    $host = 'localhost';
    $username = 'root';
    $password = '';
    $database = 'monitoring';
    
    $conn = new mysqli($host, $username, $password, $database);
    
    if ($conn->connect_error) {
        die(json_encode([
            'success' => false,
            'message' => 'Database connection failed: ' . $conn->connect_error
        ]));
    }
}

header('Content-Type: application/json');

$endpoint = isset($_GET['endpoint']) ? $_GET['endpoint'] : '';
$action = isset($_GET['action']) ? $_GET['action'] : '';

if ($endpoint !== 'network') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid endpoint']);
    exit;
}

switch ($action) {
    case 'all':
        getAllTowers($conn);
        break;
    case 'create':
        createNetwork($conn);
        break;
    // ... actions lainnya
    default:
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
        break;
}

function createNetwork($conn) {
    try {
        $input = file_get_contents('php://input');
        $data = json_decode($input, true);
        
        if (!isset($data['tower_id']) || !isset($data['location']) || 
            !isset($data['ip_address']) || !isset($data['container_yard'])) {
            throw new Exception('Required fields: tower_id, location, ip_address, container_yard');
        }
        
        $towerId = $data['tower_id'];
        $location = $data['location'];
        $ipAddress = $data['ip_address'];  // ✅ Ambil dari request
        $containerYard = $data['container_yard'];
        $status = isset($data['status']) ? $data['status'] : 'UP';
        $deviceCount = isset($data['device_count']) ? (int)$data['device_count'] : 0;
        $traffic = isset($data['traffic']) ? $data['traffic'] : '0 Mbps';
        $uptime = isset($data['uptime']) ? $data['uptime'] : '0%';
        
        $stmt = $conn->prepare("INSERT INTO towers 
            (tower_id, location, ip_address, status, container_yard, device_count, traffic, uptime, created_at, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())");
        
        if (!$stmt) {
            throw new Exception($conn->error);
        }
        
        $stmt->bind_param("sssissss", 
            $towerId, $location, $ipAddress, $status, $containerYard, $deviceCount, $traffic, $uptime);
        
        if ($stmt->execute()) {
            $newId = $conn->insert_id;
            echo json_encode([
                'success' => true,
                'message' => 'Tower created successfully',
                'data' => [
                    'id' => $newId,
                    'tower_id' => $towerId,
                    'location' => $location,
                    'ip_address' => $ipAddress,  // ✅ Return IP yang disimpan
                    'status' => $status
                ]
            ]);
        } else {
            throw new Exception($stmt->error);
        }
        $stmt->close();
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
    }
}

function getAllTowers($conn) {
    try {
        $sql = "SELECT id, tower_id, location, ip_address, status, container_yard, device_count, traffic, uptime, created_at, updated_at 
                FROM towers ORDER BY tower_id ASC";
        
        $result = $conn->query($sql);
        
        if (!$result) {
            throw new Exception($conn->error);
        }
        
        $towers = [];
        while ($row = $result->fetch_assoc()) {
            $towers[] = $row;
        }
        
        echo json_encode([
            'success' => true,
            'data' => $towers
        ]);
    } catch (Exception $e) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
    }
}
?>
```

---

### **Step 4: Verifikasi Database Column**

Pastikan tabel `towers` dan `cameras` memiliki kolom `ip_address`:

```sql
-- Untuk Tower
ALTER TABLE towers ADD COLUMN ip_address VARCHAR(15) NOT NULL DEFAULT '0.0.0.0' AFTER location;

-- Untuk Camera
ALTER TABLE cameras ADD COLUMN ip_address VARCHAR(15) NOT NULL DEFAULT '0.0.0.0' AFTER location;
```

---

## 📊 TESTING SETELAH FIX

### Test Case 1: Create Tower dengan IP Berbeda

```bash
curl -X POST http://localhost/monitoring_api/network.php?endpoint=network&action=create \
  -H "Content-Type: application/json" \
  -d '{
    "tower_id": "TEST-TOWER-01",
    "location": "Test Location",
    "ip_address": "192.168.1.50",
    "container_yard": "CY1"
  }'
```

**Expected Result**:
```json
{
  "success": true,
  "message": "Tower created successfully",
  "data": {
    "id": 1,
    "tower_id": "TEST-TOWER-01",
    "location": "Test Location",
    "ip_address": "192.168.1.50",  // ✅ HARUS IP yang dikirim, bukan 10.2.71.60
    "status": "UP"
  }
}
```

### Test Case 2: Verifikasi Database

```sql
SELECT * FROM towers WHERE tower_id = 'TEST-TOWER-01';
```

**Expected**: Kolom `ip_address` = `192.168.1.50` ✅

---

## 📝 SUMMARY

| Item | Status | File |
|------|--------|------|
| Frontend mengirim IP benar | ✅ OK | `api_service.dart` |
| Backend MMT menangani IP | ✅ OK | `mmt.php` |
| Backend Network/CCTV | ⚠️ FILE MISSING | `network.php`, `cctv.php` |
| Database column ada (MMT) | ✅ OK | `mmt_schema.sql` |
| Database column (Tower/Camera) | ❓ PERLU CEK | - |
| Hardcoded IP di Frontend | ⚠️ OK (hanya testing) | `api_service.dart:954-982` |

---

## 🎯 NEXT STEPS

1. **URGENT**: Temukan file `network.php` dan `cctv.php` di server lokal
2. **Verifikasi**: Cek apakah IP parameter digunakan dengan benar
3. **Fix**: Gunakan template di atas jika file tidak ada atau ada bug
4. **Test**: Jalankan test case yang disediakan
5. **Monitor**: Pastikan semua device baru memiliki IP yang benar di database

---

**Created**: February 5, 2026  
**Last Updated**: February 5, 2026
