import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';

class DistanceCalculatorWidget extends StatefulWidget {
  final Map<String, dynamic> deliveryAddress;
  final Function(double) onDistanceCalculated;

  const DistanceCalculatorWidget({
    Key? key,
    required this.deliveryAddress,
    required this.onDistanceCalculated,
  }) : super(key: key);

  @override
  State<DistanceCalculatorWidget> createState() => _DistanceCalculatorWidgetState();
}

class _DistanceCalculatorWidgetState extends State<DistanceCalculatorWidget> {
  bool _isLoading = true;
  String _distanceText = '';
  String? _errorMessage;

  // Warehouse location (origin)
  final String _warehouseAddress = '53.419040, -1.455223';

  // Your Google Maps API Key (IMPORTANT: Keep this secure and consider using environment variables)
  final String apiKey = 'AIzaSyBBFIP5MegcM9fM5GsUNueB8oPLuAIrJYc';

  @override
  void initState() {
    super.initState();
    _calculateRoadDistance();
  }

  @override
  void didUpdateWidget(DistanceCalculatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deliveryAddress != widget.deliveryAddress) {
      _calculateRoadDistance();
    }
  }

  String _formatAddress(Map<String, dynamic> address) {
    return '${address['address']}, ${address['city'] ?? ''}, ${address['zipCode'] ?? ''}, UK'
        .replaceAll(RegExp(r',\s*,'), ',')
        .replaceAll(RegExp(r',\s*$'), '');
  }

  Future<void> _calculateRoadDistance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final destinationAddress = _formatAddress(widget.deliveryAddress);

      // Encode addresses for the API call
      final String encodedOrigin = Uri.encodeComponent(_warehouseAddress);
      final String encodedDestination = Uri.encodeComponent(destinationAddress);

      // Construct the Distance Matrix API URL
      final String url = 'https://maps.googleapis.com/maps/api/distancematrix/json?'
          'origins=$encodedOrigin&'
          'destinations=$encodedDestination&'
          'units=imperial&'
          'key=$apiKey';

      // Make the API request
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      // Check the API response
      if (data['status'] == 'OK') {
        final results = data['rows'][0]['elements'][0];

        if (results['status'] == 'OK') {
          // Extract distance in miles
          final distanceText = results['distance']['text'];
          final distance = double.parse(distanceText.replaceAll(RegExp(r'[^\d.]'), ''));

          setState(() {
            _distanceText = '$distanceText from warehouse';
            _isLoading = false;
          });

          // Call the callback with the distance
          widget.onDistanceCalculated(distance);
          return;
        }
      }

      // If we reach here, something went wrong
      throw Exception('Unable to calculate road distance');

    } catch (e) {
      setState(() {
        _errorMessage = 'Could not calculate delivery distance';
        _isLoading = false;
      });

      // Callback with infinite distance to indicate error
      widget.onDistanceCalculated(double.infinity);

      // Log the error for debugging
      print('Distance calculation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Text(
          _errorMessage!,
          style: titilliumRegular.copyWith(color: Colors.red)
      );
    }

    return Text(
      _distanceText,
      style: titilliumSemiBold.copyWith(
        fontSize: Dimensions.fontSizeLarge,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}