<?php
/**
 * CCTV / CAMERA ENDPOINTS
 * File: cctv.php
 * Path: monitoring_api/cctv.php
 * 
 * Endpoints:
 * - ?endpoint=cctv&action=all - Get all cameras
 * - ?endpoint=cctv&action=by-yard&container_yard=CY1 - Get cameras by container yard
 * - ?endpoint=cctv&action=by-id&camera_id=1 - Get camera by ID
 * - ?endpoint=cctv&action=stats - Get camera statistics
 * - ?endpoint=cctv&action=create - Create new camera (POST)
 * - ?endpoint=cctv&action=update-status - Update camera status (POST)
 */

// ==================== DATABASE CONNECTION ====================
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

// Set header JSON
header('Content-Type: application/json');

// ==================== ROUTING ====================

$endpoint = isset($_GET['endpoint']) ? $_GET['endpoint'] : '';
$action = isset($_GET['action']) ? $_GET['action'] : '';

// Hanya proses jika endpoint adalah 'cctv'
if ($endpoint !== 'cctv') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid endpoint'
    ]);
    exit;
}

try {
    switch ($action) {
        case 'all':
            getAllCameras();
            break;
        case 'by-yard':
            getCamerasByContainerYard();
            break;
        case 'by-id':
            getCameraById();
            break;
        case 'stats':
            getCameraStats();
            break;
        case 'create':
            createCamera();
            break;
        case 'update-status':
            updateCameraStatus();
            break;
        default:
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Invalid action'
            ]);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

// ==================== FUNCTIONS ====================

function getAllCameras() {
    global $conn;

    $sql = "SELECT id, camera_id, location, ip_address, status, 
                   type, area_type, container_yard, created_at, updated_at 
            FROM cameras ORDER BY container_yard, camera_id ASC";
    
    $result = $conn->query($sql);
    
    if ($result->num_rows > 0) {
        $cameras = [];
        while ($row = $result->fetch_assoc()) {
            $cameras[] = $row;
        }
        echo json_encode([
            'success' => true,
            'data' => $cameras
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'data' => []
        ]);
    }
}

function getCamerasByContainerYard() {
    global $conn;

    $containerYard = isset($_GET['container_yard']) ? $_GET['container_yard'] : '';

    if (empty($containerYard)) {
        throw new Exception('container_yard parameter required');
    }

    $sql = "SELECT id, camera_id, location, ip_address, status, 
                   type, area_type, container_yard, created_at, updated_at 
            FROM cameras WHERE container_yard = ? ORDER BY camera_id ASC";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $containerYard);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $cameras = [];
        while ($row = $result->fetch_assoc()) {
            $cameras[] = $row;
        }
        echo json_encode([
            'success' => true,
            'data' => $cameras
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'data' => []
        ]);
    }
    $stmt->close();
}

function getCameraById() {
    global $conn;

    $cameraId = isset($_GET['camera_id']) ? $_GET['camera_id'] : '';

    if (empty($cameraId)) {
        throw new Exception('camera_id parameter required');
    }

    $sql = "SELECT id, camera_id, location, ip_address, status, 
                   type, area_type, container_yard, created_at, updated_at 
            FROM cameras WHERE camera_id = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $cameraId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $camera = $result->fetch_assoc();
        echo json_encode([
            'success' => true,
            'data' => $camera
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Camera not found'
        ]);
    }
    $stmt->close();
}

function getCameraStats() {
    global $conn;

    $sql = "SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'UP' THEN 1 ELSE 0 END) as online,
                SUM(CASE WHEN status = 'DOWN' THEN 1 ELSE 0 END) as offline,
                SUM(CASE WHEN status = 'MAINTENANCE' THEN 1 ELSE 0 END) as maintenance,
                container_yard
            FROM cameras
            GROUP BY container_yard";
    
    $result = $conn->query($sql);
    
    if ($result->num_rows > 0) {
        $stats = [];
        while ($row = $result->fetch_assoc()) {
            $stats[] = $row;
        }
        echo json_encode([
            'success' => true,
            'data' => $stats
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'data' => []
        ]);
    }
}

function createCamera() {
    global $conn;

    $data = json_decode(file_get_contents("php://input"), true);

    // Validate required fields
    if (!isset($data['camera_id']) || !isset($data['location']) || 
        !isset($data['ip_address']) || !isset($data['container_yard'])) {
        throw new Exception('Required fields: camera_id, location, ip_address, container_yard');
    }

    $cameraId = $data['camera_id'];
    $location = $data['location'];
    $ipAddress = $data['ip_address'];  // ✅ GUNAKAN PARAMETER YANG DIKIRIM
    $containerYard = $data['container_yard'];
    $status = $data['status'] ?? 'UP';
    $type = $data['type'] ?? 'Fixed';
    $areaType = $data['area_type'] ?? 'Warehouse';

    $sql = "INSERT INTO cameras (camera_id, location, ip_address, status, 
                                 type, area_type, container_yard, created_at, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())";
    
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Database error: " . $conn->error);
    }

    $stmt->bind_param(
        "sssssss",
        $cameraId,
        $location,
        $ipAddress,
        $status,
        $type,
        $areaType,
        $containerYard
    );


    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Camera created successfully',
            'data' => [
                'id' => $stmt->insert_id,
                'camera_id' => $cameraId,
                'ip_address' => $ipAddress
            ]
        ]);
    } else {
        throw new Exception("Database error: " . $stmt->error);
    }

    $stmt->close();
}

function updateCameraStatus() {
    global $conn;

    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['camera_id']) || !isset($data['status'])) {
        throw new Exception('Required fields: camera_id, status');
    }

    $cameraId = $data['camera_id'];
    $status = $data['status'];

    $sql = "UPDATE cameras SET status = ?, updated_at = NOW() WHERE camera_id = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $status, $cameraId);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Camera status updated successfully'
        ]);
    } else {
        throw new Exception("Database error: " . $stmt->error);
    }

    $stmt->close();
}

?>
