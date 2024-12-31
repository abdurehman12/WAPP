import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_payloads/shipday-payload-widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_payloads/dpd-payload-widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_payloads/fedex-payload-widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class ShippingPayloadIntegrator extends StatefulWidget {
  final String shippingMethod;
  final Map<String, dynamic> addressDetails;
  final List<CartModel> cartItems;
  final double totalAmount;
  final double tax;
  final double discount;
  final double deliveryFee;
  final double distance;
  final String orderId;
  final VoidCallback onPayloadSent;

  const ShippingPayloadIntegrator({
    Key? key,
    required this.shippingMethod,
    required this.addressDetails,
    required this.cartItems,
    required this.totalAmount,
    required this.tax,
    required this.discount,
    required this.deliveryFee,
    required this.distance,
    required this.orderId,
    required this.onPayloadSent,
  }) : super(key: key);

  @override
  _ShippingPayloadIntegratorState createState() => _ShippingPayloadIntegratorState();
}

class _ShippingPayloadIntegratorState extends State<ShippingPayloadIntegrator> {
  Map<String, dynamic>? _shippingPayload;
  bool _isPayloadSent = false;

  void _onPayloadGenerated(Map<String, dynamic> payload) {
    setState(() {
      _shippingPayload = payload;
    });
    _sendShippingPayload();
  }

  Future<void> _sendShippingPayload() async {
    if (_isPayloadSent || _shippingPayload == null) return;

    try {
      late String apiUrl;
      late Map<String, String> headers;

      switch (widget.shippingMethod) {
        case 'Shipday':
          apiUrl = 'https://api.shipday.com/orders';
          headers = {
            'Authorization': 'Basic ${AppConstants.SHIPDAY_API_KEY}',
            'Content-Type': 'application/json'
          };
          break;
        case 'FedEx':
          apiUrl = 'https://apis.fedex.com/ship/v1/shipments';
          headers = {
            'Authorization': 'Bearer ${AppConstants.FEDEX_ACCESS_TOKEN}',
            'Content-Type': 'application/json'
          };
          break;
        case 'DPD':
          apiUrl = 'https://api.dpdlocal.co.uk/shipping/shipment';
          headers = {
            'Content-Type': 'application/json',
            'GeoSession': AppConstants.DPD_GEOSESSION
          };
          break;
        default:
          return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(_shippingPayload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isPayloadSent = true;
        });
        widget.onPayloadSent();
      }
    } catch (e) {
      print('Shipping payload error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Select payload widget based on shipping method
        if (widget.shippingMethod == 'Shipday')
          ShipdayPayloadWidget(
            addressDetails: widget.addressDetails,
            cartItems: widget.cartItems,
            totalAmount: widget.totalAmount,
            tax: widget.tax,
            discount: widget.discount,
            deliveryFee: widget.deliveryFee,
            distance: widget.distance,
            onPayloadGenerated: _onPayloadGenerated,
          )
        else if (widget.shippingMethod == 'FedEx')
          FedExPayloadWidget(
            addressDetails: widget.addressDetails,
            cartItems: widget.cartItems,
            totalAmount: widget.totalAmount,
            tax: widget.tax,
            discount: widget.discount,
            deliveryFee: widget.deliveryFee,
            distance: widget.distance,
            onPayloadGenerated: _onPayloadGenerated,
          )
        else if (widget.shippingMethod == 'DPD')
          DPDPayloadWidget(
            addressDetails: widget.addressDetails,
            cartItems: widget.cartItems,
            totalAmount: widget.totalAmount,
            tax: widget.tax,
            discount: widget.discount,
            deliveryFee: widget.deliveryFee,
            distance: widget.distance,
            onPayloadGenerated: _onPayloadGenerated,
          ),
      ],
    );
  }
}
