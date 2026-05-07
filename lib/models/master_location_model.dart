import 'package:monitoring/utils/location_label_utils.dart';

class MasterLocation {
  final int id;
  final String locationType;
  final String locationCode;
  final String locationName;
  final String containerYard;
  final double latitude;
  final double longitude;
  final String? itemId;

  MasterLocation({
    required this.id,
    required this.locationType,
    required this.locationCode,
    required this.locationName,
    required this.containerYard,
    required this.latitude,
    required this.longitude,
    this.itemId,
  });

  factory MasterLocation.fromMap(Map<String, dynamic> map) {
    return MasterLocation(
      id: int.tryParse((map['id'] ?? '0').toString()) ?? 
          int.tryParse((map['item_id'] ?? '0').toString()) ?? 0,
      locationType: (map['location_type'] ?? '').toString(),
      locationCode: (map['location_code'] ?? '').toString(),
      locationName: canonicalizeLocationLabel((map['location_name'] ?? '').toString()),
      containerYard: (map['container_yard'] ?? '').toString(),
      latitude: double.tryParse((map['latitude'] ?? '0').toString()) ?? 0.0,
      longitude: double.tryParse((map['longitude'] ?? '0').toString()) ?? 0.0,
      itemId: map['item_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'location_type': locationType,
      'location_code': locationCode,
      'location_name': locationName,
      'container_yard': containerYard,
      'latitude': latitude,
      'longitude': longitude,
      'item_id': itemId,
    };
  }
}
