<?php
/**
 * DIAGNOSTIC TEST - Test semua endpoint yang digunakan Flutter
 */

header('Content-Type: application/json');

$results = [
    'timestamp' => date('Y-m-d H:i:s'),
    'tests' => []
];

$baseUrl = 'http://localhost/monitoring_api/index.php';

// Test endpoints yang ada di error log
$endpoints = [
    'realtime&action=all' => 'GET',
    'cctv&action=all' => 'GET',
    'network&action=all' => 'GET',
    'alert&action=all' => 'GET',
    'mmt&action=all' => 'GET',
    'network&action=by-yard&container_yard=CY1' => 'GET',
];

echo "=== TESTING ALL ENDPOINTS ===\n\n";

foreach ($endpoints as $endpoint => $method) {
    $fullUrl = "$baseUrl?endpoint=$endpoint";
    echo "Testing: $endpoint\n";
    echo "Full URL: $fullUrl\n";
    
    try {
        // Use curl untuk test
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $fullUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_TIMEOUT, 5);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);
        
        if ($curlError) {
            echo "❌ CURL Error: $curlError\n";
        } else {
            echo "✓ Status: $httpCode\n";
            if ($httpCode == 200) {
                $json = json_decode($response, true);
                if (is_array($json)) {
                    echo "✓ Response is valid JSON\n";
                    echo "✓ Keys: " . implode(', ', array_keys($json)) . "\n";
                } else {
                    echo "❌ Response is NOT valid JSON\n";
                    echo "Response: " . substr($response, 0, 100) . "...\n";
                }
            } else {
                echo "Response: " . substr($response, 0, 100) . "...\n";
            }
        }
    } catch (Exception $e) {
        echo "❌ Exception: " . $e->getMessage() . "\n";
    }
    
    echo "\n";
}

echo "=== FILE EXISTENCE CHECK ===\n";
$files = [
    'realtime.php',
    'cctv.php',
    'network.php',
    'alerts.php',
    'mmt.php',
];

foreach ($files as $file) {
    $path = __DIR__ . '/' . $file;
    $exists = file_exists($path);
    echo ($exists ? "✓" : "❌") . " $file: " . ($exists ? "EXISTS" : "NOT FOUND") . "\n";
}

echo "\n=== PHP FILES IN DIRECTORY ===\n";
$files = glob(__DIR__ . '/*.php');
foreach ($files as $file) {
    echo "  - " . basename($file) . "\n";
}

?>
