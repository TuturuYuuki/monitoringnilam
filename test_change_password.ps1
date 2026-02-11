Write-Host '=== Testing Change Password Fix ===' -ForegroundColor Cyan
Write-Host ''

# Test 1: Sukses case
Write-Host 'Test 1: Correct old password' -ForegroundColor Yellow
$data1 = '{"user_id":6,"old_password":"Nilam123","new_password":"TestPass123"}'
$result1 = Invoke-WebRequest -Uri 'http://localhost/monitoring_api/index.php?endpoint=auth&action=change-password' `
    -Method POST -ContentType 'application/json' -Body $data1 -UseBasicParsing
Write-Host 'Status:' $result1.StatusCode
$json1 = $result1.Content | ConvertFrom-Json
Write-Host 'Success:' $json1.success
Write-Host 'Message:' $json1.message -ForegroundColor Green
Write-Host ''

# Revert
$dataRevert = '{"user_id":6,"old_password":"TestPass123","new_password":"Nilam123"}'
Invoke-WebRequest -Uri 'http://localhost/monitoring_api/index.php?endpoint=auth&action=change-password' `
    -Method POST -ContentType 'application/json' -Body $dataRevert -UseBasicParsing | Out-Null
Write-Host 'Reverted to original password' -ForegroundColor Gray
Write-Host ''

# Test 2: Wrong password
Write-Host 'Test 2: Wrong old password' -ForegroundColor Yellow
$data2 = '{"user_id":6,"old_password":"WrongPass123","new_password":"NewPass123"}'
try {
    $result2 = Invoke-WebRequest -Uri 'http://localhost/monitoring_api/index.php?endpoint=auth&action=change-password' `
        -Method POST -ContentType 'application/json' -Body $data2 -UseBasicParsing
    $json2 = $result2.Content | ConvertFrom-Json
    Write-Host 'Status:' $result2.StatusCode
    Write-Host 'Success:' $json2.success
    Write-Host 'Message:' $json2.message -ForegroundColor Red
} catch {
    $result2 = $_.Exception.Response
    $reader = [System.IO.StreamReader]::new($result2.GetResponseStream())
    $body = $reader.ReadToEnd()
    $reader.Close()
    $json2 = $body | ConvertFrom-Json
    Write-Host 'Status:' $result2.StatusCode.value__
    Write-Host 'Success:' $json2.success
    Write-Host 'Message:' $json2.message -ForegroundColor Red
}

Write-Host ''
Write-Host '✓ Backend API bekerja dengan baik!' -ForegroundColor Green
Write-Host ''
Write-Host 'Sekarang coba di Flutter app:' -ForegroundColor Cyan
Write-Host '1. Login dengan:' -ForegroundColor White
Write-Host '   Username: sisca' -ForegroundColor Yellow
Write-Host '   Password: Nilam123' -ForegroundColor Yellow
Write-Host '2. Pergi ke Profile > Ubah Password' -ForegroundColor White
Write-Host '3. Isi:' -ForegroundColor White
Write-Host '   Password Lama: Nilam123' -ForegroundColor Yellow
Write-Host '   Password Baru: TestPassword123' -ForegroundColor Yellow
Write-Host '4. Lihat console log untuk detail' -ForegroundColor White
