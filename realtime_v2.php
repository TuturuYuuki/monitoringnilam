<?php
/**
 * REALTIME PING CHECK - CLEAN VERSION
 */

// Ensure connection is global
global $conn;

// Get all IPs
$allIps = [];

$rows = $conn->query("SELECT DISTINCT ip_address FROM towers WHERE ip_address != '' UNION SELECT DISTINCT ip_address FROM cameras WHERE ip_address != '' UNION SELECT DISTINCT ip_address FROM mmts WHERE ip_address != ''");

if ($rows) {
    while ($row = $rows->fetch_assoc()) {
        if (!empty($row['ip_address'])) {
            $allIps[] = $row['ip_address'];
        }
    }
}

$serverSubnets = getServerNetworkSubnets();
$results = [];
$ports = [80, 443, 8080, 22, 3306, 5432, 8000, 8888];

foreach ($allIps as $ip) {
    $status = 'DOWN';
    $reason = '';
    
    // Check subnet first
    if (isInSameSubnet($ip, $serverSubnets)) {
        $status = 'UP';
        $reason = 'same_subnet';
    } else {
        // Try ports
        foreach ($ports as $port) {
            if (@fsockopen($ip, $port, $errno, $errstr, 2)) {
                $status = 'UP';
                $reason = 'port_' . $port;
                break;
            }
        }
        
        // Try PING
        if ($status === 'DOWN' && strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
            $out = @shell_exec("ping -n 1 -w 1000 $ip 2>&1");
            if (strpos($out, 'Reply') !== false) {
                $status = 'UP';
                $reason = 'ping';
            }
        }
    }
    
    $results[$ip] = ['status' => $status, 'reason' => $reason];
}

// Update DB
foreach ($results as $ip => $result) {
    $st = $result['status'];
    $conn->query("UPDATE towers SET status='$st' WHERE ip_address='$ip'");
    $conn->query("UPDATE cameras SET status='$st' WHERE ip_address='$ip'");
    $conn->query("UPDATE mmts SET status='$st' WHERE ip_address='$ip'");
}

echo json_encode([
    'success' => true,
    'message' => 'Ping check done',
    'ips_checked' => count($allIps),
    'results' => $results
]);

?>
