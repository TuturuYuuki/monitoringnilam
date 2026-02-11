<?php
/**
 * DIAGNOSTIC TOOL - Complete System Check
 * Mengecek semua aspek: PHP, MySQL, Tables, Data, API Routes
 */

header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', 1);

$results = [
    'timestamp' => date('Y-m-d H:i:s'),
    'php_version' => phpversion(),
    'checks' => []
];

// =========================
// 1. PHP Configuration Check
// =========================
$results['checks']['php_config'] = [
    'status' => 'OK',
    'version' => phpversion(),
    'extensions' => [
        'mysqli' => extension_loaded('mysqli'),
        'pdo' => extension_loaded('pdo'),
        'pdo_mysql' => extension_loaded('pdo_mysql'),
        'json' => extension_loaded('json'),
    ]
];

// =========================
// 2. Database Connection Check
// =========================
$dbConfig = [
    'host' => 'localhost',
    'user' => 'root',
    'pass' => '',
    'name' => 'monitoring_api'
];

try {
    $conn = new mysqli($dbConfig['host'], $dbConfig['user'], $dbConfig['pass'], $dbConfig['name']);
    
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    $results['checks']['database_connection'] = [
        'status' => 'OK',
        'host' => $dbConfig['host'],
        'database' => $dbConfig['name'],
        'charset' => $conn->character_set_name()
    ];
    
    // =========================
    // 3. Tables Check
    // =========================
    $requiredTables = ['user', 'towers', 'cameras', 'mmts', 'alerts', 'otp_tokens'];
    $existingTables = [];
    
    $tablesResult = $conn->query("SHOW TABLES");
    while ($row = $tablesResult->fetch_array()) {
        $existingTables[] = $row[0];
    }
    
    $missingTables = array_diff($requiredTables, $existingTables);
    
    $results['checks']['tables'] = [
        'status' => empty($missingTables) ? 'OK' : 'ERROR',
        'required' => $requiredTables,
        'existing' => $existingTables,
        'missing' => array_values($missingTables)
    ];
    
    // =========================
    // 4. User Table Structure Check
    // =========================
    if (in_array('user', $existingTables)) {
        $userStructure = $conn->query("DESCRIBE user");
        $userColumns = [];
        while ($row = $userStructure->fetch_assoc()) {
            $userColumns[$row['Field']] = $row['Type'];
        }
        
        $requiredUserColumns = ['user_id', 'username', 'email', 'password', 'role', 'nama'];
        $missingUserColumns = array_diff($requiredUserColumns, array_keys($userColumns));
        
        $results['checks']['user_table_structure'] = [
            'status' => empty($missingUserColumns) ? 'OK' : 'ERROR',
            'columns' => $userColumns,
            'missing_columns' => array_values($missingUserColumns)
        ];
        
        // =========================
        // 5. User Data Check
        // =========================
        $userCountResult = $conn->query("SELECT COUNT(*) as count FROM user");
        $userCount = $userCountResult->fetch_assoc()['count'];
        
        $testUser = $conn->query("SELECT user_id, username, email, role FROM user WHERE user_id = 6");
        $testUserData = $testUser->fetch_assoc();
        
        $results['checks']['user_data'] = [
            'status' => 'OK',
            'total_users' => (int)$userCount,
            'test_user_6' => $testUserData ? $testUserData : 'NOT FOUND'
        ];
        
        // =========================
        // 6. Password Hash Check (User ID 6)
        // =========================
        if ($testUserData) {
            $passwordCheck = $conn->query("SELECT password FROM user WHERE user_id = 6");
            $passwordHash = $passwordCheck->fetch_assoc()['password'];
            
            // Test if password is valid bcrypt hash
            $isBcrypt = (strlen($passwordHash) === 60 && substr($passwordHash, 0, 4) === '$2y$');
            
            // Test password verification with known password
            $testPassword = 'Nilam123';
            $passwordValid = password_verify($testPassword, $passwordHash);
            
            $results['checks']['password_hash'] = [
                'status' => $isBcrypt ? 'OK' : 'ERROR',
                'is_bcrypt' => $isBcrypt,
                'hash_length' => strlen($passwordHash),
                'hash_prefix' => substr($passwordHash, 0, 7),
                'test_password_valid' => $passwordValid,
                'note' => $passwordValid ? 'Password "Nilam123" works' : 'Password mismatch or corrupted'
            ];
        }
    }
    
    // =========================
    // 7. Other Tables Check
    // =========================
    $tableCounts = [];
    foreach (['towers', 'cameras', 'mmts', 'alerts'] as $table) {
        if (in_array($table, $existingTables)) {
            $countResult = $conn->query("SELECT COUNT(*) as count FROM $table");
            $tableCounts[$table] = (int)$countResult->fetch_assoc()['count'];
        }
    }
    
    $results['checks']['data_counts'] = [
        'status' => 'OK',
        'counts' => $tableCounts
    ];
    
    // =========================
    // 8. API Files Check
    // =========================
    $apiFiles = [
        'index.php' => file_exists(__DIR__ . '/index.php'),
        'auth.php' => file_exists(__DIR__ . '/auth.php'),
        'network.php' => file_exists(__DIR__ . '/network.php'),
        'cctv.php' => file_exists(__DIR__ . '/cctv.php'),
        'mmt.php' => file_exists(__DIR__ . '/mmt.php'),
    ];
    
    $missingFiles = array_keys(array_filter($apiFiles, function($exists) {
        return !$exists;
    }));
    
    $results['checks']['api_files'] = [
        'status' => empty($missingFiles) ? 'OK' : 'ERROR',
        'files' => $apiFiles,
        'missing' => $missingFiles
    ];
    
    // =========================
    // 9. Test Change Password Function
    // =========================
    if ($testUserData) {
        // Simulate change password logic
        $userId = 6;
        $oldPassword = 'Nilam123';
        $newPasswordHash = password_hash('TestPassword123', PASSWORD_BCRYPT, ['cost' => 9]);
        
        $results['checks']['change_password_simulation'] = [
            'status' => 'OK',
            'user_id' => $userId,
            'can_generate_hash' => strlen($newPasswordHash) === 60,
            'note' => 'Password hashing works correctly'
        ];
    }
    
    // =========================
    // 10. Overall Status
    // =========================
    $errors = [];
    foreach ($results['checks'] as $checkName => $check) {
        if (isset($check['status']) && $check['status'] === 'ERROR') {
            $errors[] = $checkName;
        }
    }
    
    $results['overall_status'] = empty($errors) ? 'HEALTHY' : 'ERRORS_FOUND';
    $results['errors'] = $errors;
    
    $conn->close();
    
} catch (Exception $e) {
    $results['checks']['database_connection'] = [
        'status' => 'FATAL_ERROR',
        'error' => $e->getMessage()
    ];
    $results['overall_status'] = 'CRITICAL';
}

// Pretty print JSON
echo json_encode($results, JSON_PRETTY_PRINT);
?>
