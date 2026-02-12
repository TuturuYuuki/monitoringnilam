<?php
// Check if username or email already exists

$conn = new mysqli('localhost', 'root', '', 'monitoring_api');

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$username = 'nilam';
$email = 'ceaa2345';

echo "=== Checking Existing Users ===\n\n";

// Check username
$stmt = $conn->prepare("SELECT id, username, email, fullname, created_at FROM user WHERE username = ?");
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    echo "❌ USERNAME '$username' SUDAH TERDAFTAR:\n";
    while ($row = $result->fetch_assoc()) {
        echo json_encode($row, JSON_PRETTY_PRINT) . "\n";
    }
} else {
    echo "✓ Username '$username' BELUM terdaftar (available)\n";
}

echo "\n";

// Check email
$stmt2 = $conn->prepare("SELECT id, username, email, fullname, created_at FROM user WHERE email = ?");
$stmt2->bind_param("s", $email);
$stmt2->execute();
$result2 = $stmt2->get_result();

if ($result2->num_rows > 0) {
    echo "❌ EMAIL '$email' SUDAH TERDAFTAR:\n";
    while ($row = $result2->fetch_assoc()) {
        echo json_encode($row, JSON_PRETTY_PRINT) . "\n";
    }
} else {
    echo "✓ Email '$email' BELUM terdaftar (available)\n";
}

echo "\n=== Total Users in Database ===\n";
$totalResult = $conn->query("SELECT COUNT(*) as total FROM user");
$total = $totalResult->fetch_assoc()['total'];
echo "Total users: $total\n";

$conn->close();
?>
