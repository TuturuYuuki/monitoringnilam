Write-Host 'Stopping Apache...' -ForegroundColor Yellow
taskkill /F /IM httpd.exe 2>&1 | Out-Null
taskkill /F /IM httpd.exe 2>&1 | Out-Null
Start-Sleep -Seconds 2

Write-Host 'Clearing PHP OPcache files...' -ForegroundColor Yellow
Get-Item -Path 'C:\xampp\php\opcache' -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Get-Item -Path 'C:\xampp\php\tmp' -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

Write-Host 'Starting Apache...' -ForegroundColor Yellow
& 'C:\xampp\apache\bin\httpd.exe' -k start
Start-Sleep -Seconds 3

Write-Host 'Testing server...' -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri 'http://localhost/' -UseBasicParsing -TimeoutSec 5
    Write-Host 'Server is running - Status:' $response.StatusCode -ForegroundColor Green
} catch {
    Write-Host 'Server error:' $_.Exception.Message -ForegroundColor Red
}

Write-Host ''
Write-Host 'Testing MMT 10 creation with fixed code...' -ForegroundColor Cyan
$response = (Invoke-WebRequest 'http://localhost/monitoring_api/test_mmt10.php' -UseBasicParsing).Content
Write-Host $response
