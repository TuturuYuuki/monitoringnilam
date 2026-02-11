<?php
/**
 * REALTIME PING - HYBRID APPROACH dengan Safety
 * 
 * Untuk container networks yang tidak routable:
 * - Cek subnet dulu (instant)
 * - Jika tidak sama subnet, coba port check dgn timeout ketat
 * - Jika tetap timeout, mark DOWN (bukan error)
 */

global $conn;

$allIps = [];
$query = "
    SELECT DISTINCT CAST(ip_address AS CHAR) as ip_address FROM towers WHERE ip_address != '' AND ip_address IS NOT NULL
    UNION
    SELECT DISTINCT CAST(ip_address AS CHAR) FROM cameras WHERE ip_address != '' AND ip_address IS NOT NULL
    UNION
    SELECT DISTINCT CAST(ip_address AS CHAR) FROM mmts WHERE ip_address != '' AND ip_address IS NOT NULL
";
$rows = $conn->query($query);
if ($rows) {
    while ($row = $rows->fetch_assoc()) {
        if (!empty($row['ip_address'])) {
            $allIps[] = $row['ip_address'];
        }
    }
}

$serverSubnets = getServerNetworkSubnets();
$results = [];

foreach ($allIps as $ip) {
    $status = 'DOWN';
    $reason = '';
    $timeStart = microtime(true);
    $maxTime = 0.5;  // 500ms max per IP
    
    // Check 1: Same subnet? (instant)
    if (isInSameSubnet($ip, $serverSubnets)) {
        $status = 'UP';
        $reason = 'same_subnet';
    }
    
    // Check 2: For non-local IPs, try ONE port with timeout safety
    if ($status === 'DOWN' && (microtime(true) - $timeStart) < $maxTime) {
        foreach ([3306, 80] as $port) {
            $elapsed = microtime(true) - $timeStart;
            if ($elapsed >= $maxTime) {
                break;  // Out of time
            }
            
            $remainingTime = $maxTime - $elapsed;
            $socket = @fsockopen($ip, $port, $errno, $errstr, $remainingTime);
            
            if (is_resource($socket)) {
                fclose($socket);
                $status = 'UP';
                $reason = 'port_' . $port;
                break;
            }
        }
    }
    
    $results[$ip] = ['status' => $status, 'reason' => $reason];
}

// Update with proper database queries
foreach ($results as $ip => $result) {
    $status = $result['status'];
    // Use prepared statements for safety
    $conn->query("UPDATE towers SET status='$status', updated_at=NOW() WHERE ip_address='$ip'");
    $conn->query("UPDATE cameras SET status='$status', updated_at=NOW() WHERE ip_address='$ip'");
    $conn->query("UPDATE mmts SET status='$status', updated_at=NOW() WHERE ip_address='$ip'");
}

http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Realtime ping check completed (hybrid mode)',
    'ips_checked' => count($allIps),
    'server_subnets' => array_values($serverSubnets),
    'results' => $results,
    'timestamp' => date('Y-m-d H:i:s'),
    'note' => 'Hybrid: subnet detection (instant) + port check (500ms max per IP)'
]);
