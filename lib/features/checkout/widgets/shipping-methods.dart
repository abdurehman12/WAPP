import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/distance-calculator.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipday-fee-calculator.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/dpd-fee-calculator.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/fedex-fee-calculator.dart';

class ShippingMethodsWidget extends StatefulWidget {
  final Map<String, dynamic> deliveryAddress;

  const ShippingMethodsWidget({
    Key? key,
    required this.deliveryAddress,
  }) : super(key: key);

  @override
  State<ShippingMethodsWidget> createState() => _ShippingMethodsWidgetState();
}

class _ShippingMethodsWidgetState extends State<ShippingMethodsWidget> {
  String? _selectedMethod;
  double? _calculatedDistance;
  static const double MAX_LOCAL_DISTANCE = 40.0;

  bool get hasValidAddress {
    return widget.deliveryAddress['address'] != null &&
        widget.deliveryAddress['address'].toString().isNotEmpty &&
        widget.deliveryAddress['city'] != null &&
        widget.deliveryAddress['city'].toString().isNotEmpty &&
        widget.deliveryAddress['zipCode'] != null &&
        widget.deliveryAddress['zipCode'].toString().isNotEmpty;
  }

  void _onDistanceCalculated(double distance) {
    if (mounted) {
      setState(() {
        _calculatedDistance = distance;
        // Only set default method if user hasn't made a selection yet
        if (_selectedMethod == null) {
          _selectedMethod = distance <= MAX_LOCAL_DISTANCE ? 'Shipday' : 'FedEx';
          // Update controller with default selection
          Provider.of<CheckoutController>(context, listen: false)
              .setShippingMethod(_selectedMethod!);
        }
      });
    }
  }

  void _selectShippingMethod(String? value) {
    if (value != null) {
      setState(() => _selectedMethod = value);
      Provider.of<CheckoutController>(context, listen: false)
          .setShippingMethod(value);

      // Reset shipping fee when changing methods
      Provider.of<CheckoutController>(context, listen: false)
          .setShippingFee(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasValidAddress) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Shipping Method',
                style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'Please select a delivery address to view available shipping methods',
                style: titilliumRegular.copyWith(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Distance Calculator
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: DistanceCalculatorWidget(
                deliveryAddress: widget.deliveryAddress,
                onDistanceCalculated: _onDistanceCalculated,
              ),
            ),

            if (_calculatedDistance != null) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Text(
                'Select Shipping Method',
                style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Show Shipday for local delivery
              if (_calculatedDistance! <= MAX_LOCAL_DISTANCE) ...[
                _buildMethodTile(
                  'Shipday',
                  'Same Day Local Delivery',
                  const Icon(Icons.local_shipping, color: Colors.green),
                ),
                if (_selectedMethod == 'Shipday')
                  Consumer<CartController>(
                    builder: (context, cartController, _) {
                      return ShipdayFeeCalculator(
                        distance: _calculatedDistance!,
                        cartList: cartController.cartList,
                        onFeeCalculated: (fee) {
                          Provider.of<CheckoutController>(context, listen: false)
                              .setShippingFee(fee);
                        },
                      );
                    },
                  ),
              ],

              // Always show DPD
              _buildMethodTile(
                'DPD',
                'Next Day Delivery',
                const Icon(Icons.local_shipping, color: Colors.blue),
              ),

              if (_selectedMethod == 'DPD')
                Consumer<CartController>(
                  builder: (context, cartController, _) {
                    return DPDFeeCalculator(
                      distance: _calculatedDistance!,
                      cartList: cartController.cartList,
                      deliveryAddress: widget.deliveryAddress,
                      onFeeCalculated: (fee) {
                        Provider.of<CheckoutController>(context, listen: false)
                            .setShippingFee(fee);
                      },
                    );
                  },
                ),

              // Always show FedEx
              _buildMethodTile(
                'FedEx',
                'Standard Delivery',
                const Icon(Icons.local_shipping, color: Colors.purple),
              ),

              // Add FedEx Fee Calculator
              if (_selectedMethod == 'FedEx')
                Consumer<CartController>(
                  builder: (context, cartController, _) {
                    return FedExFeeCalculator(
                      distance: _calculatedDistance!,
                      cartList: cartController.cartList,
                      deliveryAddress: widget.deliveryAddress,
                      onFeeCalculated: (fee) {
                        Provider.of<CheckoutController>(context, listen: false)
                            .setShippingFee(fee);
                      },
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile(String value, String subtitle, Icon icon) {
    return ListTile(
      title: Text(value),
      subtitle: Text(subtitle),
      leading: Radio<String>(
        value: value,
        groupValue: _selectedMethod,
        onChanged: _selectShippingMethod,
        activeColor: Theme.of(context).primaryColor,
      ),
      trailing: icon,
    );
  }
}