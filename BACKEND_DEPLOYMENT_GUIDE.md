# Backend Deployment Guide

## Summary of Changes

All backend PHP files have been updated to properly handle IP addresses dynamically (no hardcoding) and to properly route endpoints using a router system.

## Files to Deploy to `C:\xampp\htdocs\monitoring_api\`

### 1. **index.php** (NEW - CRITICAL)
- **Purpose**: Main router for all API endpoints
- **What it does**: Routes requests to appropriate endpoint files (network.php, cctv.php, mmt.php, realtime.php, alerts.php, auth.php)
- **Features**: Gracefully handles missing files with JSON 404 responses
- **Status**: Replace any existing index.php with this new version

### 2. **network.php** (UPDATED)
- **Purpose**: Handle Access Point/Tower endpoints
- **Changes**: IP address is now dynamically read from request data ($data['ip_address']), NOT hardcoded to 10.2.71.60
- **Endpoints**: 
  - GET: /index.php?endpoint=network&action=all|by-yard|by-id|stats
  - POST: /index.php?endpoint=network&action=create|update-status
- **Status**: Must replace old network.php

### 3. **cctv.php** (UPDATED)
- **Purpose**: Handle CCTV/Camera endpoints
- **Changes**: IP address is now dynamically read from request data ($data['ip_address']), NOT hardcoded
- **Endpoints**: 
  - GET: /index.php?endpoint=cctv&action=all|by-yard|by-id|stats
  - POST: /index.php?endpoint=cctv&action=create|update-status
- **Status**: Must replace old cctv.php

### 4. **auth.php** (NEW)
- **Purpose**: Handle authentication endpoints
- **Features**: 
  - login: Verify email/password
  - logout: User logout
  - register: New user registration
  - verify-otp: Verify OTP code
  - resend-otp: Resend OTP to email
  - check-auth: Check authentication status
- **Status**: New file, copy as-is

### 5. **realtime.php** (NEW)
- **Purpose**: Real-time status check for all devices
- **Features**: Pings all unique IPs from towers, cameras, and MMT devices, updates database status
- **Endpoints**: GET: /index.php?endpoint=realtime&action=all
- **Status**: New file, copy as-is

### 6. **alerts.php** (NEW)
- **Purpose**: Alert management and retrieval
- **Features**: 
  - Get all alerts
  - Get critical alerts with severity filtering
  - Filter by category
- **Endpoints**: GET: /index.php?endpoint=alerts&action=all|critical|by-category
- **Status**: New file, copy as-is

### 7. **mmt.php** (EXISTING)
- **Purpose**: Handle MMT device endpoints
- **Status**: Should already exist; verify it's in place

## Deployment Steps

### Step 1: Backup Old Files
```powershell
# Create backup folder
mkdir "C:\xampp\htdocs\monitoring_api_backup_$(Get-Date -Format yyyyMMdd_HHmmss)"

# Copy existing files to backup
Copy-Item "C:\xampp\htdocs\monitoring_api\*" "C:\xampp\htdocs\monitoring_api_backup_*"
```

### Step 2: Remove Old Files
Delete old versions if they exist:
- `C:\xampp\htdocs\monitoring_api\index.php` (old version)
- `C:\xampp\htdocs\monitoring_api\network.php` (old version with hardcoded IP)
- `C:\xampp\htdocs\monitoring_api\cctv.php` (old version with hardcoded IP)

### Step 3: Copy New Files
Copy from `C:\Tuturu\File alvan\PENS\KP\monitoring\` to `C:\xampp\htdocs\monitoring_api\`:

```powershell
$source = "C:\Tuturu\File alvan\PENS\KP\monitoring"
$dest = "C:\xampp\htdocs\monitoring_api"

# Copy new/updated files
Copy-Item "$source\index.php" "$dest\index.php"
Copy-Item "$source\network.php" "$dest\network.php"
Copy-Item "$source\cctv.php" "$dest\cctv.php"
Copy-Item "$source\auth.php" "$dest\auth.php"
Copy-Item "$source\realtime.php" "$dest\realtime.php"
Copy-Item "$source\alerts.php" "$dest\alerts.php"
Copy-Item "$source\mmt.php" "$dest\mmt.php"
```

### Step 4: Verify File Permissions
Windows XAMPP typically has proper permissions, but verify all .php files are readable:
```powershell
Get-ChildItem "C:\xampp\htdocs\monitoring_api\*.php" | Select-Object Name, FullName
```

### Step 5: Restart XAMPP Apache
```powershell
# Stop Apache
Stop-Service "Apache2.4"

# Start Apache
Start-Service "Apache2.4"

# Or if using XAMPP control panel: Stop Apache → Start Apache
```

## Testing After Deployment

### Test 1: Check Endpoint Routing
```powershell
# Test network endpoint
Invoke-WebRequest "http://localhost/monitoring_api/index.php?endpoint=network&action=all" | Select-Object Content

# Expected: JSON response (not HTML error)
```

### Test 2: Check CCTV Endpoint
```powershell
Invoke-WebRequest "http://localhost/monitoring_api/index.php?endpoint=cctv&action=all" | Select-Object Content
```

### Test 3: Check Realtime Endpoint
```powershell
Invoke-WebRequest "http://localhost/monitoring_api/index.php?endpoint=realtime&action=all" | Select-Object Content
```

### Test 4: Check Alerts Endpoint
```powershell
Invoke-WebRequest "http://localhost/monitoring_api/index.php?endpoint=alerts&action=all" | Select-Object Content
```

### Test 5: Test IP Not Hardcoded
Create new device via Flutter app and verify:
1. Console should NOT show `10.2.71.60` repeated in every request
2. Each device should use its actual IP address
3. IP should be user-input during device creation

## Troubleshooting

### Issue: Still seeing "SyntaxError: Unexpected token '<'" in Flutter console

**Causes**:
1. Apache not restarted after file copy
2. PHP files have syntax errors
3. Database tables missing
4. Old files conflicting with new files

**Solutions**:
```powershell
# Force restart Apache
Restart-Service Apache2.4 -Force

# Check PHP syntax (if you have PHP installed)
php -l "C:\xampp\htdocs\monitoring_api\index.php"
php -l "C:\xampp\htdocs\monitoring_api\network.php"
php -l "C:\xampp\htdocs\monitoring_api\cctv.php"
php -l "C:\xampp\htdocs\monitoring_api\realtime.php"
php -l "C:\xampp\htdocs\monitoring_api\alerts.php"
php -l "C:\xampp\htdocs\monitoring_api\auth.php"

# Check Apache error logs
Get-Content "C:\xampp\apache\logs\error.log" -Tail 20
```

### Issue: Database Connection Errors

Verify database connection in PHP files:
```powershell
# Check if monitoring_api database exists
# In MySQL:
# USE mysql;
# SELECT * FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = 'monitoring_api';
```

### Issue: Missing Required Tables

Create missing tables:
- `users` (if auth.php trying to access it)
- `alerts` (if alerts.php trying to access it)
- `otp_tokens` (if OTP feature needed)

See MMT_DATABASE_SETUP.md for table structures.

## Key Changes Summary

| File | Change | Benefit |
|------|--------|---------|
| index.php | NEW - Router system | All endpoints routed through index.php |
| network.php | IP now dynamic | No hardcoded 10.2.71.60 |
| cctv.php | IP now dynamic | No hardcoded 10.2.71.60 |
| auth.php | NEW | Auth endpoints available |
| realtime.php | NEW | Real-time ping check available |
| alerts.php | NEW | Alert management available |
| mmt.php | SAME | Still handles MMT devices |

## After Successful Deployment

1. ✅ Flutter app should no longer show "FormatException: SyntaxError: Unexpected token '<'"
2. ✅ Network calls should return valid JSON (not HTML error pages)
3. ✅ Device IP should be dynamic (not always 10.2.71.60)
4. ✅ Real-time status checks should work (realtime endpoint)
5. ✅ Alert queries should work (alerts endpoint)

## Rollback Plan

If something breaks:
```powershell
# Stop Apache
Stop-Service Apache2.4

# Restore from backup
Remove-Item "C:\xampp\htdocs\monitoring_api\*" -Force
Copy-Item "C:\xampp\htdocs\monitoring_api_backup_*\*" "C:\xampp\htdocs\monitoring_api\"

# Restart Apache
Start-Service Apache2.4
```

---

**Next Step**: Update Flutter code to use new IP-dynamic backend once deployment is complete.
