<?php
/**
 * NETWORK / ACCESS POINT ENDPOINTS
 * File: network.php
 * Path: monitoring_api/network.php
 * 
 * Endpoints:
 * - ?endpoint=network&action=all - Get all towers
 * - ?endpoint=network&action=by-yard&container_yard=CY1 - Get towers by container yard
 * - ?endpoint=network&action=by-id&tower_id=1 - Get tower by ID
 * - ?endpoint=network&action=stats - Get network statistics
 * - ?endpoint=network&action=create - Create new tower (POST)
 * - ?endpoint=network&action=update-status - Update tower status (POST)
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

// Hanya proses jika endpoint adalah 'network'
if ($endpoint !== 'network') {
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
            getAllTowers();
            break;
        case 'by-yard':
            getTowersByContainerYard();
            break;
        case 'by-id':
            getTowerById();
            break;
        case 'stats':
            getTowerStats();
            break;
        case 'create':
            createTower();
            break;
        case 'update-status':
            updateTowerStatus();
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

function getAllTowers() {
    global $conn;

    $sql = "SELECT id, tower_id, tower_number, location, ip_address, status, 
                   traffic, uptime, device_count, container_yard, created_at, updated_at 
            FROM towers ORDER BY container_yard, tower_number ASC";
    
    $result = $conn->query($sql);
    
    if ($result->num_rows > 0) {
        $towers = [];
        while ($row = $result->fetch_assoc()) {
            $towers[] = $row;
        }
        echo json_encode([
            'success' => true,
            'data' => $towers
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'data' => []
        ]);
    }
}

function getTowersByContainerYard() {
    global $conn;

    $containerYard = isset($_GET['container_yard']) ? $_GET['container_yard'] : '';

    if (empty($containerYard)) {
        throw new Exception('container_yard parameter required');
    }

    $sql = "SELECT id, tower_id, tower_number, location, ip_address, status, 
                   traffic, uptime, device_count, container_yard, created_at, updated_at 
            FROM towers WHERE container_yard = ? ORDER BY tower_number ASC";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $containerYard);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $towers = [];
        while ($row = $result->fetch_assoc()) {
            $towers[] = $row;
        }
        echo json_encode([
            'success' => true,
            'data' => $towers
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'data' => []
        ]);
    }
    $stmt->close();
}

function getTowerById() {
    global $conn;

    $towerId = isset($_GET['tower_id']) ? $_GET['tower_id'] : '';

    if (empty($towerId)) {
        throw new Exception('tower_id parameter required');
    }

    $sql = "SELECT id, tower_id, tower_number, location, ip_address, status, 
                   traffic, uptime, device_count, container_yard, created_at, updated_at 
            FROM towers WHERE tower_id = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $towerId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $tower = $result->fetch_assoc();
        echo json_encode([
            'success' => true,
            'data' => $tower
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Tower not found'
        ]);
    }
    $stmt->close();
}

function getTowerStats() {
    global $conn;

    $sql = "SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'UP' THEN 1 ELSE 0 END) as online,
                SUM(CASE WHEN status = 'DOWN' THEN 1 ELSE 0 END) as offline,
                SUM(CASE WHEN status = 'MAINTENANCE' THEN 1 ELSE 0 END) as maintenance,
                container_yard
            FROM towers
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

function createTower() {
    global $conn;

    $data = json_decode(file_get_contents("php://input"), true);

    // Validate required fields
    if (!isset($data['tower_id']) || !isset($data['location']) || 
        !isset($data['ip_address']) || !isset($data['container_yard'])) {
        throw new Exception('Required fields: tower_id, location, ip_address, container_yard');
    }

    $towerId = $data['tower_id'];
    $location = $data['location'];
    $ipAddress = $data['ip_address'];  // ✅ GUNAKAN PARAMETER YANG DIKIRIM
    $containerYard = $data['container_yard'];
    $deviceCount = $data['device_count'] ?? 1;
    $status = $data['status'] ?? 'UP';
    $traffic = $data['traffic'] ?? '0 Mbps';
    $uptime = $data['uptime'] ?? '0%';

    // Extract tower number from tower_id (e.g., "AP 01" -> 1)
    $towerNumber = intval(str_replace('AP ', '', $towerId));

    $sql = "INSERT INTO towers (tower_id, tower_number, location, ip_address, status, 
                                traffic, uptime, device_count, container_yard, created_at, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())";
    
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Database error: " . $conn->error);
    }

    $stmt->bind_param(
        "sisisssiss",
        $towerId,
        $towerNumber,
        $location,
        $ipAddress,
        $status,
        $traffic,
        $uptime,
        $deviceCount,
        $containerYard
    );


    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Tower created successfully',
            'data' => [
                'id' => $stmt->insert_id,
                'tower_id' => $towerId,
                'ip_address' => $ipAddress
            ]
        ]);
    } else {
        throw new Exception("Database error: " . $stmt->error);
    }

    $stmt->close();
}

function updateTowerStatus() {
    global $conn;

    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['tower_id']) || !isset($data['status'])) {
        throw new Exception('Required fields: tower_id, status');
    }

    $towerId = $data['tower_id'];
    $status = $data['status'];

    $sql = "UPDATE towers SET status = ?, updated_at = NOW() WHERE tower_id = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ss", $status, $towerId);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Tower status updated successfully'
        ]);
    } else {
        throw new Exception("Database error: " . $stmt->error);
    }

    $stmt->close();
}

?>
