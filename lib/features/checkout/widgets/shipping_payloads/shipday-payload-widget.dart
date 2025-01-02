import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';

class ShipdayPayloadWidget extends StatelessWidget {
  final Map<String, dynamic> addressDetails;
  final List<CartModel> cartItems;
  final double totalAmount;
  final double tax;
  final double discount;
  final double deliveryFee;
  final double distance;
  final Function(Map<String, dynamic>) onPayloadGenerated;

  const ShipdayPayloadWidget({
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

  Future<void> _generatePayload() async {
    double totalWeight = cartItems.fold(0.0,
            (sum, item) => sum + ((item.quantity ?? 1) * 0.5));

    final payload = {
      "orderNumber": DateTime.now().millisecondsSinceEpoch.toString(),
      "customerName": addressDetails['contactPersonName'] ?? "",
      "customerAddress": {
        "street": addressDetails['address'] ?? "",
        "city": addressDetails['city'] ?? "",
        "zipCode": addressDetails['zipCode'] ?? "",
        "country": "GB"
      },
      "customerPhone": addressDetails['phone'] ?? "",
      "restaurantName": "6Valley",
      "restaurantAddress": {
        "street": "15 Tideswell Rd",
        "city": "Sheffield",
        "zipCode": "S5 6QR",
        "country": "GB"
      },
      "restaurantPhone": "1234567890",
      "expectedDeliveryDate": DateTime.now().toIso8601String().split('T')[0],
      "orderItems": cartItems.map((item) => {
        "name": item.name,
        "quantity": item.quantity ?? 1,
        "unitPrice": item.price,
        "totalWeight": (item.quantity ?? 1) * 0.5
      }).toList(),
      "orderAmount": totalAmount,
      "tax": tax,
      "discount": discount,
      "deliveryFee": deliveryFee,
    };

    onPayloadGenerated(payload);
  }

  @override
  Widget build(BuildContext context) {
    _generatePayload();
    return const SizedBox.shrink();
  }
}