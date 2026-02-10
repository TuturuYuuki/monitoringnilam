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
    
    // Get server subnets for comparison
    $serverSubnets = getServerNetworkSubnets();
    
    $results = [];
    $timeout = 2;
    $ports = [80, 443, 8080, 22, 3306, 5432, 8000, 8888, 8443, 9000, 9090];
    
    // Ping each IP
    foreach ($allIps as $ip) {
        $status = 'DOWN';
        $reason = '';
        
        // First check: Same subnet as server? Auto UP
        if (isInSameSubnet($ip, $serverSubnets)) {
            $status = 'UP';
            $reason = 'same_subnet';
        } else {
            // Try port connections
            foreach ($ports as $port) {
                $socket = @fsockopen($ip, $port, $errno, $errstr, $timeout);
                if (is_resource($socket)) {
                    fclose($socket);
                    $status = 'UP';
                    $reason = 'port_' . $port;
                    break;
                }
            }
            
            // Fallback to ICMP PING
            if ($status === 'DOWN') {
                if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
                    $pingOutput = @shell_exec("ping -n 1 -w 1000 $ip");
                    if (strpos($pingOutput, 'Reply from') !== false) {
                        $status = 'UP';
                        $reason = 'icmp_ping';
                    }
                } else {
                    $pingResult = @exec("ping -c 1 -W 2 $ip 2>&1", $output, $code);
                    if ($code === 0) {
                        $status = 'UP';
                        $reason = 'icmp_ping';
                    }
                }
            }
        }
        
        $results[$ip] = ['status' => $status, 'reason' => $reason];
    }
    
    // Update database
    foreach ($results as $ip => $result) {
        $status = $result['status'];
        $conn->query("UPDATE towers SET status = '$status' WHERE ip_address = '$ip'");
        $conn->query("UPDATE cameras SET status = '$status' WHERE ip_address = '$ip'");
        $conn->query("UPDATE mmts SET status = '$status' WHERE ip_address = '$ip'");
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Realtime ping check completed',
        'ips_checked' => count($allIps),
        'server_subnets' => $serverSubnets,
        'results' => $results,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}

?>


?>
