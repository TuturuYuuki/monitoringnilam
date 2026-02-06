<?php
/**
 * ALERTS ENDPOINTS
 * File: alerts.php
 * Path: monitoring_api/alerts.php
 */

// Check endpoint
if ($endpoint !== 'alerts') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid endpoint']);
    exit;
}

try {
    switch ($action) {
        case 'all':
            getAllAlerts();
            break;
        case 'critical':
            getCriticalAlerts();
            break;
        case 'by-category':
            getAlertsByCategory();
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

function getAllAlerts() {
    global $conn;

    $sql = "SELECT id, title, description, severity, timestamp, route, category 
            FROM alerts 
            ORDER BY timestamp DESC 
            LIMIT 100";
    
    $result = $conn->query($sql);
    
    if ($result) {
        $alerts = [];
        while ($row = $result->fetch_assoc()) {
            $alerts[] = $row;
        }
        echo json_encode([
            'success' => true,
            'data' => $alerts
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Query error: ' . $conn->error
        ]);
    }
}

function getCriticalAlerts() {
    global $conn;

    $sql = "SELECT id, title, description, severity, timestamp, route, category 
            FROM alerts 
            WHERE severity IN ('critical', 'warning')
            ORDER BY 
                CASE WHEN severity = 'critical' THEN 1 
                     ELSE 2 
                END,
                timestamp DESC 
            LIMIT 50";
    
    $result = $conn->query($sql);
    
    if ($result) {
        $alerts = [];
        while ($row = $result->fetch_assoc()) {
            $alerts[] = $row;
        }
        echo json_encode([
            'success' => true,
            'data' => $alerts,
            'count' => count($alerts)
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Query error: ' . $conn->error
        ]);
    }
}

function getAlertsByCategory() {
    global $conn;

    $category = isset($_GET['category']) ? $_GET['category'] : '';

    if (empty($category)) {
        echo json_encode(['success' => false, 'message' => 'category parameter required']);
        return;
    }

    $sql = "SELECT id, title, description, severity, timestamp, route, category 
            FROM alerts 
            WHERE category = ?
            ORDER BY timestamp DESC 
            LIMIT 50";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $category);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result) {
        $alerts = [];
        while ($row = $result->fetch_assoc()) {
            $alerts[] = $row;
        }
        echo json_encode([
            'success' => true,
            'data' => $alerts,
            'category' => $category
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Query error: ' . $conn->error
        ]);
    }
    
    $stmt->close();
}

?>
