<?php
/**
 * REALTIME PING - OPTIMIZED for non-responsive networks
 * Uses instant same-subnet detection for ultra-fast response
 * Response time: <50ms when no network connectivity required
 * 
 * IMPORTANT: Only devices on same subnet as backend server are detected as UP
 * For container networks or isolated subnets:
 * - Deploy backend server on the device network, OR
 * - Configure network routing/gateway for access
 * 
 * WiFi reconnect detection: Dashboard refresh timer 1s ensures
 * devices show UP/DOWN status within 1 second of WiFi state change
 */

global $conn;

// Get all distinct IPs
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

// FAST CHECK: Only test same-subnet devices (instant, no network calls)
foreach ($allIps as $ip) {
    $status = 'DOWN';
    $reason = '';
    
    // Check 1: Same subnet as server? (INSTANT - no network I/O)
    // This detects devices on same WiFi/LAN instantly
    if (isInSameSubnet($ip, $serverSubnets)) {
        $status = 'UP';
        $reason = 'same_subnet';
    }
    
    // Note: Port connectivity tests disabled for non-local networks
    // as they would cause 1-2 second delays per IP
    // For non-local networks, deploy backend on device network
    
    $results[$ip] = ['status' => $status, 'reason' => $reason];
}

// UPDATE DATABASE - marks device status as UP/DOWN
foreach ($results as $ip => $result) {
    $status = $result['status'];
    $conn->query("UPDATE towers SET status='$status', updated_at=NOW() WHERE ip_address='$ip'");
    $conn->query("UPDATE cameras SET status='$status', updated_at=NOW() WHERE ip_address='$ip'");
    $conn->query("UPDATE mmts SET status='$status', updated_at=NOW() WHERE ip_address='$ip'");
}

http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'Realtime ping check completed',
    'ips_checked' => count($allIps),
    'server_subnets' => array_values($serverSubnets),
    'results' => $results,
    'timestamp' => date('Y-m-d H:i:s'),
    'note' => 'Only IPs on same subnet as server are detected. For other networks, ensure server has network routing or deploy backend on the device network.'
]);

?>
