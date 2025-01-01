import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';

class DPDFeeCalculator extends StatefulWidget {
  final double distance;
  final List<CartModel> cartList;
  final Function(double fee) onFeeCalculated;
  final Map<String, dynamic> deliveryAddress;

  const DPDFeeCalculator({
    Key? key,
    required this.distance,
    required this.cartList,
    required this.onFeeCalculated,
    required this.deliveryAddress,
  }) : super(key: key);

  @override
  State<DPDFeeCalculator> createState() => _DPDFeeCalculatorState();
}

class _DPDFeeCalculatorState extends State<DPDFeeCalculator> {
  bool _isLoading = false;
  double? _dpdFee;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _calculateDPDFee();
  }

  Future<void> _calculateDPDFee() async {
    try {
      setState(() => _isLoading = false);

      // Calculate total weight
      double totalWeight = 0;
      print('\n=== Calculating DPD Fee ===');
      for (var item in widget.cartList) {
        double itemWeight = (item.quantity ?? 1) * 0.5; // Default weight 0.5kg per item
        totalWeight += itemWeight;
        print('Item: ${item.name}');
        print('  Quantity: ${item.quantity}');
        print('  Weight: ${itemWeight}kg');
      }
      int roundedWeight = totalWeight.round();
      print('Total Order Weight: $roundedWeight kg');

      final response = await http.get(
        Uri.parse('https://wholesalepallets.uk/api/dpd_rate/$roundedWeight'),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        double totalRate;

        // Handle different response types
        if (data is Map<String, dynamic>) {
          totalRate = double.parse(data['total_rate'].toString());
        } else if (data is double) {
          totalRate = data;
        } else if (data is String) {
          totalRate = double.parse(data);
        } else {
          throw FormatException("Unexpected response type");
        }

        print('Final Rate: £$totalRate');
        print('=== End DPD Fee Calculation ===\n');

        setState(() {
          _dpdFee = totalRate;
          _isLoading = false;
          _errorMessage = null;
        });

        widget.onFeeCalculated(totalRate);
      } else {
        print('API Error: Failed to get rate');
        print('=== End DPD Fee Calculation ===\n');
        // _calculateFallbackRate();
      }
    } catch (e) {
      print('Error calculating fee: $e');
      print('=== End DPD Fee Calculation ===\n');
      // _calculateFallbackRate();
    }
  }



  // void _calculateFallbackRate() {
  //   double baseRate = 12.00;
  //   double finalRate;
  //
  //   if (widget.distance <= 20) {
  //     finalRate = baseRate + 15.30;
  //   } else if (widget.distance <= 40) {
  //     finalRate = baseRate + 20.30;
  //   } else if (widget.distance <= 60) {
  //     finalRate = baseRate + 25.30;
  //   } else {
  //     double extraMiles = widget.distance - 60;
  //     finalRate = baseRate + 25.30 + (extraMiles * 0.45);
  //   }
  //
  //   setState(() {
  //     _dpdFee = finalRate;
  //     _isLoading = false;
  //     _errorMessage = null;
  //   });
  //
  //   widget.onFeeCalculated(finalRate);
  // }

  void _handleError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
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
        child: Text(
          _errorMessage!,
          style: titilliumRegular.copyWith(color: Colors.red),
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
      //       'DPD Delivery Fee:',
      //       style: titilliumRegular.copyWith(
      //         fontSize: Dimensions.fontSizeLarge,
      //       ),
      //     ),
      //     Text(
      //       PriceConverter.convertPrice(context, _dpdFee ?? 0),
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
