<?php
/**
 * MMT (MINE MANAGEMENT TECHNOLOGY) ENDPOINTS
 * File: mmt.php
 * Path: monitoring_api/mmt.php
 * 
 * Endpoints:
 * - ?endpoint=mmt&action=all - Get all MMTs
 * - ?endpoint=mmt&action=by-yard&container_yard=CY1 - Get MMTs by container yard
 * - ?endpoint=mmt&action=by-id&mmt_id=1 - Get MMT by ID
 * - ?endpoint=mmt&action=stats - Get MMT statistics
 * - ?endpoint=mmt&action=update-status - Update MMT status (POST)
 */

// ==================== DATABASE CONNECTION ====================
// Pastikan sudah di-include dari index.php atau set di sini

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

// Hanya proses jika endpoint adalah 'mmt'
if ($endpoint !== 'mmt') {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid endpoint'
    ]);
    exit;
}

// Routing berdasarkan action
switch ($action) {
    case 'all':
        getAllMMTs($conn);
        break;
    
    case 'by-yard':
        $containerYard = isset($_GET['container_yard']) ? $_GET['container_yard'] : '';
        getMMTsByContainerYard($conn, $containerYard);
        break;
    
    case 'by-id':
        $mmtId = isset($_GET['mmt_id']) ? $_GET['mmt_id'] : 0;
        getMMTById($conn, $mmtId);
        break;
    
    case 'stats':
        getMMTStats($conn);
        break;
    
    case 'create':
        createMMT($conn);
        break;
    
    case 'update-status':
        updateMMTStatus($conn);
        break;
    
    default:
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid action'
        ]);
        break;
}

// ==================== HANDLER FUNCTIONS ====================

/**
 * Get all MMTs from database
 */
function getAllMMTs($conn) {
    try {
        $sql = "SELECT 
                    id,
                    mmt_id,
                    location,
                    ip_address,
                    status,
                    type,
                    container_yard,
                    created_at,
                    updated_at
                FROM mmts
                ORDER BY mmt_id ASC";
        
        $result = $conn->query($sql);
        
        if (!$result) {
            throw new Exception($conn->error);
        }
        
        $data = [];
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
        
        echo json_encode([
            'success' => true,
            'data' => $data,
            'count' => count($data)
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
}

/**
 * Get MMTs by Container Yard
 */
function getMMTsByContainerYard($conn, $containerYard) {
    try {
        if (empty($containerYard)) {
            throw new Exception('Container yard is required');
        }
        
        $stmt = $conn->prepare("SELECT 
                                    id,
                                    mmt_id,
                                    location,
                                    ip_address,
                                    status,
                                    type,
                                    container_yard,
                                    created_at,
                                    updated_at
                                FROM mmts
                                WHERE container_yard = ?
                                ORDER BY mmt_id ASC");
        
        if (!$stmt) {
            throw new Exception($conn->error);
        }
        
        $stmt->bind_param("s", $containerYard);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $data = [];
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
        
        echo json_encode([
            'success' => true,
            'data' => $data,
            'count' => count($data),
            'container_yard' => $containerYard
        ]);
        
        $stmt->close();
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
}

/**
 * Get MMT by ID
 */
function getMMTById($conn, $mmtId) {
    try {
        if (empty($mmtId)) {
            throw new Exception('MMT ID is required');
        }
        
        $stmt = $conn->prepare("SELECT 
                                    id,
                                    mmt_id,
                                    location,
                                    ip_address,
                                    status,
                                    type,
                                    container_yard,
                                    created_at,
                                    updated_at
                                FROM mmts
                                WHERE id = ?
                                LIMIT 1");
        
        if (!$stmt) {
            throw new Exception($conn->error);
        }
        
        $stmt->bind_param("i", $mmtId);
        $stmt->execute();
        $result = $stmt->get_result();
        $data = $result->fetch_assoc();
        
        if ($data) {
            echo json_encode([
                'success' => true,
                'data' => $data
            ]);
        } else {
            throw new Exception('MMT not found');
        }
        
        $stmt->close();
    } catch (Exception $e) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
}

/**
 * Get MMT Statistics
 */
function getMMTStats($conn) {
    try {
        $stats = [
            'total' => 0,
            'up' => 0,
            'down' => 0,
            'by_container_yard' => []
        ];
        
        // Total count
        $result = $conn->query("SELECT COUNT(*) as total FROM mmts");
        if ($result) {
            $row = $result->fetch_assoc();
            $stats['total'] = (int)$row['total'];
        }
        
        // Count by status
        $result = $conn->query("SELECT status, COUNT(*) as count FROM mmts GROUP BY status");
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                if ($row['status'] === 'UP') {
                    $stats['up'] = (int)$row['count'];
                } else if ($row['status'] === 'DOWN') {
                    $stats['down'] = (int)$row['count'];
                }
            }
        }
        
        // Count by container yard
        $result = $conn->query("SELECT container_yard, COUNT(*) as count FROM mmts GROUP BY container_yard");
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $stats['by_container_yard'][$row['container_yard']] = (int)$row['count'];
            }
        }
        
        echo json_encode([
            'success' => true,
            'data' => $stats
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
}

/**
 * Create new MMT (POST)
 */
function createMMT($conn) {
    try {
        $input = file_get_contents('php://input');
        $data = json_decode($input, true);
        
        // Validate required fields
        if (!isset($data['mmt_id']) || !isset($data['location']) || 
            !isset($data['ip_address']) || !isset($data['container_yard'])) {
            throw new Exception('Required fields: mmt_id, location, ip_address, container_yard');
        }
        
        $mmtId = $data['mmt_id'];
        $location = $data['location'];
        $ipAddress = $data['ip_address'];
        $containerYard = $data['container_yard'];
        $status = isset($data['status']) ? $data['status'] : 'UP';
        $type = isset($data['type']) ? $data['type'] : 'Mine Monitor';
        $deviceCount = isset($data['device_count']) ? (int)$data['device_count'] : 0;
        $traffic = isset($data['traffic']) ? $data['traffic'] : '0 Mbps';
        $uptime = isset($data['uptime']) ? $data['uptime'] : '0%';
        
        // Extract mmt_number from mmt_id (e.g., "MMT-CY1-01" -> 1)
        $mmtNumber = null;
        if (preg_match('/-(\d+)$/', $mmtId, $matches)) {
            $mmtNumber = (int)$matches[1];
        }
        
        // Check if mmt_id already exists
        $checkStmt = $conn->prepare("SELECT id FROM mmts WHERE mmt_id = ?");
        $checkStmt->bind_param("s", $mmtId);
        $checkStmt->execute();
        $checkResult = $checkStmt->get_result();
        
        if ($checkResult->num_rows > 0) {
            throw new Exception('MMT ID already exists');
        }
        $checkStmt->close();
        
        // Insert new MMT
        $stmt = $conn->prepare("INSERT INTO mmts 
            (mmt_id, mmt_number, location, ip_address, status, type, container_yard, 
             device_count, traffic, uptime, created_at, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())");
        
        if (!$stmt) {
            throw new Exception($conn->error);
        }
        
        $stmt->bind_param("sissssiss", 
            $mmtId, $mmtNumber, $location, $ipAddress, $status, 
            $type, $containerYard, $deviceCount, $traffic, $uptime);
        
        if ($stmt->execute()) {
            $newId = $conn->insert_id;
            
            echo json_encode([
                'success' => true,
                'message' => 'MMT created successfully',
                'data' => [
                    'id' => $newId,
                    'mmt_id' => $mmtId,
                    'location' => $location,
                    'ip_address' => $ipAddress,
                    'container_yard' => $containerYard,
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

/**
 * Update MMT Status (POST)
 */
function updateMMTStatus($conn) {
    try {
        $input = file_get_contents('php://input');
        $data = json_decode($input, true);
        
        if (!isset($data['mmt_id']) || !isset($data['status'])) {
            throw new Exception('mmt_id and status are required');
        }
        
        $mmtId = $data['mmt_id'];
        $status = $data['status'];
        
        // Validate status
        $validStatus = ['UP', 'DOWN', 'Unknown'];
        if (!in_array($status, $validStatus)) {
            throw new Exception('Invalid status. Must be: UP, DOWN, or Unknown');
        }
        
        $stmt = $conn->prepare("UPDATE mmts SET status = ?, updated_at = NOW() WHERE mmt_id = ?");
        
        if (!$stmt) {
            throw new Exception($conn->error);
        }
        
        $stmt->bind_param("ss", $status, $mmtId);
        
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode([
                    'success' => true,
                    'message' => 'MMT status updated successfully',
                    'mmt_id' => $mmtId,
                    'new_status' => $status
                ]);
            } else {
                throw new Exception('MMT not found or status unchanged');
            }
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

// Close connection
$conn->close();
?>
