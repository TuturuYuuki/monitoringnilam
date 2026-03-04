import 'package:flutter/material.dart';

class MapPickerDialog extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const MapPickerDialog({
    super.key,
    this.initialLat = -7.209191,
    this.initialLng = 112.725250,
  });

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  late double selectedLat;
  late double selectedLng;

  // Simple map boundaries untuk container yard area
  // CY1: -7.210 to -7.208, 112.724 to 112.726
  // CY2: -7.209 to -7.207, 112.725 to 112.727
  // CY3: -7.208 to -7.206, 112.726 to 112.728

  final double mapMinLat = -7.212;
  final double mapMaxLat = -7.205;
  final double mapMinLng = 112.722;
  final double mapMaxLng = 112.730;

  @override
  void initState() {
    super.initState();
    selectedLat = widget.initialLat;
    selectedLng = widget.initialLng;
  }

  void _onMapTap(TapDownDetails details) {
    final screen = MediaQuery.of(context).size;
    final mapWidth = screen.width - 40;
    const mapHeight = 400.0;

    // Convert tap position to lat/lng
    final xPercent = details.localPosition.dx / mapWidth;
    final yPercent = details.localPosition.dy / mapHeight;

    final newLat = mapMaxLat - (yPercent * (mapMaxLat - mapMinLat));
    final newLng = mapMinLng + (xPercent * (mapMaxLng - mapMinLng));

    setState(() {
      selectedLat = newLat;
      selectedLng = newLng;
    });

    print('📍 Selected position: $selectedLat, $selectedLng');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Posisi Tower'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            // Instruksi
            const Padding(
              padding: EdgeInsets.only(bottom: 10.0),
              child: Text(
                'Tap di area map untuk memilih posisi tower',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            // Simple map (grid-based untuk visual)
            Expanded(
              child: GestureDetector(
                onTapDown: _onMapTap,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Grid background
                      CustomPaint(
                        painter: GridPainter(),
                        size: Size.infinite,
                      ),

                      // Container Yard labels
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Text(
                          'CY1',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Text(
                          'CY2/CY3',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                      // Selected position marker
                      Positioned(
                        left: _getPixelX(selectedLng),
                        top: _getPixelY(selectedLat),
                        child: Transform.translate(
                          offset: const Offset(-15, -15),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Koordinat display
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Latitude:'),
                        Text(
                          selectedLat.toStringAsFixed(6),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Longitude:'),
                        Text(
                          selectedLng.toStringAsFixed(6),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            {'latitude': selectedLat, 'longitude': selectedLng},
          ),
          child: const Text('Pilih Posisi'),
        ),
      ],
    );
  }

  double _getPixelX(double lng) {
    final mapWidth = MediaQuery.of(context).size.width - 40;
    final percent = (lng - mapMinLng) / (mapMaxLng - mapMinLng);
    return percent * mapWidth;
  }

  double _getPixelY(double lat) {
    const mapHeight = 400.0;
    final percent = (mapMaxLat - lat) / (mapMaxLat - mapMinLat);
    return percent * mapHeight;
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double i = 0; i <= size.width; i += size.width / 4) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += size.height / 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}
