<?php
/**
 * MONITORING API - Main Router
 * File: index.php
 * Path: monitoring_api/index.php
 * 
 * Main routing file that handles all API endpoints
 */

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Handle OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ==================== DATABASE CONNECTION ====================
$host = 'localhost';
$username = 'root';
$password = '';
$database = 'monitoring_api';

$conn = new mysqli($host, $username, $password, $database);

if ($conn->connect_error) {
    die(json_encode([
        'success' => false,
        'message' => 'Database connection failed: ' . $conn->connect_error
    ]));
}

$conn->set_charset("utf8");

// ==================== SHARED HELPER FUNCTIONS ====================
/**
 * Get server's local network subnets
 * Returns array of /24 subnets (first 3 octets)
 */
function getServerNetworkSubnets() {
    $subnets = [];
    
    // Get local addresses
    $hostName = @gethostname();
    $hostIp = @gethostbyname($hostName);
    
    if ($hostIp && $hostIp !== $hostName) {
        $subnets[] = getSubnetFromIp($hostIp);
    }
    
    // Also get localhost network
    $subnets[] = "127.0.0"; // localhost subnet
    
    // Common private network subnets
    $subnets[] = "192.168.0";
    $subnets[] = "192.168.1";
    $subnets[] = "10.0.0";
    $subnets[] = "10.0.1";
    $subnets[] = "172.16.0";
    
    return array_unique($subnets);
}

/**
 * Extract /24 subnet from IP (first 3 octets)
 * Example: 192.168.1.100 -> 192.168.1
 */
function getSubnetFromIp($ip) {
    $parts = explode('.', $ip);
    if (count($parts) === 4) {
        return implode('.', array_slice($parts, 0, 3));
    }
    return $ip;
}

/**
 * Check if IP is in same subnet as server
 */
function isInSameSubnet($ip, $serverSubnets) {
    if (!is_array($serverSubnets)) {
        $serverSubnets = [$serverSubnets];
    }
    
    $ipSubnet = getSubnetFromIp($ip);
    
    foreach ($serverSubnets as $serverSubnet) {
        if ($ipSubnet === $serverSubnet) {
            return true;
        }
    }
    
    return false;
}

// ==================== ENDPOINT ROUTING ====================

$endpoint = isset($_GET['endpoint']) ? $_GET['endpoint'] : '';
$action = isset($_GET['action']) ? $_GET['action'] : '';

try {
    // Route ke file yang sesuai berdasarkan endpoint
    switch ($endpoint) {
        case 'auth':
            if (file_exists('auth.php')) {
                require 'auth.php';
            } else {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => 'Auth endpoint not available']);
            }
            break;
            
        case 'network':
            if (file_exists('network.php')) {
                require 'network.php';
            } else {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => 'Network PHP file not found']);
            }
            break;
            
        case 'cctv':
            if (file_exists('cctv.php')) {
                require 'cctv.php';
            } else {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => 'CCTV PHP file not found']);
            }
            break;
            
        case 'mmt':
            if (file_exists('mmt.php')) {
                require 'mmt.php';
            } else {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => 'MMT PHP file not found']);
            }
            break;
            
        case 'realtime':
            if (file_exists('realtime.php')) {
                require 'realtime.php';
            } else {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => 'Realtime PHP file not found']);
            }
            break;
            
        case 'alerts':
            if (file_exists('alerts.php')) {
                require 'alerts.php';
            } else {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => 'Alerts PHP file not found']);
            }
            break;
            
        case 'device-ping':
            if (file_exists('device-ping.php')) {
                require 'device-ping.php';
            } else {
                http_response_code(404);
                echo json_encode(['success' => false, 'message' => 'Device Ping PHP file not found']);
            }
            break;
            
        default:
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Invalid endpoint: ' . $endpoint,
                'available_endpoints' => [
                    'auth' => 'Authentication endpoints',
                    'network' => 'Network/Tower endpoints',
                    'cctv' => 'CCTV/Camera endpoints',
                    'mmt' => 'MMT endpoints',
                    'realtime' => 'Realtime status check',
                    'alerts' => 'Alert management'
                ]
            ]);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage(),
        'endpoint' => $endpoint,
        'action' => $action
    ]);
}

// Don't close connection here - let PHP handle it automatically
// Each endpoint may be using it after require()
?>
