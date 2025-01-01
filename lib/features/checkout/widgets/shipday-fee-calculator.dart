import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';

class ShipdayFeeCalculator extends StatefulWidget {
  final double distance;
  final List<CartModel> cartList;
  final Function(double fee) onFeeCalculated;

  const ShipdayFeeCalculator({
    Key? key,
    required this.distance,
    required this.cartList,
    required this.onFeeCalculated,
  }) : super(key: key);

  @override
  State<ShipdayFeeCalculator> createState() => _ShipdayFeeCalculatorState();
}

class _ShipdayFeeCalculatorState extends State<ShipdayFeeCalculator> {
  bool _isLoading = false;
  double? _shipdayFee;
  String? _errorMessage;
  double? _lastCalculatedDistance;

  @override
  void initState() {
    super.initState();
    _calculateShipdayFee();
  }

  @override
  void didUpdateWidget(ShipdayFeeCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate fee if distance has changed
    if (oldWidget.distance != widget.distance || _lastCalculatedDistance != widget.distance) {
      _calculateShipdayFee();
    }
  }

  Future<void> _calculateShipdayFee() async {
    try {
      setState(() => _isLoading = false);

      int roundedDistance = widget.distance.round();
      _lastCalculatedDistance = widget.distance;

      print('\n=== Calculating Shipday Fee ===');
      print('Distance: $roundedDistance miles');

      final response = await http.get(
          Uri.parse('https://wholesalepallets.uk/api/get_shipday_rate/$roundedDistance')
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double totalRate = double.parse(data['total_rate'].toString());

        print('Calculated Rate: £$totalRate');
        print('=== End Shipday Fee Calculation ===\n');

        setState(() {
          _shipdayFee = totalRate;
          _isLoading = false;
          _errorMessage = null;
        });

        widget.onFeeCalculated(totalRate);
      } else {
        _handleError('Failed to calculate shipping rate');
      }
    } catch (e) {
      print('Error calculating fee: $e');
      _handleError('Error calculating shipping rate');
    }
  }

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
      //       'Shipday Delivery Fee:',
      //       style: titilliumRegular.copyWith(
      //         fontSize: Dimensions.fontSizeLarge,
      //       ),
      //     ),
      //     Text(
      //       PriceConverter.convertPrice(context, _shipdayFee ?? 0),
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