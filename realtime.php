<?php
/**
 * REALTIME PING CHECK ENDPOINTS
 * File: realtime.php
 * Path: monitoring_api/realtime.php
 */

// Check endpoint
if ($endpoint !== 'realtime') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid endpoint']);
    exit;
}

try {
    switch ($action) {
        case 'all':
            realtimePingAll();
            break;
        default:
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid action']);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

function realtimePingAll() {
    global $conn;

    // Get all unique IPs from towers, cameras, mmts
    $allIps = [];
    
    // From towers
    $result = $conn->query("SELECT DISTINCT ip_address FROM towers WHERE ip_address IS NOT NULL AND ip_address != ''");
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            if (!empty($row['ip_address'])) {
                $allIps[] = $row['ip_address'];
            }
        }
    }
    
    // From cameras
    $result = $conn->query("SELECT DISTINCT ip_address FROM cameras WHERE ip_address IS NOT NULL AND ip_address != ''");
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            if (!empty($row['ip_address'])) {
                $allIps[] = $row['ip_address'];
            }
        }
    }
    
    // From mmts
    $result = $conn->query("SELECT DISTINCT ip_address FROM mmts WHERE ip_address IS NOT NULL AND ip_address != ''");
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            if (!empty($row['ip_address'])) {
                $allIps[] = $row['ip_address'];
            }
        }
    }
    
    // Remove duplicates
    $allIps = array_unique($allIps);
    
    $results = [];
    
    // Ping each IP
    foreach ($allIps as $ip) {
        $status = 'DOWN';
        
        // Try to connect on common ports
        if (@fsockopen($ip, 80, $errno, $errstr, 2) || 
            @fsockopen($ip, 22, $errno, $errstr, 2) || 
            @fsockopen($ip, 3306, $errno, $errstr, 2)) {
            $status = 'UP';
        }
        
        $results[$ip] = $status;
    }
    
    // Update status for towers
    foreach ($results as $ip => $status) {
        $conn->query("UPDATE towers SET status = '$status' WHERE ip_address = '$ip'");
        $conn->query("UPDATE cameras SET status = '$status' WHERE ip_address = '$ip'");
        $conn->query("UPDATE mmts SET status = '$status' WHERE ip_address = '$ip'");
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Realtime ping check completed',
        'ips_checked' => count($allIps),
        'results' => $results
    ]);
}

?>
