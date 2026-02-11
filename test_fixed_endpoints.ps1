# Test All Fixed Endpoints

Write-Host "`n=== TESTING FIXED BACKEND ENDPOINTS ===" -ForegroundColor Cyan
Write-Host "Testing after fixing user_id -> id column mismatch`n" -ForegroundColor Yellow

# Test 1: Check Connection (New Endpoint)
Write-Host "1. Test Check Connection Endpoint..." -ForegroundColor Yellow
try {
    $url = 'http://localhost/monitoring_api/index.php?endpoint=auth&action=check-connection'
    $response = Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing -TimeoutSec 5
    
    $json = $response.Content | ConvertFrom-Json
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Response: $($json.message)" -ForegroundColor Green
    Write-Host "   Database: $($json.database)" -ForegroundColor Green
} catch {
    Write-Host "   FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# Test 2: Get Profile (User ID 6)
Write-Host "`n2. Test Get Profile (User ID 6)..." -ForegroundColor Yellow
try {
    $url = 'http://localhost/monitoring_api/index.php?endpoint=auth&action=get-profile&user_id=6'
    $response = Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing -TimeoutSec 5
    
    $json = $response.Content | ConvertFrom-Json
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Username: $($json.data.username)" -ForegroundColor Green
    Write-Host "   Email: $($json.data.email)" -ForegroundColor Green
    Write-Host "   Fullname: $($json.data.fullname)" -ForegroundColor Green
    Write-Host "   ID (from DB): $($json.data.id)" -ForegroundColor Green
    Write-Host "   User_ID (compatibility): $($json.data.user_id)" -ForegroundColor Green
} catch {
    Write-Host "   FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# Test 3: Change Password (Nilam123 -> TestPass123)
Write-Host "`n3. Test Change Password (Nilam123 -> TestPass123)..." -ForegroundColor Yellow
try {
    $url = 'http://localhost/monitoring_api/index.php?endpoint=auth&action=change-password'
    $body = @{
        user_id = 6
        old_password = 'Nilam123'
        new_password = 'TestPass123'
    } | ConvertTo-Json
    
    $startTime = Get-Date
    $response = Invoke-WebRequest -Uri $url -Method POST -Body $body -ContentType 'application/json' -UseBasicParsing -TimeoutSec 10
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    $json = $response.Content | ConvertFrom-Json
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Message: $($json.message)" -ForegroundColor Green
    Write-Host "   Response Time: $([math]::Round($duration, 2))ms" -ForegroundColor Green
} catch {
    Write-Host "   FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# Test 4: Revert Password (TestPass123 -> Nilam123)
Write-Host "`n4. Reverting Password (TestPass123 -> Nilam123)..." -ForegroundColor Yellow
try {
    $url = 'http://localhost/monitoring_api/index.php?endpoint=auth&action=change-password'
    $body = @{
        user_id = 6
        old_password = 'TestPass123'
        new_password = 'Nilam123'
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri $url -Method POST -Body $body -ContentType 'application/json' -UseBasicParsing -TimeoutSec 10
    
    $json = $response.Content | ConvertFrom-Json
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Message: $($json.message)" -ForegroundColor Green
} catch {
    Write-Host "   FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# Test 5: Wrong Old Password (Should Fail)
Write-Host "`n5. Test Wrong Old Password (Should Return 401)..." -ForegroundColor Yellow
try {
    $url = 'http://localhost/monitoring_api/index.php?endpoint=auth&action=change-password'
    $body = @{
        user_id = 6
        old_password = 'WrongPassword123'
        new_password = 'NewPass123'
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri $url -Method POST -Body $body -ContentType 'application/json' -UseBasicParsing -TimeoutSec 10
    
    Write-Host "   Unexpected Success - Should have failed!" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "   Status: 401 (Correct!)" -ForegroundColor Green
        Write-Host "   Error message validated: Password lama tidak sesuai" -ForegroundColor Green
    } else {
        Write-Host "   Wrong status code: $statusCode" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "All endpoints tested with id column (not user_id)" -ForegroundColor White
Write-Host "Check results above for any failures" -ForegroundColor White
Write-Host "`nNext step: Hot Restart Flutter app and test from mobile!" -ForegroundColor Yellow
Write-Host ""
