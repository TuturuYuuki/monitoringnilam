import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/models/alert_model.dart';

void main() async {
  print("Starting API test...");
  
  // The same endpoint called by getAlertsReport
  final start = '2024-01-01';
  final end = '2030-01-01';
  final status = 'ALL';
  final url = Uri.parse('http://localhost/monitoring_api/index.php?endpoint=alerts&action=report&start=$start&end=$end&status=$status');
  
  try {
    final response = await http.get(url);
    print("Status Code: ${response.statusCode}");
    
    final jsonResponse = json.decode(response.body);
    print("Decoded type: ${jsonResponse.runtimeType}");
    
    if (jsonResponse is List) {
      final list = jsonResponse.whereType<Map>().toList();
      print("Found ${list.length} maps in list.");
      
      for (var i = 0; i < list.length && i < 2; i++) {
        final data = list[i];
        try {
          // Simulate the cast
          final casted = Map<String, dynamic>.from(data);
          print("Cast successful for item $i");
          
          final parsedAlert = Alert.fromJson(casted);
          print("Parsed Alert ID: ${parsedAlert.id}");
        } catch (e) {
          print("Error casting item $i: $e");
        }
      }
    } else if (jsonResponse is Map) {
      print("It is a map. Keys: ${jsonResponse.keys}");
    }
    
  } catch (e) {
    print("Request failed: $e");
  }
}
