/// ============================================================================
/// COORDINATES BACKUP - Dart Constants
/// Location: lib/constants/coordinates_backup.dart
/// 
/// Purpose: Backup semua koordinat lat/lng sebelum migration ke PNG layout
/// Backup Date: 2026-03-02
/// ============================================================================

class CoordinatesBackup {
  /// Reference Center Point
  static const double TPK_CENTER_LATITUDE = -7.207277;
  static const double TPK_CENTER_LONGITUDE = 112.723613;
  static const double TPK_DEFAULT_ZOOM = 16.5;

  /// Bounding Box
  static const double LAT_MIN_CURRENT = -7.210500;
  static const double LAT_MAX_CURRENT = -7.204000;
  static const double LNG_MIN_CURRENT = 112.721800;
  static const double LNG_MAX_CURRENT = 112.725500;

  // Recommended with margin untuk conversion accuracy
  static const double LAT_MIN_RECOMMENDED = -7.210500;
  static const double LAT_MAX_RECOMMENDED = -7.203500;
  static const double LNG_MIN_RECOMMENDED = 112.721500;
  static const double LNG_MAX_RECOMMENDED = 112.725800;

  /// Container Yards
  static const Map<String, Map<String, dynamic>> CONTAINER_YARDS = {
    'CY1': {
      'name': 'Container Yard 1',
      'lat': -7.205843,
      'lng': 112.723164,
    },
    'CY2': {
      'name': 'Container Yard 2',
      'lat': -7.209152,
      'lng': 112.724487,
    },
    'CY3': {
      'name': 'Container Yard 3',
      'lat': -7.208712,
      'lng': 112.723270,
    },
  };

  /// Towers (26 Total)
  static const Map<int, Map<String, dynamic>> TOWERS = {
    // CY2 Towers (1-6)
    1: {
      'name': 'Tower 1',
      'lat': -7.209459,
      'lng': 112.724717,
      'cy': 'CY2',
    },
    2: {
      'name': 'Tower 2',
      'lat': -7.209191,
      'lng': 112.725250,
      'cy': 'CY2',
    },
    3: {
      'name': 'Tower 3',
      'lat': -7.208561,
      'lng': 112.724946,
      'cy': 'CY2',
    },
    4: {
      'name': 'Tower 4',
      'lat': -7.208150,
      'lng': 112.724395,
      'cy': 'CY2',
    },
    5: {
      'name': 'Tower 5',
      'lat': -7.208262,
      'lng': 112.724161,
      'cy': 'CY2',
    },
    6: {
      'name': 'Tower 6',
      'lat': -7.208956,
      'lng': 112.724173,
      'cy': 'CY2',
    },
    // CY1 Towers (7-17)
    7: {
      'name': 'Tower 7',
      'lat': -7.207690,
      'lng': 112.723693,
      'cy': 'CY1',
    },
    8: {
      'name': 'Tower 8',
      'lat': -7.207567,
      'lng': 112.723945,
      'cy': 'CY1',
    },
    9: {
      'name': 'Tower 9',
      'lat': -7.207156,
      'lng': 112.724302,
      'cy': 'CY1',
    },
    10: {
      'name': 'Tower 10',
      'lat': -7.204341,
      'lng': 112.722956,
      'cy': 'CY1',
    },
    11: {
      'name': 'Tower 11',
      'lat': -7.204080,
      'lng': 112.722354,
      'cy': 'CY1',
    },
    12: {
      'name': 'Tower 12A',
      'lat': -7.204228,
      'lng': 112.722045,
      'cy': 'CY1',
      'hint': '12A',
    },
    13: {
      'name': 'Tower 12',
      'lat': -7.204460,
      'lng': 112.721970,
      'cy': 'CY1',
    },
    14: {
      'name': 'Tower 13',
      'lat': -7.205410,
      'lng': 112.722386,
      'cy': 'CY1',
    },
    15: {
      'name': 'Tower 14',
      'lat': -7.206786,
      'lng': 112.723023,
      'cy': 'CY1',
    },
    16: {
      'name': 'Tower 15',
      'lat': -7.207566,
      'lng': 112.723469,
      'cy': 'CY1',
    },
    17: {
      'name': 'Tower 16',
      'lat': -7.207342,
      'lng': 112.723059,
      'cy': 'CY1',
    },
    18: {
      'name': 'Tower 17',
      'lat': -7.209240,
      'lng': 112.723915,
      'cy': 'CY1',
    },
    // CY3 Towers (18-26)
    19: {
      'name': 'Tower 18',
      'lat': -7.210090,
      'lng': 112.724321,
      'cy': 'CY3',
    },
    20: {
      'name': 'Tower 19',
      'lat': -7.210336,
      'lng': 112.723639,
      'cy': 'CY3',
    },
    21: {
      'name': 'Tower 20',
      'lat': -7.210082,
      'lng': 112.723303,
      'cy': 'CY3',
    },
    22: {
      'name': 'Tower 21',
      'lat': -7.209070,
      'lng': 112.722914,
      'cy': 'CY3',
    },
    23: {
      'name': 'Tower 22',
      'lat': -7.208501,
      'lng': 112.722942,
      'cy': 'CY3',
    },
    24: {
      'name': 'Tower 23',
      'lat': -7.208017,
      'lng': 112.722195,
      'cy': 'CY3',
    },
    25: {
      'name': 'Tower 24',
      'lat': -7.207314,
      'lng': 112.722005,
      'cy': 'CY3',
    },
    26: {
      'name': 'Tower 25',
      'lat': -7.207213,
      'lng': 112.722232,
      'cy': 'CY3',
    },
    27: {
      'name': 'Tower 26',
      'lat': -7.207029,
      'lng': 112.722613,
      'cy': 'CY3',
    },
  };

  /// CCTV Devices (CC01-CC04)
  static const Map<String, Map<String, dynamic>> CCTV_DEVICES = {
    'CC01': {
      'name': 'CC01 - CY1',
      'lat': -7.204768,
      'lng': 112.723299,
      'cy': 'CY1',
    },
    'CC02': {
      'name': 'CC02 - CY1',
      'lat': -7.205358,
      'lng': 112.723571,
      'cy': 'CY1',
    },
    'CC03': {
      'name': 'CC03 - CY1',
      'lat': -7.205947,
      'lng': 112.723840,
      'cy': 'CY1',
    },
    'CC04': {
      'name': 'CC04 - CY1',
      'lat': -7.206656,
      'lng': 112.724164,
      'cy': 'CY1',
    },
  };

  /// RTG Devices (RTG01-RTG08)
  static const Map<String, Map<String, dynamic>> RTG_DEVICES = {
    'RTG01': {
      'name': 'RTG01 - CY1',
      'lat': -7.204805,
      'lng': 112.722550,
      'cy': 'CY1',
    },
    'RTG02': {
      'name': 'RTG02 - CY1',
      'lat': -7.205129,
      'lng': 112.723000,
      'cy': 'CY1',
    },
    'RTG03': {
      'name': 'RTG03 - CY1',
      'lat': -7.205998,
      'lng': 112.722836,
      'cy': 'CY1',
    },
    'RTG04': {
      'name': 'RTG04 - CY1',
      'lat': -7.206359,
      'lng': 112.723258,
      'cy': 'CY1',
    },
    'RTG05': {
      'name': 'RTG05 - CY1',
      'lat': -7.206749,
      'lng': 112.723464,
      'cy': 'CY1',
    },
    'RTG06': {
      'name': 'RTG06 - CY1',
      'lat': -7.207079,
      'lng': 112.723899,
      'cy': 'CY1',
    },
    'RTG07': {
      'name': 'RTG07 - CY2',
      'lat': -7.208641,
      'lng': 112.724410,
      'cy': 'CY2',
    },
    'RTG08': {
      'name': 'RTG08 - CY2',
      'lat': -7.208957,
      'lng': 112.724877,
      'cy': 'CY2',
    },
  };

  /// RS Device
  static const Map<String, Map<String, dynamic>> RS_DEVICE = {
    'RS': {
      'name': 'RS - CY3',
      'lat': -7.207700,
      'lng': 112.723028,
      'cy': 'CY3',
    },
  };

  /// Special Locations
  static const Map<String, Map<String, dynamic>> SPECIAL_LOCATIONS = {
    'GATE': {
      'name': 'Gate In/Out',
      'lat': -7.2099123,
      'lng': 112.7244489,
    },
    'PARKING': {
      'name': 'Parking',
      'lat': -7.209907,
      'lng': 112.724877,
    },
  };

  /// Summary
  static const Map<String, int> SUMMARY = {
    'towers': 26,
    'cctv': 4,
    'rtg': 8,
    'rs': 1,
    'special_locations': 2,
    'total': 41,
  };
}
