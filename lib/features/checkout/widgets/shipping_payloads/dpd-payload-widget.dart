import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';

class DPDPayloadWidget extends StatefulWidget {
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

  @override
  _DPDPayloadWidgetState createState() => _DPDPayloadWidgetState();
}

class _DPDPayloadWidgetState extends State<DPDPayloadWidget> {
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
      'consignment': [
        {
          'consignmentRef': 'DPD${DateTime.now().millisecondsSinceEpoch}',
          'parcel': [
            {
              'packageNumber': 1,
              'parcelProduct': widget.cartItems.map((item) => {
                'productCode': item.id.toString(),
                'productTypeDescription': item.name,
                'productItemsDescription': item.name,
                'unitWeight': item.weight ?? 0.5,
                'numberOfItems': item.quantity ?? 1,
                'unitValue': item.price ?? 0,
              }).toList()
            }
          ],
          'collectionDetails': {
            'contactDetails': {
              'contactName': '6Valley Shipper',
              'telephone': '+44 0000 000000'
            },
            'address': {
              'organisation': '6Valley',
              'countryCode': 'GB',
              'postcode': 'S5 6QR',
              'street': '15 Tideswell Rd',
              'town': 'Sheffield'
            }
          },
          'deliveryDetails': {
            'contactDetails': {
              'contactName': widget.addressDetails['contactPersonName'] ?? 'Recipient',
              'telephone': widget.addressDetails['phone'] ?? ''
            },
            'address': {
              'organisation': widget.addressDetails['contactPersonName'] ?? 'Recipient',
              'countryCode': 'GB',
              'postcode': widget.addressDetails['zipCode'] ?? '',
              'street': widget.addressDetails['address'] ?? '',
              'town': widget.addressDetails['city'] ?? ''
            }
          },
          'totalWeight': totalWeight,
        }
      ],
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
