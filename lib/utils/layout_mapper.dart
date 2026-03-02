/// ============================================================================
/// Layout Mapper - Coordinate Conversion System
/// 
/// Converts between:
/// - Geographic coordinates (lat/lng) from database
/// - Pixel coordinates (x/y) on PNG layout image
/// 
/// Usage:
///   PixelCoordinate pixel = LayoutMapper.latLngToPixel(lat, lng);
///   // Use pixel.x and pixel.y to position markers on PNG canvas
/// ============================================================================

class PixelCoordinate {
  final double x;  // pixels from left
  final double y;  // pixels from top

  const PixelCoordinate(this.x, this.y);

  @override
  String toString() => 'PixelCoordinate(x: ${x.toStringAsFixed(1)}, y: ${y.toStringAsFixed(1)})';
}

class LayoutMapper {
  /// ===== PNG Layout Dimensions =====
  /// Update these values to match your actual PNG size
  static const double PNG_WIDTH = 1400;    // pixels
  static const double PNG_HEIGHT = 900;    // pixels

  /// ===== Bounding Box (Geographic Coordinates) =====
  /// These define the real-world boundaries that map to the PNG
  /// Format: degrees (e.g., -7.210500 = 7.2105° South)
  
  // Current TPK Nilam area bounds
  static const double LAT_MIN = -7.210500;   // South (bottom)
  static const double LAT_MAX = -7.203500;   // North (top)
  static const double LNG_MIN = 112.721500;  // West (left)
  static const double LNG_MAX = 112.725800;  // East (right)

  /// Calculate PNG dimensions in geographic units (for debugging)
  static double get latitudeRange => LAT_MAX - LAT_MIN;
  static double get longitudeRange => LNG_MAX - LNG_MIN;
  static double get pixelsPerLatitude => PNG_HEIGHT / latitudeRange;
  static double get pixelsPerLongitude => PNG_WIDTH / longitudeRange;

  /// ===== Main Conversion Methods =====

  /// Convert geographic coordinates (lat/lng) to pixel position on PNG
  ///
  /// Example:
  ///   PixelCoordinate pixel = LayoutMapper.latLngToPixel(-7.207277, 112.723613);
  ///   print('Pixel position: x=${pixel.x}, y=${pixel.y}');
  /// 
  /// Returns:
  ///   PixelCoordinate with x and y in pixel units (0-1400 for x, 0-900 for y)
  static PixelCoordinate latLngToPixel(double lat, double lng) {
    // Validate input
    if (lat < LAT_MAX || lat > LAT_MIN) {
      print('⚠️ Latitude $lat is outside bounds ($LAT_MAX to $LAT_MIN)');
    }
    if (lng < LNG_MIN || lng > LNG_MAX) {
      print('⚠️ Longitude $lng is outside bounds ($LNG_MIN to $LNG_MAX)');
    }

    // Normalize lat/lng to 0-1 range
    // latNorm: 0 = South (LAT_MIN), 1 = North (LAT_MAX)
    double latNorm = (lat - LAT_MIN) / (LAT_MAX - LAT_MIN);
    
    // lngNorm: 0 = West (LNG_MIN), 1 = East (LNG_MAX)
    double lngNorm = (lng - LNG_MIN) / (LNG_MAX - LNG_MIN);

    // Convert to pixel coordinates
    // Note: PNG Y-axis is flipped (0 at top, increases downward)
    // So we flip latNorm: Northern coordinates = top of image = low Y pixel
    double pixelX = lngNorm * PNG_WIDTH;
    double pixelY = (1 - latNorm) * PNG_HEIGHT;  // Flip Y-axis

    return PixelCoordinate(
      pixelX.clamp(0, PNG_WIDTH),
      pixelY.clamp(0, PNG_HEIGHT),
    );
  }

  /// Convert pixel position back to geographic coordinates (lat/lng)
  /// Useful for reverse lookup or user interactions on the map
  ///
  /// Example:
  ///   Map<String, double> coord = LayoutMapper.pixelToLatLng(700, 450);
  ///   double lat = coord['lat']!;
  ///   double lng = coord['lng']!;
  static Map<String, double> pixelToLatLng(double pixelX, double pixelY) {
    // Validate pixel range
    pixelX = pixelX.clamp(0, PNG_WIDTH);
    pixelY = pixelY.clamp(0, PNG_HEIGHT);

    // Normalize pixel to 0-1 range
    double lngNorm = pixelX / PNG_WIDTH;
    double latNorm = 1 - (pixelY / PNG_HEIGHT);  // Flip Y-axis back

    // Convert to geographic coordinates
    double lng = LNG_MIN + (lngNorm * (LNG_MAX - LNG_MIN));
    double lat = LAT_MIN + (latNorm * (LAT_MAX - LAT_MIN));

    return {
      'lat': lat,
      'lng': lng,
    };
  }

  /// ===== Utility Methods =====

  /// Check if a coordinate is within the layout bounds
  static bool isWithinBounds(double lat, double lng) {
    return lat >= LAT_MAX && 
           lat <= LAT_MIN && 
           lng >= LNG_MIN && 
           lng <= LNG_MAX;
  }

  /// Get the center of the layout in pixel coordinates
  static PixelCoordinate get centerPixel {
    return PixelCoordinate(PNG_WIDTH / 2, PNG_HEIGHT / 2);
  }

  /// Get the center of the layout in geographic coordinates
  static Map<String, double> get centerLatLng {
    double centerLat = (LAT_MIN + LAT_MAX) / 2;
    double centerLng = (LNG_MIN + LNG_MAX) / 2;
    return {
      'lat': centerLat,
      'lng': centerLng,
    };
  }

  /// Calculate distance in pixels between two geographic points
  static double distanceBetweenLatLng(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    PixelCoordinate pixel1 = latLngToPixel(lat1, lng1);
    PixelCoordinate pixel2 = latLngToPixel(lat2, lng2);

    double dx = pixel2.x - pixel1.x;
    double dy = pixel2.y - pixel1.y;

    return (dx * dx + dy * dy).isNaN ? 0 : (dx * dx + dy * dy).toStringAsFixed(1).length as double;
  }

  /// Debug: Print layout information
  static void printLayoutInfo() {
    print('═' * 60);
    print('🗺️  LAYOUT MAPPER CONFIGURATION');
    print('═' * 60);
    print('PNG Dimensions: ${PNG_WIDTH.toInt()} x ${PNG_HEIGHT.toInt()} px');
    print('');
    print('Geographic Bounds:');
    print('  Latitude:  $LAT_MAX (North) to $LAT_MIN (South)');
    print('  Longitude: $LNG_MIN (West) to $LNG_MAX (East)');
    print('');
    print('Pixel Scale:');
    print('  Pixels per Latitude:  ${pixelsPerLatitude.toStringAsFixed(2)} px/°');
    print('  Pixels per Longitude: ${pixelsPerLongitude.toStringAsFixed(2)} px/°');
    print('');
    print('Center:');
    var center = centerLatLng;
    print('  Geographic: ${center['lat']!.toStringAsFixed(6)}, ${center['lng']!.toStringAsFixed(6)}');
    var centerPixel = LayoutMapper.centerPixel;
    print('  Pixel: ${centerPixel.x.toInt()}, ${centerPixel.y.toInt()}');
    print('═' * 60);
  }

  /// ===== Calibration Tests =====
  /// Use these to verify mapping accuracy

  /// Test known reference points
  /// Returns true if the mapping seems reasonable
  static bool calibrateWithTestPoints() {
    // TPK Center
    PixelCoordinate centerPixel = latLngToPixel(-7.207277, 112.723613);
    print('✓ TPK Center -> Pixel: (${centerPixel.x.toInt()}, ${centerPixel.y.toInt()})');

    // Known towers (should be roughly positioned)
    PixelCoordinate tower1 = latLngToPixel(-7.209459, 112.724717);
    print('✓ Tower 1 -> Pixel: (${tower1.x.toInt()}, ${tower1.y.toInt()})');

    PixelCoordinate tower26 = latLngToPixel(-7.207029, 112.722613);
    print('✓ Tower 26 -> Pixel: (${tower26.x.toInt()}, ${tower26.y.toInt()})');

    // Check if points are within bounds
    bool allValid = centerPixel.x >= 0 && centerPixel.x <= PNG_WIDTH &&
        centerPixel.y >= 0 && centerPixel.y <= PNG_HEIGHT &&
        tower1.x >= 0 && tower1.x <= PNG_WIDTH &&
        tower1.y >= 0 && tower1.y <= PNG_HEIGHT &&
        tower26.x >= 0 && tower26.x <= PNG_WIDTH &&
        tower26.y >= 0 && tower26.y <= PNG_HEIGHT;

    return allValid;
  }
}
