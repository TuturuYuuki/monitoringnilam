Write-Host 'Testing Backend Change Password' -ForegroundColor Cyan
Write-Host ''

# Test simple connection first
Write-Host 'Step 1: Check server...'
try {
    $test = Invoke-WebRequest -Uri 'http://localhost/monitoring_api/index.php?endpoint=auth&action=check-auth' -UseBasicParsing -TimeoutSec 5
    Write-Host 'Server: ONLINE (Status: ' $test.StatusCode ')' -ForegroundColor Green
} catch {
    Write-Host 'Server: ERROR - ' $_.Exception.Message -ForegroundColor Red
    exit
}

Write-Host ''
Write-Host 'Step 2: Test change password (with timing)...'
$body = '{"user_id":6,"old_password":"Nilam123","new_password":"Test123456"}'
$start = Get-Date

try {
    $response = Invoke-WebRequest `
        -Uri 'http://localhost/monitoring_api/index.php?endpoint=auth&action=change-password' `
        -Method POST `
        -ContentType 'application/json' `
        -Body $body `
        -UseBasicParsing `
        -TimeoutSec 10
    
    $end = Get-Date
    $duration = ($end - $start).TotalMilliseconds
    
    Write-Host 'Status Code:' $response.StatusCode -ForegroundColor Green
    Write-Host 'Response Time:' ([math]::Round($duration, 2)) 'ms' -ForegroundColor Green
    Write-Host 'Response Body:' -ForegroundColor Yellow
    Write-Host $response.Content
    
    # Revert password
    Write-Host ''
    Write-Host 'Reverting password...'
    $revertBody = '{"user_id":6,"old_password":"Test123456","new_password":"Nilam123"}'
    $revert = Invoke-WebRequest `
        -Uri 'http://localhost/monitoring_api/index.php?endpoint=auth&action=change-password' `
        -Method POST `
        -ContentType 'application/json' `
        -Body $revertBody `
        -UseBasicParsing `
        -TimeoutSec 10
    Write-Host 'Reverted: ' $revert.StatusCode -ForegroundColor Green
    
} catch {
    $end = Get-Date
    $duration = ($end - $start).TotalMilliseconds
    
    Write-Host 'ERROR after' ([math]::Round($duration, 2)) 'ms' -ForegroundColor Red
    Write-Host 'Error Message:' $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Response) {
        Write-Host 'HTTP Status:' $_.Exception.Response.StatusCode.value__ -ForegroundColor Red
    }
}

Write-Host ''
Write-Host '=== Diagnosis ===' -ForegroundColor Cyan
if ($duration -lt 500) {
    Write-Host '✓ Backend is FAST' -ForegroundColor Green
} elseif ($duration -lt 2000) {
    Write-Host '⚠ Backend is SLOW but OK' -ForegroundColor Yellow
} else {
    Write-Host '✗ Backend is TOO SLOW (timeout risk)' -ForegroundColor Red
}
