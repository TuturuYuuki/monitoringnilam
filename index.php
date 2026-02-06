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
