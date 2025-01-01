import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';

class DPDPayloadWidget extends StatelessWidget {
  final Map<String, dynamic> addressDetails;
  final List<CartModel> cartItems;
  final double totalAmount;
  final double tax;
  final double discount;
  final double deliveryFee;
  final double distance;
  final Function(Map<String, dynamic>) onPayloadGenerated;

  const DPDPayloadWidget({
    Key? key,
    required this.addressDetails,
    required this.cartItems,
    required this.totalAmount,
    required this.tax,
    required this.discount,
    required this.deliveryFee,
    required this.distance,
    required this.onPayloadGenerated,
  }) : super(key: key);

  Future<String?> _getDPDGeoSession() async {
    final String _dpdBaseUrl = 'https://api.dpdlocal.co.uk';
    final String _dpdAuthToken = 'Basic cGFsbGV0c3J1czpwYWxsZXRzcnVzMjAyNEA=';

    try {
      final response = await http.post(
          Uri.parse('$_dpdBaseUrl/user/?action=login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': _dpdAuthToken
          }
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['geoSession'];
      }
      return null;
    } catch (e) {
      print('Error getting DPD GeoSession: $e');
      return null;
    }
  }

  Future<void> _generatePayload() async {
    final geoSession = await _getDPDGeoSession();
    if (geoSession == null) return;

    double totalWeight = cartItems.fold(0.0,
            (sum, item) => sum + ((item.quantity ?? 1) * 0.5));

    final payload = {
      "job_id": DateTime.now().millisecondsSinceEpoch.toString(),
      "collectionDetails": {
        "address": {
          "organisation": "6Valley",
          "addressLine1": "15 Tideswell Rd",
          "town": "Sheffield",
          "postcode": "S5 6QR",
          "country": "GB"
        },
        "contactDetails": {
          "contactName": "Store Contact",
          "telephone": "1234567890"
        }
      },
      "deliveryDetails": {
        "address": {
          "organisation": addressDetails['contactPersonName'] ?? "",
          "addressLine1": addressDetails['address'] ?? "",
          "town": addressDetails['city'] ?? "",
          "postcode": addressDetails['zipCode'] ?? "",
          "country": "GB"
        },
        "contactDetails": {
          "contactName": addressDetails['contactPersonName'] ?? "",
          "telephone": addressDetails['phone'] ?? ""
        }
      },
      "collectionDate": DateTime.now().toIso8601String().split('T')[0],
      "numberOfParcels": cartItems.length,
      "totalWeight": totalWeight,
      "serviceCode": "1",
      "totalAmount": totalAmount,
      "shippingAmount": deliveryFee,
      "reference": DateTime.now().millisecondsSinceEpoch.toString(),
      "GeoSession": geoSession
    };

    onPayloadGenerated(payload);
  }

  @override
  Widget build(BuildContext context) {
    _generatePayload();
    return const SizedBox.shrink();
  }
}