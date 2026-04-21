/// ============================================================================
/// Nilam Layout Map Widget
/// 
/// Custom map widget that renders:
/// - PNG layout image as background
/// - Device markers positioned on the layout
/// - Status indicators (UP/DOWN colors)
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:monitoring/models/device_marker.dart';
import 'package:monitoring/utils/layout_mapper.dart';

class NilamLayoutMap extends StatefulWidget {
  /// List of device markers to display
  final List<DeviceMarker> markers;

  /// Callback when a marker is tapped
  final Function(DeviceMarker)? onMarkerTap;

  /// Callback when map background is tapped
  final VoidCallback? onMapTap;

  /// Path to PNG layout image
  final String layoutImagePath;

  /// Show debug grid overlay
  final bool showDebugGrid;

  /// Show coordinate labels for debugging
  final bool showCoordinateLabels;

  const NilamLayoutMap({
    super.key,
    required this.markers,
    this.onMarkerTap,
    this.onMapTap,
    this.layoutImagePath = 'assets/images/nilam_layout.png',
    this.showDebugGrid = false,
    this.showCoordinateLabels = false,
  });

  @override
  State<NilamLayoutMap> createState() => _NilamLayoutMapState();
}

class _NilamLayoutMapState extends State<NilamLayoutMap> {
  DeviceMarker? _selectedMarker;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onMapTap,
      child: Container(
        color: Colors.grey[200],
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ===== Background PNG Layout =====
            _buildLayoutImage(),

            // ===== Debug Grid (if enabled) =====
            if (widget.showDebugGrid)
              _buildDebugGrid(),

            // ===== Device Markers =====
            _buildMarkers(),

            // ===== Info Panel (if marker selected) =====
            if (_selectedMarker != null)
              _buildInfoPanel(),
          ],
        ),
      ),
    );
  }

  /// Build the PNG layout background
  Widget _buildLayoutImage() {
    return Center(
      child: AspectRatio(
        aspectRatio: LayoutMapper.PNG_WIDTH / LayoutMapper.PNG_HEIGHT,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF1976D2),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Image.asset(
            widget.layoutImagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Layout image not found:\n${widget.layoutImagePath}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build debug grid overlay
  Widget _buildDebugGrid() {
    return Center(
      child: AspectRatio(
        aspectRatio: LayoutMapper.PNG_WIDTH / LayoutMapper.PNG_HEIGHT,
        child: CustomPaint(
          painter: _GridPainter(),
        ),
      ),
    );
  }

  /// Build device markers
  Widget _buildMarkers() {
    return Center(
      child: AspectRatio(
        aspectRatio: LayoutMapper.PNG_WIDTH / LayoutMapper.PNG_HEIGHT,
        child: Stack(
          children: widget.markers.map((marker) {
            // Convert pixel coordinates to relative position (0-1)
            double relativeX = marker.pixelX / LayoutMapper.PNG_WIDTH;
            double relativeY = marker.pixelY / LayoutMapper.PNG_HEIGHT;

            return Positioned(
              left: relativeX * 100 + '%'.length.toDouble(),
              top: relativeY * 100 + '%'.length.toDouble(),
              child: Transform.translate(
                offset: Offset(-marker.markerSize / 2, -marker.markerSize / 2),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedMarker = marker);
                    widget.onMarkerTap?.call(marker);
                  },
                  child: _buildMarkerWidget(marker),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build individual marker widget
  Widget _buildMarkerWidget(DeviceMarker marker) {
    final isSelected = _selectedMarker?.id == marker.id;

    return AnimatedScale(
      scale: isSelected ? 1.3 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marker circle
          Container(
            width: marker.markerSize,
            height: marker.markerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: marker.statusColor,
              border: Border.all(
                color: isSelected ? Colors.yellow : Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: marker.statusColor.withValues(alpha: 0.5),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                marker.icon,
                color: Colors.white,
                size: marker.markerSize * 0.6,
              ),
            ),
          ),

          // Marker label
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: marker.statusColor,
                width: 1,
              ),
            ),
            child: Text(
              marker.id,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Coordinate label (if debug enabled)
          if (widget.showCoordinateLabels) ...[
            const SizedBox(height: 2),
            Text(
              '(${marker.pixelX.toInt()}, ${marker.pixelY.toInt()})',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build info panel for selected marker
  Widget _buildInfoPanel() {
    if (_selectedMarker == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedMarker!.statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedMarker!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _selectedMarker!.typeName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _selectedMarker = null),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Details
            _buildInfoRow('Status', _selectedMarker!.statusText),
            if (_selectedMarker!.ipAddress != null)
              _buildInfoRow('IP Address', _selectedMarker!.ipAddress!),
            if (_selectedMarker!.containerYard != null)
              _buildInfoRow('Container Yard', _selectedMarker!.containerYard!),
            _buildInfoRow(
              'Coordinates',
              '${_selectedMarker!.latitude.toStringAsFixed(6)}\n${_selectedMarker!.longitude.toStringAsFixed(6)}',
            ),
          ],
        ),
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for debug grid
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 0.5;

    const gridSize = 50;

    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
