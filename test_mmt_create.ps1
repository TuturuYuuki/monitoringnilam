Write-Host 'Test 1: GET all MMTs' -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri 'http://localhost/monitoring_api/index.php?endpoint=mmt&action=all' -TimeoutSec 5 -UseBasicParsing
    Write-Host 'Status:' $response.StatusCode -ForegroundColor Green
    $data = $response.Content | ConvertFrom-Json
    Write-Host 'Items count:' $data.count -ForegroundColor Green
    Write-Host 'Sample data:' ($data.data | ConvertTo-Json) -ForegroundColor Cyan
} catch {
    Write-Host 'Error:' $_.Exception.Message -ForegroundColor Red
}

Write-Host ''
Write-Host 'Test 2: Create MMT 10' -ForegroundColor Yellow

$json = @{
    mmt_id = "MMT 10"
    location = "Tower 1 - CY2"
    ip_address = "192.168.137.250"
    container_yard = "CY1"
    status = "UP"
    type = "Mine Monitor"
    device_count = 1
    traffic = "0 Mbps"
    uptime = "0%"
} | ConvertTo-Json

Write-Host 'Sending payload:' -ForegroundColor Cyan
Write-Host $json -ForegroundColor White

try {
    $response = Invoke-WebRequest -Uri 'http://localhost/monitoring_api/index.php?endpoint=mmt&action=create' `
        -Method POST `
        -Headers @{'Content-Type'='application/json'} `
        -Body $json `
        -UseBasicParsing
    Write-Host 'Status:' $response.StatusCode -ForegroundColor Green
    Write-Host 'Response:' $response.Content -ForegroundColor Green
} catch {
    Write-Host 'Exception caught' -ForegroundColor Red
    Write-Host 'Message:' $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $sr = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $body = $sr.ReadToEnd()
        $sr.Close()
        if ($body) {
            Write-Host 'Response body:' -ForegroundColor Red
            Write-Host $body -ForegroundColor White
        }
    }
}

Write-Host ''
Write-Host 'Test 3: Check database for MMT 10' -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri 'http://localhost/monitoring_api/index.php?endpoint=mmt&action=by-id&mmt_id=MMT%2010' `
        -TimeoutSec 5 -UseBasicParsing
    Write-Host 'Status:' $response.StatusCode -ForegroundColor Green
    Write-Host 'Response:' $response.Content -ForegroundColor Green
} catch {
    Write-Host 'Not found or error:' $_.Exception.Message -ForegroundColor Yellow
}
