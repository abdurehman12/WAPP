import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';

class ShipdayPayloadWidget extends StatefulWidget {
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

  @override
  _ShipdayPayloadWidgetState createState() => _ShipdayPayloadWidgetState();
}

class _ShipdayPayloadWidgetState extends State<ShipdayPayloadWidget> {
  @override
  void initState() {
    super.initState();
    _generatePayload();
  }

  void _generatePayload() {
    final now = DateTime.now();
    final deliveryDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final pickupTime = now;
    final deliveryTime = now.add(Duration(hours: 2));

    final payload = {
      'orderNumber': 'SHIP${DateTime.now().millisecondsSinceEpoch}',
      'customerName': widget.addressDetails['contactPersonName'] ?? 'Customer',
      'customerAddress': widget.addressDetails['address'] ?? '',
      'customerEmail': widget.addressDetails['email'] ?? '',
      'customerPhoneNumber': widget.addressDetails['phone'] ?? '',
      'restaurantName': '6Valley',
      'restaurantAddress': '15 Tideswell Rd, Sheffield S5 6QR, UK',
      'restaurantPhoneNumber': '+44 0000 000000',
      'expectedDeliveryDate': deliveryDate,
      'pickupLatitude': 53.419040,
      'pickupLongitude': -1.455223,
      'deliveryLatitude': double.tryParse(widget.addressDetails['calculatedLatitude']?.toString() ?? '') ?? 53.5228957,
      'deliveryLongitude': double.tryParse(widget.addressDetails['calculatedLongitude']?.toString() ?? '') ?? -1.1338375,
      'distance': widget.distance,
      'orderItems': widget.cartItems.map((item) => {
        'name': item.name ?? 'Product',
        'unitPrice': (item.price ?? 0).toDouble(),
        'quantity': item.quantity ?? 1,
      }).toList(),
      'tax': widget.tax,
      'discountAmount': widget.discount,
      'deliveryFee': widget.deliveryFee.toString(),
      'totalOrderCost': widget.totalAmount,
      'orderSource': 'Meghra Market App',
      'paymentMethod': 'COD',
    };

    widget.onPayloadGenerated(payload);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
