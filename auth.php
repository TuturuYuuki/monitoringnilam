<?php
/**
 * Authentication Endpoints
 * Handles user login, logout, and authentication-related operations
 */

header('Content-Type: application/json');

$action = $_GET['action'] ?? $_POST['action'] ?? 'login';

try {
    switch ($action) {
        case 'login':
            handleLogin();
            break;
            
        case 'logout':
            handleLogout();
            break;
            
        case 'check-auth':
            handleCheckAuth();
            break;
            
        case 'register':
            handleRegister();
            break;
            
        case 'verify-otp':
            handleVerifyOtp();
            break;
            
        case 'resend-otp':
            handleResendOtp();
            break;
            
        case 'update-profile':
            handleUpdateProfile();
            break;
            
        case 'request-email-change-otp':
            handleRequestEmailChangeOtp();
            break;
            
        case 'verify-email-change-otp':
            handleVerifyEmailChangeOtp();
            break;
            
        case 'get-latest-otp':
            // For local testing only - remove in production!
            handleGetLatestOtp();
            break;
            
        case 'get-profile':
            handleGetProfile();
            break;
            
        case 'change-password':
            handleChangePassword();
            break;
            
        default:
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Invalid auth action: ' . $action,
                'available_actions' => [
                    'login' => 'User login with email and password',
                    'logout' => 'User logout',
                    'check-auth' => 'Check if user is authenticated',
                    'register' => 'Register new user',
                    'verify-otp' => 'Verify OTP code',
                    'resend-otp' => 'Resend OTP to email',
                    'update-profile' => 'Update user profile',
                    'get-profile' => 'Get user profile from database',
                    'request-email-change-otp' => 'Request OTP for email change',
                    'verify-email-change-otp' => 'Verify OTP and change email'
                ]
            ]);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Auth error: ' . $e->getMessage()
    ]);
}

/**
 * Handle user login
 */
function handleLogin() {
    global $conn;
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Accept either username or email
    $username = $data['username'] ?? null;
    $email = $data['email'] ?? null;
    $password = $data['password'] ?? null;
    
    if (!$password || (!$username && !$email)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Username/email and password required']);
        return;
    }
    
    try {
        // Query untuk mencari user berdasarkan username atau email
        if ($username) {
            $stmt = $conn->prepare("SELECT id, email, username, password, fullname, role FROM user WHERE username = ? LIMIT 1");
            $stmt->bind_param("s", $username);
        } else {
            $stmt = $conn->prepare("SELECT id, email, username, password, fullname, role FROM user WHERE email = ? LIMIT 1");
            $stmt->bind_param("s", $email);
        }
        
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Invalid username/email or password']);
            return;
        }
        
        $user = $result->fetch_assoc();
        
        // Verifikasi password
        if (!password_verify($password, $user['password'])) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Invalid username/email or password']);
            return;
        }
        
        // Login berhasil
        echo json_encode([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'id' => (int)$user['id'],
                'email' => $user['email'],
                'username' => $user['username'],
                'fullname' => $user['fullname'],
                'role' => $user['role']
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

/**
 * Handle user logout
 */
function handleLogout() {
    echo json_encode([
        'success' => true,
        'message' => 'Logout successful'
    ]);
}

/**
 * Check if user is authenticated
 */
function handleCheckAuth() {
    // Implementasi sesuai dengan session handling system Anda
    echo json_encode([
        'success' => true,
        'authenticated' => false,
        'message' => 'Auth check endpoint available'
    ]);
}

/**
 * Handle user registration
 */
function handleRegister() {
    global $conn;
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    $username = $data['username'] ?? null;
    $email = $data['email'] ?? null;
    $password = $data['password'] ?? null;
    $fullname = $data['fullname'] ?? null;
    
    if (!$username || !$email || !$password || !$fullname) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Username, email, password, and fullname required']);
        return;
    }
    
    try {
        // Check if username already exists
        $checkStmt = $conn->prepare("SELECT id FROM user WHERE username = ?");
        $checkStmt->bind_param("s", $username);
        $checkStmt->execute();
        
        if ($checkStmt->get_result()->num_rows > 0) {
            http_response_code(409);
            echo json_encode(['success' => false, 'message' => 'Username already registered']);
            return;
        }
        
        // Check if email already exists
        $checkEmail = $conn->prepare("SELECT id FROM user WHERE email = ?");
        $checkEmail->bind_param("s", $email);
        $checkEmail->execute();
        
        if ($checkEmail->get_result()->num_rows > 0) {
            http_response_code(409);
            echo json_encode(['success' => false, 'message' => 'Email already registered']);
            return;
        }
        
        // Hash password
        $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
        $role = 'user';
        
        // Insert new user
        $stmt = $conn->prepare("INSERT INTO user (username, email, password, fullname, role) VALUES (?, ?, ?, ?, ?)");
        $stmt->bind_param("sssss", $username, $email, $hashedPassword, $fullname, $role);
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Registration successful',
            'user_id' => $conn->insert_id,
            'data' => [
                'id' => $conn->insert_id,
                'username' => $username,
                'email' => $email,
                'fullname' => $fullname,
                'role' => $role
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

/**
 * Handle OTP verification
 */
function handleVerifyOtp() {
    global $conn;
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['email']) || !isset($data['otp'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Email and OTP code required']);
        return;
    }
    
    $email = $data['email'];
    $otp_code = $data['otp'];
    
    try {
        // Query OTP dari database
        $stmt = $conn->prepare("SELECT id, otp_code, created_at FROM otp_tokens WHERE email = ? AND used = 0 ORDER BY created_at DESC LIMIT 1");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'No valid OTP found for this email']);
            return;
        }
        
        $otp_record = $result->fetch_assoc();
        $created_time = strtotime($otp_record['created_at']);
        $current_time = time();
        $time_diff = ($current_time - $created_time) / 60; // in minutes
        
        // Check if OTP expired (15 minutes validity)
        if ($time_diff > 15) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'OTP has expired']);
            return;
        }
        
        // Verify OTP code
        if ($otp_record['otp_code'] !== $otp_code) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Invalid OTP code']);
            return;
        }
        
        // Mark OTP as used
        $updateStmt = $conn->prepare("UPDATE otp_tokens SET used = 1 WHERE id = ?");
        $updateStmt->bind_param("i", $otp_record['id']);
        $updateStmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'OTP verified successfully'
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

/**
 * Handle OTP resend
 */
function handleResendOtp() {
    global $conn;
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['email'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Email required']);
        return;
    }
    
    $email = $data['email'];
    
    try {
        // Generate new OTP
        $otp_code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        
        // Save to database
        $stmt = $conn->prepare("INSERT INTO otp_tokens (email, otp_code, used) VALUES (?, ?, 0)");
        $stmt->bind_param("ss", $email, $otp_code);
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'OTP resent successfully',
            'otp_code' => $otp_code  // In production, only send this via email
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

/**
 * Handle profile update
 */
function handleUpdateProfile() {
    global $conn;
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['user_id'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID required']);
        return;
    }
    
    $userId = (int)$data['user_id'];
    $fullname = $data['fullname'] ?? null;
    $email = $data['email'] ?? null;
    $username = $data['username'] ?? null;
    $phone = $data['phone'] ?? $data['no_telp'] ?? $data['telp'] ?? $data['phone_number'] ?? null;
    $location = $data['location'] ?? $data['lokasi'] ?? $data['address'] ?? null;
    $division = $data['division'] ?? $data['divisi'] ?? null;
    
    try {
        // Build dynamic UPDATE statement
        $updates = [];
        $params = [];
        $types = '';
        
        if ($fullname !== null) {
            $updates[] = 'fullname = ?';
            $params[] = $fullname;
            $types .= 's';
        }
        if ($email !== null) {
            $updates[] = 'email = ?';
            $params[] = $email;
            $types .= 's';
        }
        if ($username !== null) {
            $updates[] = 'username = ?';
            $params[] = $username;
            $types .= 's';
        }
        if ($phone !== null) {
            $updates[] = 'phone = ?';
            $params[] = $phone;
            $types .= 's';
        }
        if ($location !== null) {
            $updates[] = 'location = ?';
            $params[] = $location;
            $types .= 's';
        }
        if ($division !== null) {
            $updates[] = 'division = ?';
            $params[] = $division;
            $types .= 's';
        }
        
        if (empty($updates)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'No fields to update']);
            return;
        }
        
        // Add user_id to params
        $params[] = $userId;
        $types .= 'i';
        
        $sql = 'UPDATE user SET ' . implode(', ', $updates) . ' WHERE id = ?';
        
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            throw new Exception('Prepare failed: ' . $conn->error);
        }
        
        $stmt->bind_param($types, ...$params);
        $stmt->execute();
        
        if ($stmt->affected_rows > 0) {
            echo json_encode([
                'success' => true,
                'message' => 'Profile updated successfully',
                'affected_rows' => $stmt->affected_rows
            ]);
        } else {
            echo json_encode([
                'success' => true,
                'message' => 'No changes made',
                'affected_rows' => 0
            ]);
        }
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

/**
 * Send OTP via email (logs to file for development)
 */
function sendViaSmtp($toEmail, $subject, $message) {
    $config = require(__DIR__ . '/config/email.php');
    
    $smtpHost = $config['smtp_host'];
    $smtpPort = $config['smtp_port'];
    $smtpUser = $config['smtp_user'];
    $smtpPass = $config['smtp_pass'];
    $fromEmail = $config['from_email'];
    $fromName = $config['from_name'];
    
    try {
        // Create socket connection
        $logFile = __DIR__ . '/emails.log';
        // Connect without TLS first (plain TCP)
        $socket = @fsockopen($smtpHost, $smtpPort, $errno, $errstr, 10);
        
        if (!$socket) {
            $logEntry = "[SMTP_ERROR] Socket connection failed: $errstr ($errno) for " . $toEmail . "\n";
            @file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
            error_log("[SMTP] Socket connection failed: $errstr ($errno)");
            return false;
        }
        @file_put_contents($logFile, "[SMTP_DEBUG] Connected to " . $smtpHost . ":" . $smtpPort . " for " . $toEmail . "\n", FILE_APPEND | LOCK_EX);
        
        // Set connection to non-blocking to prevent timeout
        stream_set_blocking($socket, true);
        stream_set_timeout($socket, 10);
        
        $readResponse = function ($label) use ($socket, $logFile) {
            $lines = [];
            while (($line = fgets($socket, 1024)) !== false) {
                $lineTrim = trim($line);
                $lines[] = $lineTrim;
                @file_put_contents($logFile, "[SMTP_DEBUG] " . $label . ": " . $lineTrim . "\n", FILE_APPEND | LOCK_EX);
                if (preg_match('/^\d{3} /', $lineTrim)) {
                    break;
                }
            }
            return $lines;
        };

        $readResponse('SERVER');

        // Send EHLO
        fwrite($socket, "EHLO localhost\r\n");
        $readResponse('EHLO');

        // Start TLS
        fwrite($socket, "STARTTLS\r\n");
        $starttlsLines = $readResponse('STARTTLS');
        $starttlsLast = end($starttlsLines) ?: '';
        if (strpos($starttlsLast, '220') !== 0) {
            $logEntry = "[SMTP_ERROR] STARTTLS failed: " . $starttlsLast . " for " . $toEmail . "\n";
            @file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
            fclose($socket);
            return false;
        }

        // Enable encryption
        $cryptoMethod = defined('STREAM_CRYPTO_METHOD_TLS_CLIENT')
            ? STREAM_CRYPTO_METHOD_TLS_CLIENT
            : STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT;
        $cryptoOk = stream_socket_enable_crypto($socket, true, $cryptoMethod);
        if (!$cryptoOk) {
            $logEntry = "[SMTP_ERROR] TLS negotiation failed for " . $toEmail . "\n";
            @file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
            fclose($socket);
            return false;
        }

        // Send EHLO again after TLS
        fwrite($socket, "EHLO localhost\r\n");
        $readResponse('EHLO TLS');

        // Authenticate
        fwrite($socket, "AUTH LOGIN\r\n");
        $readResponse('AUTH LOGIN');

        // Send username (base64 encoded)
        fwrite($socket, base64_encode($smtpUser) . "\r\n");
        $readResponse('AUTH USER');

        // Send password (base64 encoded)
        fwrite($socket, base64_encode($smtpPass) . "\r\n");
        $passLines = $readResponse('AUTH PASS');
        $passLast = end($passLines) ?: '';
        if (strpos($passLast, '235') !== 0) {
            $logEntry = "[SMTP_ERROR] Authentication failed: " . $passLast . " for " . $toEmail . "\n";
            @file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
            fclose($socket);
            return false;
        }

        // Send MAIL FROM
        fwrite($socket, "MAIL FROM:<" . $fromEmail . ">\r\n");
        $readResponse('MAIL FROM');

        // Send RCPT TO
        fwrite($socket, "RCPT TO:<" . $toEmail . ">\r\n");
        $readResponse('RCPT TO');

        // Send DATA
        fwrite($socket, "DATA\r\n");
        $dataLines = $readResponse('DATA');
        $dataLast = end($dataLines) ?: '';
        if (strpos($dataLast, '354') !== 0) {
            $logEntry = "[SMTP_ERROR] DATA rejected: " . $dataLast . " for " . $toEmail . "\n";
            @file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
            fclose($socket);
            return false;
        }

        // Construct email
        $email = "From: " . $fromName . " <" . $fromEmail . ">\r\n";
        $email .= "To: " . $toEmail . "\r\n";
        $email .= "Subject: " . $subject . "\r\n";
        $email .= "Content-Type: text/plain; charset=UTF-8\r\n";
        $email .= "Content-Transfer-Encoding: 8bit\r\n\r\n";
        $email .= $message . "\r\n";
        
        // Send message
        fwrite($socket, $email . "\r\n.\r\n");
        $messageLines = $readResponse('MESSAGE');
        $messageLast = end($messageLines) ?: '';
        if (strpos($messageLast, '250') !== 0) {
            $logEntry = "[SMTP_ERROR] Message sending failed: " . $messageLast . " for " . $toEmail . "\n";
            @file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
            fclose($socket);
            return false;
        }
        
        // Send QUIT
        fwrite($socket, "QUIT\r\n");
        fclose($socket);
        
        $logEntry = "[SMTP_SUCCESS] Email successfully sent via SMTP to " . $toEmail . "\n";
        @file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
        error_log("[SMTP] Email sent successfully to " . $toEmail);
        return true;
        
    } catch (Exception $e) {
        $logEntry = "[SMTP_ERROR] Exception: " . $e->getMessage() . " for " . $toEmail . "\n";
        @file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
        error_log("[SMTP] Exception: " . $e->getMessage());
        return false;
    }
}

function sendOtpEmail($toEmail, $otpCode, $userName = 'User') {
    $subject = 'Kode OTP Verifikasi Email';
    
    $message = "Halo $userName,\n\n";
    $message .= "Kode OTP Anda: $otpCode\n\n";
    $message .= "Kode ini berlaku selama 15 menit.\n";
    $message .= "Jangan bagikan kode ini kepada siapapun.\n\n";
    $message .= "---\n";
    $message .= "Monitoring System";
    
    // Log email to file
    $logFile = __DIR__ . '/emails.log';
    $logEntry = "\n" . str_repeat("=", 80) . "\n";
    $logEntry .= "TIME: " . date('Y-m-d H:i:s') . "\n";
    $logEntry .= "TO: " . $toEmail . "\n";
    $logEntry .= "OTP: " . $otpCode . "\n";
    $logEntry .= "SUBJECT: " . $subject . "\n";
    $logEntry .= str_repeat("-", 80) . "\n";
    $logEntry .= $message . "\n";
    
    @file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
    
    // Try Gmail SMTP first
    if (sendViaSmtp($toEmail, $subject, $message)) {
        error_log("[OTP] Email sent via SMTP to " . $toEmail);
        return true;
    }
    
    // Fallback to mail() function
    error_log("[OTP] SMTP failed, falling back to mail()");
    $headers = "Content-Type: text/plain; charset=UTF-8\r\n";
    $headers .= "From: monitoring@system.local\r\n";
    
    @mail($toEmail, $subject, $message, $headers);
    
    return true;
}

/**
 * Handle email change OTP request
 */
function handleRequestEmailChangeOtp() {
    global $conn;
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['user_id']) || !isset($data['new_email'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID and new email required']);
        return;
    }
    
    $userId = (int)$data['user_id'];
    $newEmail = $data['new_email'];
    
    try {
        // Validate email
        if (!filter_var($newEmail, FILTER_VALIDATE_EMAIL)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Email tidak valid']);
            return;
        }
        
        // Get user name
        $userStmt = $conn->prepare("SELECT fullname FROM user WHERE id = ?");
        $userStmt->bind_param("i", $userId);
        $userStmt->execute();
        $userResult = $userStmt->get_result();
        $userName = 'User';
        if ($userResult->num_rows > 0) {
            $userRow = $userResult->fetch_assoc();
            $userName = $userRow['fullname'];
        }
        
        // Generate OTP
        $otpCode = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        
        // Save OTP to database
        $stmt = $conn->prepare("INSERT INTO otp_tokens (email, otp_code, used) VALUES (?, ?, 0)");
        $stmt->bind_param("ss", $newEmail, $otpCode);
        $stmt->execute();
        
        // Send OTP via email
        sendOtpEmail($newEmail, $otpCode, $userName);
        
        echo json_encode([
            'success' => true,
            'message' => 'OTP telah dikirim ke email ' . htmlspecialchars($newEmail)
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
    }
}

/**
 * Handle email change OTP verification
 */
function handleVerifyEmailChangeOtp() {
    global $conn;
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['user_id']) || !isset($data['new_email']) || !isset($data['otp_code'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID, new email, and OTP required']);
        return;
    }
    
    $userId = (int)$data['user_id'];
    $newEmail = $data['new_email'];
    $otpCode = $data['otp_code'];
    
    try {
        // Check OTP
        $stmt = $conn->prepare("SELECT id, otp_code, created_at FROM otp_tokens WHERE email = ? AND otp_code = ? AND used = 0 ORDER BY created_at DESC LIMIT 1");
        $stmt->bind_param("ss", $newEmail, $otpCode);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Invalid OTP']);
            return;
        }
        
        $otp = $result->fetch_assoc();
        $createdTime = strtotime($otp['created_at']);
        $currentTime = time();
        $timeDiff = ($currentTime - $createdTime) / 60; // in minutes
        
        // Check if OTP expired (15 minutes)
        if ($timeDiff > 15) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'OTP has expired']);
            return;
        }
        
        // Mark OTP as used
        $updateOtp = $conn->prepare("UPDATE otp_tokens SET used = 1 WHERE id = ?");
        $updateOtp->bind_param("i", $otp['id']);
        $updateOtp->execute();
        
        // Update user email
        $updateUser = $conn->prepare("UPDATE user SET email = ? WHERE id = ?");
        $updateUser->bind_param("si", $newEmail, $userId);
        $updateUser->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Email verified and updated successfully'
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
    }
}

/**
 * Get user profile from database
 */
function handleGetProfile() {
    global $conn;
    
    // Get user_id from GET or POST
    $userId = $_GET['user_id'] ?? $_POST['user_id'] ?? null;
    
    if (!$userId) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID required']);
        return;
    }
    
    $userId = (int)$userId;
    
    try {
        $stmt = $conn->prepare("SELECT id, username, email, fullname, phone, location, division, role FROM user WHERE id = ?");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User tidak ditemukan']);
            return;
        }
        
        $user = $result->fetch_assoc();
        
        echo json_encode([
            'success' => true,
            'data' => [
                'id' => $user['id'],
                'user_id' => $user['id'],
                'username' => $user['username'],
                'email' => $user['email'],
                'fullname' => $user['fullname'],
                'phone' => $user['phone'] ?? '',
                'location' => $user['location'] ?? '',
                'division' => $user['division'] ?? '',
                'role' => $user['role']
            ]
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
    }
}

/**
 * Change user password
 */
function handleChangePassword() {
    global $conn;
    
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['user_id']) || !isset($data['old_password']) || !isset($data['new_password'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User ID, old password, and new password required']);
        return;
    }
    
    $userId = (int)$data['user_id'];
    $oldPassword = $data['old_password'];
    $newPassword = $data['new_password'];
    
    try {
        // Validate new password strength
        if (strlen($newPassword) < 8) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Password minimal 8 karakter']);
            return;
        }
        
        // Get current password hash
        $stmt = $conn->prepare("SELECT password FROM user WHERE id = ?");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User tidak ditemukan']);
            return;
        }
        
        $user = $result->fetch_assoc();
        
        // Verify old password
        if (!password_verify($oldPassword, $user['password'])) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Password lama tidak sesuai']);
            return;
        }
        
        // Hash new password
        $newPasswordHash = password_hash($newPassword, PASSWORD_BCRYPT);
        
        // Update password
        $updateStmt = $conn->prepare("UPDATE user SET password = ? WHERE id = ?");
        $updateStmt->bind_param("si", $newPasswordHash, $userId);
        $updateStmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => 'Password berhasil diubah'
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
    }
}

/**
 * Get latest OTP for an email (for local testing only)
 * Remove this function in production!
 */
function handleGetLatestOtp() {
    global $conn;
    
    $email = $_GET['email'] ?? $_POST['email'] ?? '';
    
    if (empty($email)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Email parameter required']);
        return;
    }
    
    try {
        // Get latest OTP
        $stmt = $conn->prepare("SELECT otp_code, created_at, used FROM otp_tokens WHERE email = ? ORDER BY created_at DESC LIMIT 1");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'No OTP found for this email']);
            return;
        }
        
        $otp = $result->fetch_assoc();
        
        echo json_encode([
            'success' => true,
            'otp_code' => $otp['otp_code'],
            'created_at' => $otp['created_at'],
            'used' => $otp['used'] ? 'Ya' : 'Tidak',
            '_note' => 'TESTING ONLY - Remove in production'
        ]);
        
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
    }
}
?>
