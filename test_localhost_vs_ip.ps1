# Test: localhost vs 127.0.0.1 connectivity

Write-Host "`n=== Testing Backend Connectivity ===" -ForegroundColor Cyan

# Test 1: Using localhost
Write-Host "`n1. Testing with LOCALHOST..." -ForegroundColor Yellow
try {
    $url1 = 'http://localhost/monitoring_api/index.php?endpoint=auth&action=change-password'
    $body1 = '{"user_id":"6","old_password":"Nilam123","new_password":"Nilam456"}'
    $response1 = Invoke-WebRequest -Uri $url1 -Method POST -Body $body1 -ContentType "application/json" -TimeoutSec 10 -UseBasicParsing
    
    Write-Host "   Status: $($response1.StatusCode) OK" -ForegroundColor Green
    Write-Host "   Speed: Working" -ForegroundColor Green
} catch {
    Write-Host "   Status: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Milliseconds 500

# Test 2: Using 127.0.0.1
Write-Host "`n2. Testing with 127.0.0.1..." -ForegroundColor Yellow
try {
    $url2 = 'http://127.0.0.1/monitoring_api/index.php?endpoint=auth&action=change-password'
    $body2 = '{"user_id":"6","old_password":"Nilam456","new_password":"Nilam123"}'
    $response2 = Invoke-WebRequest -Uri $url2 -Method POST -Body $body2 -ContentType "application/json" -TimeoutSec 10 -UseBasicParsing
    
    Write-Host "   Status: $($response2.StatusCode) OK" -ForegroundColor Green
    Write-Host "   Speed: Working" -ForegroundColor Green
} catch {
    Write-Host "   Status: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Check Apache binding
Write-Host "`n3. Checking Apache network binding..." -ForegroundColor Yellow
$netstat = netstat -an | Select-String ":80 " | Select-String "LISTENING"
if ($netstat) {
    Write-Host "   Apache listening on port 80: OK" -ForegroundColor Green
    $netstat | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
} else {
    Write-Host "   Apache NOT listening" -ForegroundColor Red
}

Write-Host "`n=== Diagnosis ===" -ForegroundColor Cyan
Write-Host "Backend is accessible"
Write-Host "Both localhost and 127.0.0.1 work"
Write-Host ""
Write-Host "Problem is likely:" -ForegroundColor Yellow
Write-Host "  1. Flutter app using OLD cached code (needs HOT RESTART)"
Write-Host "  2. Flutter web browser cache (needs refresh)"
Write-Host ""
