<?php
/**
 * DEVICE PING ENDPOINT
 * File: device-ping.php
 * Path: monitoring_api/device-ping.php
 * 
 * Endpoints:
 * - ?endpoint=device-ping&action=test&ip=192.168.1.1 - Test single IP connectivity
 * - ?endpoint=device-ping&action=report - Report device status (POST)
 */

header('Content-Type: application/json');

// Database connection check
if (!isset($conn)) {
    $host = 'localhost';
    $username = 'root';
    $password = '';
    $database = 'monitoring_api';

    $conn = new mysqli($host, $username, $password, $database);

    if ($conn->connect_error) {
        die(json_encode([
            'success' => false,
            'message' => 'Database connection failed'
        ]));
    }
}

$action = isset($_GET['action']) ? $_GET['action'] : '';

try {
    switch ($action) {
        case 'test':
            $ip = isset($_GET['ip']) ? $_GET['ip'] : '';
            testDeviceConnectivity($ip);
            break;
            
        case 'report':
            reportDeviceStatus();
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

/**
 * Test connectivity to specific IP address
 * Uses multiple connection methods to maximize detection accuracy
 * Auto-detects if IP is in same subnet as server
 */
function testDeviceConnectivity($ip) {
    global $conn;
    
    if (empty($ip) || !filter_var($ip, FILTER_VALIDATE_IP)) {
        echo json_encode([
            'success' => false,
            'message' => 'Invalid IP address',
            'data' => ['status' => 'DOWN']
        ]);
        return;
    }

    $status = 'DOWN';
    $reason = 'unknown';
    $timeout = 2; // Socket timeout in seconds
    $ports = [80, 443, 8080, 22, 3306, 5432, 8000, 8888, 8443, 9000, 9090];
    
    // Get server subnets for comparison
    $serverSubnets = getServerNetworkSubnets();
    
    // First check: Same subnet as server? Auto UP
    if (isInSameSubnet($ip, $serverSubnets)) {
        $status = 'UP';
        $reason = 'same_subnet';
    }
    else {
        // Try common ports for connectivity
        foreach ($ports as $port) {
            $socket = @fsockopen($ip, $port, $errno, $errstr, $timeout);
            if (is_resource($socket)) {
                fclose($socket);
                $status = 'UP';
                $reason = 'port_' . $port;
                break;
            }
        }
        
        // If still DOWN, try PING command as fallback
        if ($status === 'DOWN') {
            if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
                $pingOutput = @shell_exec("ping -n 1 -w 1000 $ip");
                if (strpos($pingOutput, 'Reply from') !== false || strpos($pingOutput, 'bytes=') !== false) {
                    $status = 'UP';
                    $reason = 'icmp_ping_win';
                }
            } else {
                $pingResult = @exec("ping -c 1 -W 2 $ip 2>&1", $output, $returnCode);
                if ($returnCode === 0) {
                    $status = 'UP';
                    $reason = 'icmp_ping_linux';
                }
            }
        }
    }

    echo json_encode([
        'success' => true,
        'message' => 'Connectivity test completed',
        'ip' => $ip,
        'data' => [
            'status' => $status,
            'reason' => $reason,
            'server_subnets' => $serverSubnets,
            'timestamp' => date('Y-m-d H:i:s')
        ]
    ]);
}

/**
 * Report device status and update database
 */
function reportDeviceStatus() {
    global $conn;
    
    // Get JSON from POST body
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid request body'
        ]);
        return;
    }

    $deviceType = $input['type'] ?? '';
    $deviceId = $input['device_id'] ?? '';
    $status = strtoupper($input['status'] ?? 'DOWN');
    $targetIp = $input['target_ip'] ?? '';

    // Validate input
    if (empty($deviceType) || empty($deviceId) || !in_array($status, ['UP', 'DOWN'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Missing or invalid parameters'
        ]);
        return;
    }

    // Map device type to table
    $tableMap = [
        'tower' => 'towers',
        'camera' => 'cameras',
        'mmt' => 'mmts',
        'cctv' => 'cameras',
        'access-point' => 'towers'
    ];

    $table = $tableMap[strtolower($deviceType)] ?? null;

    if (!$table) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid device type'
        ]);
        return;
    }

    // Update device status in database
    $updateQuery = "UPDATE $table SET status = ?, updated_at = NOW() WHERE id = ?";
    
    // Alternative query if column is different
    if ($table === 'mmts') {
        $updateQuery = "UPDATE $table SET status = ?, updated_at = NOW() WHERE id = ? OR mmt_id = ?";
    } elseif ($table === 'cameras') {
        $updateQuery = "UPDATE $table SET status = ?, updated_at = NOW() WHERE id = ? OR camera_id = ?";
    }

    $stmt = $conn->prepare($updateQuery);
    
    if (!$stmt) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $conn->error
        ]);
        return;
    }

    // Bind parameters based on query
    if (strpos($updateQuery, 'OR') !== false) {
        $stmt->bind_param('sss', $status, $deviceId, $deviceId);
    } else {
        $stmt->bind_param('ss', $status, $deviceId);
    }

    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Device status updated successfully',
            'data' => [
                'device_type' => $deviceType,
                'device_id' => $deviceId,
                'status' => $status,
                'affected_rows' => $stmt->affected_rows
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to update device status: ' . $stmt->error
        ]);
    }

    $stmt->close();
}

?>
