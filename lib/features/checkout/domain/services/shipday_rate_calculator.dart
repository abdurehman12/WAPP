import 'dart:convert';
import 'package:http/http.dart' as http;

class ShipdayRateCalculator {
  static const double maxDistance = 40.0; // Maximum allowed distance in miles
  static const double fixDistance = 10.0; // Fixed rate distance threshold
  static const double fixDistanceRate = 5.0; // Rate for fixed distance
  static const double intervalDistance = 1.0; // Distance interval
  static const double intervalRate = 1.0; // Rate per interval

  // Calculate shipping rate based on distance
  static Future<double> calculateRate(double distance) async {
    try {
      final response = await http.get(
        Uri.parse('https://wholesalepallets.uk/api/get_shipday_rate/$distance'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return double.parse(data['total_rate'].toString());
      } else {
        // Fallback calculation if API is unavailable
        return _calculateLocalRate(distance);
      }
    } catch (e) {
      print('Error getting Shipday rate from API: $e');
      return _calculateLocalRate(distance);
    }
  }

  // Local rate calculation as fallback
  static double _calculateLocalRate(double distance) {
    if (distance > maxDistance) {
      return 0.0; // Outside delivery radius
    }

    double totalRate = fixDistanceRate; // Start with fix distance rate

    if (distance > fixDistance) {
      // Calculate additional rate for distance beyond fix distance
      double extraDistance = distance - fixDistance;
      int intervals = (extraDistance / intervalDistance).ceil();
      totalRate += intervals * intervalRate;
    }

    return totalRate;
  }
}