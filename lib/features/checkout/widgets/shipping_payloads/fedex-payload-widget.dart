import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';

class FedExPayloadWidget extends StatefulWidget {
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

  @override
  _FedExPayloadWidgetState createState() => _FedExPayloadWidgetState();
}

class _FedExPayloadWidgetState extends State<FedExPayloadWidget> {
  @override
  void initState() {
    super.initState();
    _generatePayload();
  }

  void _generatePayload() {
    double totalWeight = 0;
    for (var item in widget.cartItems) {
      totalWeight += (item.weight ?? 0.5) * (item.quantity ?? 1);
    }

    final payload = {
      'requestedShipment': {
        'shipper': {
          'contact': {
            'companyName': '6Valley',
            'phoneNumber': '+44 0000 000000'
          },
          'address': {
            'streetLines': ['15 Tideswell Rd'],
            'city': 'Sheffield',
            'postalCode': 'S5 6QR',
            'countryCode': 'GB'
          }
        },
        'recipients': [
          {
            'contact': {
              'personName': widget.addressDetails['contactPersonName'] ?? 'Recipient',
              'phoneNumber': widget.addressDetails['phone'] ?? '',
              'emailAddress': widget.addressDetails['email'] ?? '',
            },
            'address': {
              'streetLines': [widget.addressDetails['address'] ?? ''],
              'city': widget.addressDetails['city'] ?? '',
              'postalCode': widget.addressDetails['zipCode'] ?? '',
              'countryCode': 'GB'
            }
          }
        ],
        'serviceType': 'FEDEX_NEXT_DAY_MID_MORNING',
        'packagingType': 'FEDEX_PAK',
        'requestedPackageLineItems': [
          {
            'weight': {
              'value': totalWeight,
              'units': 'KG'
            }
          }
        ],
        'customerReferences': [
          {
            'customerReferenceType': 'CUSTOMER_REFERENCE',
            'value': 'FDX${DateTime.now().millisecondsSinceEpoch}'
          }
        ]
      },
      'additionalMetadata': {
        'totalOrderCost': widget.totalAmount,
        'tax': widget.tax,
        'discount': widget.discount,
        'deliveryFee': widget.deliveryFee,
        'distance': widget.distance
      }
    };

    widget.onPayloadGenerated(payload);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
