import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_payloads/index.dart';

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
  String? _fedExToken;
  String? _dpdGeoSession;
  bool _isPayloadSent = false;

  @override
  void initState() {
    super.initState();
    _initializeTokens();
  }

  Future<void> _initializeTokens() async {
    if (widget.shippingMethod == 'FedEx') {
      _fedExToken = await _getFedExToken();
    } else if (widget.shippingMethod == 'DPD') {
      _dpdGeoSession = await _getDPDGeoSession();
    }
  }

  Future<String?> _getFedExToken() async {
    try {
      final response = await http.post(
        Uri.parse('https://apis-sandbox.fedex.com/oauth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'client_id': 'l72a982c357eff42258a4b7b3ada56e11a',
          'client_secret': '1400190376404dd6a35937dd41e4067d',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['access_token'];
      }
      return null;
    } catch (e) {
      print('Error getting FedEx token: $e');
      return null;
    }
  }

  Future<String?> _getDPDGeoSession() async {
    try {
      final response = await http.post(
          Uri.parse('https://api.dpdlocal.co.uk/user/?action=login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Basic cGFsbGV0c3J1czpwYWxsZXRzcnVzMjAyNEA='
          }
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data']?['geoSession'];
      }
      return null;
    } catch (e) {
      print('Error getting DPD GeoSession: $e');
      return null;
    }
  }

  void _onPayloadGenerated(Map<String, dynamic> payload) {
    setState(() => _shippingPayload = payload);
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
            'Authorization': 'Basic l72a982c357eff42258a4b7b3ada56e11a',
            'Content-Type': 'application/json'
          };
          break;
        case 'FedEx':
          if (_fedExToken == null) return;
          apiUrl = 'https://apis.fedex.com/ship/v1/shipments';
          headers = {
            'Authorization': 'Bearer $_fedExToken',
            'Content-Type': 'application/json'
          };
          break;
        case 'DPD':
          if (_dpdGeoSession == null) return;
          apiUrl = 'https://api.dpdlocal.co.uk/shipping/shipment';
          headers = {
            'Content-Type': 'application/json',
            'GeoSession': _dpdGeoSession!
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
        setState(() => _isPayloadSent = true);
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