import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';

class FedExPayloadWidget extends StatelessWidget {
  final Map<String, dynamic> addressDetails;
  final List<CartModel> cartItems;
  final double totalAmount;
  final double tax;
  final double discount;
  final double deliveryFee;
  final double distance;
  final Function(Map<String, dynamic>) onPayloadGenerated;

  const FedExPayloadWidget({
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

  Future<String?> _getFedExToken() async {
    try {
      final response = await http.post(
        Uri.parse('https://apis-sandbox.fedex.com/oauth/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
          'client_id': 'l72a982c357eff42258a4b7b3ada56e11a',
          'client_secret': '1400190376404dd6a35937dd41e4067d',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      }
      return null;
    } catch (e) {
      print('Error getting FedEx token: $e');
      return null;
    }
  }

  Future<void> _generatePayload() async {
    final token = await _getFedExToken();
    if (token == null) return;

    double totalWeight = 0;
    for (var item in cartItems) {
      if (item.quantity != null) {
        totalWeight += (item.quantity ?? 1) * 0.5;
      }
    }

    final payload = {
      "labelResponseOptions": "URL_ONLY",
      "requestedShipment": {
        "shipper": {
          "contact": {
            "personName": "SHIPPER NAME",
            "phoneNumber": 1234567890,
            "companyName": "6Valley"
          },
          "address": {
            "streetLines": ["15 Tideswell Rd"],
            "city": "Sheffield",
            "postalCode": "S5 6QR",
            "countryCode": "GB"
          }
        },
        "recipients": [
          {
            "contact": {
              "personName": addressDetails['contactPersonName'] ?? "",
              "phoneNumber": int.tryParse(addressDetails['phone'] ?? "") ?? 1234567890,
              "companyName": "Recipient Company Name"
            },
            "address": {
              "streetLines": [addressDetails['address'] ?? ""],
              "city": addressDetails['city'] ?? "",
              "postalCode": addressDetails['zipCode'] ?? "",
              "countryCode": "GB"
            }
          }
        ],
        "shipDatestamp": DateTime.now().toIso8601String().split('T')[0],
        "serviceType": "FEDEX_NEXT_DAY_MID_MORNING",
        "packagingType": "FEDEX_PAK",
        "pickupType": "USE_SCHEDULED_PICKUP",
        "blockInsightVisibility": false,
        "shippingChargesPayment": {
          "paymentType": "SENDER"
        },
        "labelSpecification": {
          "imageType": "PDF",
          "labelStockType": "PAPER_85X11_TOP_HALF_LABEL"
        },
        "requestedPackageLineItems": [
          {
            "weight": {
              "value": totalWeight,
              "units": "KG"
            }
          }
        ]
      },
      "accountNumber": {
        "value": "802255209"
      }
    };

    onPayloadGenerated(payload);
  }

  @override
  Widget build(BuildContext context) {
    _generatePayload();
    return const SizedBox.shrink();
  }
}