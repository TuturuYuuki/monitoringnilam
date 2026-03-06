import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_model.dart';

class DeviceStorageService {
  static const String _storageKey = 'added_devices';

  // Simpan device baru
  static Future<void> addDevice(AddedDevice device) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesList = await getDevices();

      devicesList.add(device);

      final jsonList = devicesList.map((d) => jsonEncode(d.toJson())).toList();

      await prefs.setStringList(_storageKey, jsonList);
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
      final prefs = await SharedPreferences.getInstance();
      final devicesList = await getDevices();

      devicesList.removeWhere((d) => d.id == deviceId);

      final jsonList = devicesList.map((d) => jsonEncode(d.toJson())).toList();

      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      print('Warning: Could not remove device from storage: $e');
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
