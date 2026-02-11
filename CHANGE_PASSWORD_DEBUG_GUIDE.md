## 🔍 DEBUG GUIDE - Change Password Issue

### Root Cause Analysis

Setelah debugging, ditemukan bahwa:
1. ✅ **Backend API berfungsi normal** (tested dengan curl)
2. ❌ **Problem: Error message dari backend tidak ditampilkan dengan detail**
3. ❌ **Problem: User ID mungkin null atau invalid**

---

### Perbaikan yang Diterapkan

#### 1. **Enhanced Error Handling** ([api_service.dart](../lib/services/api_service.dart))
- Tambahkan logging detail request/response
- Handle semua HTTP status codes (200, 401, 404, 408)
- Parse error message dari backend untuk semua status

#### 2. **Better User Feedback** ([change_password.dart](../lib/change_password.dart))
- Tampilkan error message spesifik dari backend (bukan generic "Gagal mengubah password")
- Tambahkan icon di dialog (✓ untuk sukses, ✗ untuk gagal)
- Logging untuk debug user_id dan password status

#### 3. **Improved User Loading** ([change_password.dart](../lib/change_password.dart))
- Check multiple user_id fields: 'user_id', 'id'
- Logging untuk memastikan user_id valid
- Warning jika user_id null

---

### Testing Checklist

**Sebelum Test:**
1. Pastikan sudah login sebagai user yang valid
2. User yang tersedia:
   - ID: 6, Username: `sisca`, Email: `tuturu.yukihime@gmail.com`
   - ID: 7, Username: `testuser`, Email: `test@example.com`

**Test Scenarios:**

#### ✅ **Scenario 1: Sukses Change Password**
- Password Lama: `Nilam123` (atau password saat ini)
- Password Baru: `NewNilam123` (harus 8+ karakter, huruf besar/kecil/angka)
- **Expected:** Dialog hijau "Berhasil" dengan message sukses

#### ❌ **Scenario 2: Password Lama Salah**
- Password Lama: `WrongPassword123`
- Password Baru: `NewNilam123`
- **Expected:** Dialog merah "Gagal" dengan message "Password lama tidak sesuai"

#### ❌ **Scenario 3: Password Terlalu Pendek**
- Password Lama: `Nilam123`
- Password Baru: `abc123` (kurang dari 8 karakter)
- **Expected:** Validation error sebelum API call

---

### Cara Cek Console Log

**Di VS Code:**
1. Buka **Debug Console** (Ctrl+Shift+Y)
2. Jalankan Flutter app dalam debug mode
3. Pergi ke halaman Change Password
4. Cari log:
   ```
   === Loading User for Change Password ===
   User ID: 6
   
   === Starting Change Password ===
   User ID: 6
   Current Password: [PROVIDED]
   New Password: [PROVIDED]
   
   === Change Password Request ===
   Response Status: 200 (atau 401/404)
   Response Body: {"success":true,...}
   ```

**Di Chrome DevTools (jika run di web):**
1. Buka DevTools (F12)
2. Tab **Console**
3. Lihat log yang sama seperti di atas

---

### Common Issues & Solutions

#### Problem: "Gagal mengubah password" (Generic Error)
**Cause:** Error message dari backend tidak ditampilkan
**Solution:** ✅ Sudah diperbaiki - sekarang menampilkan message spesifik

#### Problem: "User ID null"
**Cause:** AuthHelper tidak menyimpan user_id dengan benar saat login
**Solution:** Check di console log, jika null maka re-login diperlukan

#### Problem: "Password lama tidak sesuai"
**Cause:** Password yang dimasukkan salah
**Solution:** Coba password default: `Nilam123`, `password123`, atau `Password123`

#### Problem: Request Timeout
**Cause:** Backend lambat atau tidak bisa diakses
**Solution:** 
- Check Apache server status
- Test API manual: `http://localhost/monitoring_api/index.php?endpoint=auth&action=change-password`

---

### Manual API Test

Test langsung tanpa Flutter:

```bash
# Test dengan curl
curl -X POST "http://localhost/monitoring_api/index.php?endpoint=auth&action=change-password" \
  -H "Content-Type: application/json" \
  -d '{"user_id":6,"old_password":"Nilam123","new_password":"NewNilam123"}'
```

Atau buka di browser:
```
http://localhost/monitoring_api/debug_change_password.php
```

---

### Expected Behavior (After Fix)

**Sukses:**
```
Dialog dengan icon ✓ hijau
Title: "Berhasil"  
Message: "Password berhasil diubah"
```

**Gagal (Password Salah):**
```
Dialog dengan icon ✗ merah
Title: "Gagal"
Message: "Password lama tidak sesuai"
```

**Gagal (User Not Found):**
```
Dialog dengan icon ✗ merah
Title: "Gagal"
Message: "User tidak ditemukan"
```

---

### Next Steps for User

1. **Hot Reload** Flutter app (R di console, atau save file)
2. **Login** dengan user yang valid (sisca / Nilam123)
3. **Go to** halaman Change Password
4. **Fill:**
   - Password Saat Ini: `Nilam123`
   - Password Baru: `NewNilam123`
   - Konfirmasi: `NewNilam123`
5. **Click** "Ubah Password"
6. **Check** console log untuk debug info
7. **See** dialog dengan error message yang spesifik

Jika masih error, share console log output!
