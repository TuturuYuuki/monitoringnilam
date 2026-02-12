<?php
/**
 * Check and Delete Device from Database
 * Target: MMT 10 (ID 11) - Tower 1 CY2
 */

$conn = new mysqli('localhost', 'root', '', 'monitoring_api');

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

echo "=== Checking Device Data Before Delete ===\n\n";

// Check MMT with ID 11
$checkMMT = $conn->query("SELECT * FROM mmts WHERE id = 11");

if ($checkMMT && $checkMMT->num_rows > 0) {
    $mmt = $checkMMT->fetch_assoc();
    echo "Found MMT to delete:\n";
    echo json_encode($mmt, JSON_PRETTY_PRINT) . "\n\n";
    
    // Delete confirmation
    echo "=== Deleting MMT ID 11 ===\n";
    $deleteResult = $conn->query("DELETE FROM mmts WHERE id = 11");
    
    if ($deleteResult) {
        echo "✓ Successfully deleted MMT ID 11\n";
        echo "Rows affected: " . $conn->affected_rows . "\n\n";
        
        // Verify deletion
        $verify = $conn->query("SELECT * FROM mmts WHERE id = 11");
        if ($verify->num_rows == 0) {
            echo "✓ Verified: MMT ID 11 no longer exists in database\n";
        } else {
            echo "⚠ Warning: MMT ID 11 still exists after delete\n";
        }
    } else {
        echo "❌ Delete failed: " . $conn->error . "\n";
    }
} else {
    echo "MMT with ID 11 not found in database\n";
    
    // Check if it's a tower instead
    echo "\nChecking towers table...\n";
    $checkTower = $conn->query("SELECT * FROM towers WHERE tower_id = 'Tower 1 - CY2' OR id = 11");
    if ($checkTower && $checkTower->num_rows > 0) {
        while ($tower = $checkTower->fetch_assoc()) {
            echo "Found Tower:\n";
            echo json_encode($tower, JSON_PRETTY_PRINT) . "\n";
        }
    }
}

echo "\n=== Current MMTs Count ===\n";
$countResult = $conn->query("SELECT COUNT(*) as total FROM mmts");
$count = $countResult->fetch_assoc()['total'];
echo "Total MMTs in database: $count\n";

$conn->close();
?>
