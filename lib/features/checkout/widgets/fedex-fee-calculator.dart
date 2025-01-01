import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';

class FedExFeeCalculator extends StatefulWidget {
  final double distance;
  final List<CartModel> cartList;
  final Function(double fee) onFeeCalculated;
  final Map<String, dynamic> deliveryAddress;

  const FedExFeeCalculator({
    Key? key,
    required this.distance,
    required this.cartList,
    required this.onFeeCalculated,
    required this.deliveryAddress,
  }) : super(key: key);

  @override
  State<FedExFeeCalculator> createState() => _FedExFeeCalculatorState();
}

class _FedExFeeCalculatorState extends State<FedExFeeCalculator> {
  bool _isLoading = true;
  double? _fedExFee;
  String? _errorMessage;
  bool _isCalculating = false;
  String? _lastCalculatedAddress;

  final String _fedExAuthUrl = 'https://apis-sandbox.fedex.com/oauth/token';
  final String _fedExShipUrl = 'https://apis-sandbox.fedex.com/ship/v1/shipments';
  final String _fedExClientId = 'l72a982c357eff42258a4b7b3ada56e11a';
  final String _fedExClientSecret = '1400190376404dd6a35937dd41e4067d';
  final String _fedExAccountNumber = '802255209';

  @override
  void initState() {
    super.initState();
    _calculateFedExFee();
  }

  @override
  void didUpdateWidget(FedExFeeCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);

    String currentAddressKey = '${widget.deliveryAddress['address']}_${widget.deliveryAddress['zipCode']}';

    if (!_isCalculating && currentAddressKey != _lastCalculatedAddress) {
      _lastCalculatedAddress = currentAddressKey;
      _calculateFedExFee();
    }
  }

  Future<String?> _getFedExToken() async {
    try {
      final response = await http.post(
        Uri.parse(_fedExAuthUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
          'client_id': _fedExClientId,
          'client_secret': _fedExClientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      }
      print('FedEx auth error: ${response.body}');
      return null;
    } catch (e) {
      print('Error getting FedEx token: $e');
      return null;
    }
  }

  Future<void> _calculateFedExFee() async {
    if (_isCalculating) return;

    try {
      _isCalculating = true;
      setState(() => _isLoading = true);

      final token = await _getFedExToken();
      if (token == null) {
        print('Failed to get FedEx token, using fallback rate');
        // _calculateFallbackRate();
        return;
      }

      double totalWeight = 0;
      print('\n=== Calculating FedEx Fee ===');
      print('Distance: ${widget.distance} miles');
      for (var item in widget.cartList) {
        double itemWeight = (item.quantity ?? 1) * 0.5;
        totalWeight += itemWeight;
        print('Item: ${item.name}, Quantity: ${item.quantity}, Weight: ${itemWeight}kg');
      }
      print('Total Order Weight: ${totalWeight}kg');

      final rateRequest = {
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
                "personName": widget.deliveryAddress['contactPersonName'] ?? "RECIPIENT NAME",
                "phoneNumber": int.tryParse(widget.deliveryAddress['phone'] ?? "") ?? 1234567890,
                "companyName": "Recipient Company Name"
              },
              "address": {
                "streetLines": [widget.deliveryAddress['address'] ?? ""],
                "city": widget.deliveryAddress['city'] ?? "",
                "postalCode": widget.deliveryAddress['zipCode'] ?? "",
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
          "value": _fedExAccountNumber
        }
      };

      print('Sending FedEx rate request: ${jsonEncode(rateRequest)}');

      final response = await http.post(
        Uri.parse(_fedExShipUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(rateRequest),
      );

      print('FedEx API Response Status: ${response.statusCode}');
      print('FedEx API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          final shipmentDetails = data['output']['transactionShipments'][0];
          final rateDetails = shipmentDetails['completedShipmentDetail']['shipmentRating']
          ['shipmentRateDetails'][0];

          double totalRate = double.parse(rateDetails['totalNetCharge'].toString());

          print('Base Rate: £$totalRate');
          print('Final Rate: £$totalRate');
          print('=== End FedEx Fee Calculation ===\n');

          setState(() {
            _fedExFee = totalRate;
            _isLoading = false;
            _errorMessage = null;
          });

          widget.onFeeCalculated(totalRate);
        } catch (e) {
          print('Error parsing rate from response: $e');
          // _calculateFallbackRate();
        }
      } else {
        print('API Error: Failed to get rate');
      }
    } catch (e) {
      print('Error calculating FedEx fee: $e');
    } finally {
      _isCalculating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Text(_errorMessage!,
            style: titilliumRegular.copyWith(color: Colors.red)
        ),
      );
    }

    return Container(
      // margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      // padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      // decoration: BoxDecoration(
      //   color: Theme.of(context).cardColor,
      //   borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
      //   border: Border.all(
      //     color: Theme.of(context).primaryColor.withOpacity(0.2),
      //   ),
      // ),
      // child: Row(
      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //   children: [
      //     Text(
      //       'FedEx Delivery Fee:',
      //       style: titilliumRegular.copyWith(
      //         fontSize: Dimensions.fontSizeLarge,
      //       ),
      //     ),
      //     Text(
      //       PriceConverter.convertPrice(context, _fedExFee ?? 0),
      //       style: titilliumSemiBold.copyWith(
      //         color: Theme.of(context).primaryColor,
      //         fontSize: Dimensions.fontSizeLarge,
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}