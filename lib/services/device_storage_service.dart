import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_model.dart';

class DeviceStorageService {
  static const String _storageKey = 'added_devices';

  static Future<void> _saveDevices(List<AddedDevice> devices) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = devices.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  // Simpan device baru
  static Future<void> addDevice(AddedDevice device) async {
    try {
      final devicesList = await getDevices();

      devicesList.add(device);
      await _saveDevices(devicesList);
    } catch (e) {
      print('Warning: Could not add device to storage: $e');
    }
  }

  // Ambil semua device
  static Future<List<AddedDevice>> getDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      final devices = <AddedDevice>[];

      for (final item in jsonList) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map<String, dynamic>) {
            devices.add(AddedDevice.fromJson(decoded));
          } else if (decoded is Map) {
            devices.add(
              AddedDevice.fromJson(
                decoded.map((key, value) => MapEntry(key.toString(), value)),
              ),
            );
          }
        } catch (e) {
          print('Warning: Skipping invalid device record in storage: $e');
        }
      }

      return devices;
    } catch (e) {
      print('Warning: Could not retrieve devices from storage: $e');
      return [];
    }
  }

  // Hapus device berdasarkan ID
  static Future<void> removeDevice(String deviceId) async {
    try {
      final devicesList = await getDevices();

      devicesList.removeWhere((d) => d.id == deviceId);
      await _saveDevices(devicesList);
    } catch (e) {
      print('Warning: Could not remove device from storage: $e');
    }
  }

  static Future<void> overwriteDevices(List<AddedDevice> devices) async {
    try {
      await _saveDevices(devices);
    } catch (e) {
      print('Warning: Could not overwrite devices in storage: $e');
    }
  }

  static Future<int> removeByTypeAndNameOrIp({
    required String type,
    String? name,
    String? ipAddress,
  }) async {
    try {
      final normalizedType = type.trim().toLowerCase();
      final normalizedName = (name ?? '').trim().toLowerCase();
      final normalizedIp = (ipAddress ?? '').trim();

      final devicesList = await getDevices();
      final originalLength = devicesList.length;

      devicesList.removeWhere((d) {
        if (d.type.trim().toLowerCase() != normalizedType) {
          return false;
        }

        final sameName =
            normalizedName.isNotEmpty && d.name.trim().toLowerCase() == normalizedName;
        final sameIp = normalizedIp.isNotEmpty && d.ipAddress.trim() == normalizedIp;
        return sameName || sameIp;
      });

      if (devicesList.length != originalLength) {
        await _saveDevices(devicesList);
      }

      return originalLength - devicesList.length;
    } catch (e) {
      print('Warning: Could not remove device by type/name/ip: $e');
      return 0;
    }
  }

  // Bersihkan semua device
  static Future<void> clearAllDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Warning: Could not clear devices from storage: $e');
    }
  }
}
