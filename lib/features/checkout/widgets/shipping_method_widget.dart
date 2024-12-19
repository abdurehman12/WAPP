import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';

class ShippingMethodWidget extends StatefulWidget {
  final Function(String) onSelect;
  final Map<String, dynamic> deliveryAddress;

  const ShippingMethodWidget({
    Key? key,
    required this.onSelect,
    required this.deliveryAddress,
  }) : super(key: key);

  @override
  ShippingMethodWidgetState createState() => ShippingMethodWidgetState();
}

class ShippingMethodWidgetState extends State<ShippingMethodWidget> {
  String? _selectedMethod;
  bool _showShipday = false;
  bool _isLoading = true;
  String _distanceText = '';
  String? _deliveryTime;
  double? _userLat;
  double? _userLong;
  String? _errorMessage;
  bool _userSelected = false;
  String? _lastCalculatedAddress;

  // Constants
  final double maxShipdayDistance = 40.0;
  final String apiKey = 'AIzaSyBBFIP5MegcM9fM5GsUNueB8oPLuAIrJYc';

  // Warehouse location
  final Map<String, dynamic> warehouse = {
    'latitude': 53.419040,
    'longitude': -1.455223,
    'address': '15 Tideswell Rd, Sheffield S5 6QR, UK'
  };

  @override
  void initState() {
    super.initState();
    _initializeDistance();
  }

  @override
  void didUpdateWidget(ShippingMethodWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deliveryAddress != widget.deliveryAddress) {
      String newAddressKey = '${widget.deliveryAddress['address']}_${widget.deliveryAddress['zipCode']}';
      if (_lastCalculatedAddress != newAddressKey) {
        _lastCalculatedAddress = newAddressKey;
        _initializeDistance();
      }
    }
  }

  void _recalculateShippingFee() {
    if (!mounted) return;

    final checkoutProvider = Provider.of<CheckoutController>(context, listen: false);

    // Only calculate if we have valid coordinates
    if (_userLat == null || _userLong == null) return;

    final distance = _calculateHaversineDistance(
      lat1: warehouse['latitude'],
      lon1: warehouse['longitude'],
      lat2: _userLat!,
      lon2: _userLong!,
    );

    final enrichedAddressDetails = {
      ...widget.deliveryAddress,
      'calculatedLatitude': _userLat.toString(),
      'calculatedLongitude': _userLong.toString(),
      'distance': distance.toString(),
    };

    print('Recalculating shipping fee for distance: $distance miles');

    if (_selectedMethod == 'FedEx') {
      checkoutProvider.calculateFedExFee(
        addressDetails: enrichedAddressDetails,
        cartList: Provider.of<CartController>(context, listen: false).cartList,
      );
    } else if (_selectedMethod == 'Shipday') {
      checkoutProvider.calculateShipdayFee(
        addressDetails: enrichedAddressDetails,
        cartList: Provider.of<CartController>(context, listen: false).cartList,
      );
    }
  }

  void _initializeDistance() async {
    if (_isValidAddress(widget.deliveryAddress)) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _calculateDistance();

      if (_selectedMethod != null && mounted) {
        _recalculateShippingFee();
      }
    }
  }

  bool _isValidAddress(Map<String, dynamic> address) {
    return (address['address']?.isNotEmpty ?? false) &&
        (address['zipCode']?.isNotEmpty ?? false);
  }

  String _formatAddress(Map<String, dynamic> address) {
    return '${address['address']}, ${address['city'] ?? ''}, ${address['zipCode'] ?? ''}, UK'
        .replaceAll(RegExp(r',\s*,'), ',')
        .replaceAll(RegExp(r',\s*$'), '');
  }

  Future<void> _calculateDistance() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final formattedAddress = _formatAddress(widget.deliveryAddress);
      print('Getting coordinates for address: $formattedAddress');

      final coordinates = await _getCoordinatesFromAddress(formattedAddress);

      if (coordinates == null) {
        throw Exception('Could not determine coordinates for the address');
      }

      _userLat = coordinates['lat'];
      _userLong = coordinates['lng'];
      print('Got coordinates: $_userLat, $_userLong');

      final distance = _calculateHaversineDistance(
        lat1: warehouse['latitude'],
        lon1: warehouse['longitude'],
        lat2: _userLat!,
        lon2: _userLong!,
      );

      print('Calculated distance: $distance miles');

      final estimatedMinutes = (distance / 20 * 60).round();

      if (!mounted) return;

      setState(() {
        _distanceText = '${distance.toStringAsFixed(1)} miles';
        _showShipday = distance <= maxShipdayDistance;
        _deliveryTime = '$estimatedMinutes minutes';

        // Only set default method if user hasn't made a selection
        if (!_userSelected) {
          _selectedMethod = _showShipday ? 'Shipday' : 'FedEx';
          widget.onSelect(_selectedMethod!);

          // Calculate FedEx fee if it's selected by default
          if (_selectedMethod == 'FedEx') {
            _calculateFedExFee();
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error in calculateDistance: $e');
      if (!mounted) return;

      setState(() {
        _showShipday = false;
        if (!_userSelected) {
          _selectedMethod = 'FedEx';
          widget.onSelect('FedEx');
          _calculateFedExFee();
        }
        _distanceText = 'Could not calculate distance';
        _errorMessage = 'Could not calculate delivery distance';
        _isLoading = false;
      });
    }
  }

  void _calculateFedExFee() {
    Provider.of<CheckoutController>(context, listen: false).calculateFedExFee(
      addressDetails: widget.deliveryAddress,
      cartList: Provider.of<CartController>(context, listen: false).cartList,
    );
  }

  Future<Map<String, double>?> _getCoordinatesFromAddress(String address) async {
    try {
      final String encodedAddress = Uri.encodeComponent(address);
      final String url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey&region=uk';

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        return {
          'lat': location['lat'],
          'lng': location['lng'],
        };
      }
      print('Geocoding failed: ${data['status']}');
      return null;
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }

  double _calculateHaversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 3958.8; // miles

    final double lat1Rad = _degreesToRadians(lat1);
    final double lon1Rad = _degreesToRadians(lon1);
    final double lat2Rad = _degreesToRadians(lat2);
    final double lon2Rad = _degreesToRadians(lon2);

    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
            sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return double.parse((earthRadius * c).toStringAsFixed(1));
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180.0);

  void _onShippingMethodSelected(String? value) {
    setState(() {
      _selectedMethod = value;
      _userSelected = true;
    });

    if (value != null) {
      final distance = _calculateHaversineDistance(
        lat1: warehouse['latitude'],
        lon1: warehouse['longitude'],
        lat2: _userLat!,
        lon2: _userLong!,
      );

      final enrichedAddressDetails = {
        ...widget.deliveryAddress,
        'calculatedLatitude': _userLat.toString(),
        'calculatedLongitude': _userLong.toString(),
        'distance': distance.toString(),
      };

      widget.onSelect(value);

      if (value == 'FedEx') {
        Provider.of<CheckoutController>(context, listen: false).calculateFedExFee(
          addressDetails: enrichedAddressDetails,
          cartList: Provider.of<CartController>(context, listen: false).cartList,
        );
      } else if (value == 'Shipday') {
        Provider.of<CheckoutController>(context, listen: false).calculateShipdayFee(
          addressDetails: enrichedAddressDetails,
          cartList: Provider.of<CartController>(context, listen: false).cartList,
        );
      } else if (value == 'DPD') {
        Provider.of<CheckoutController>(context, listen: false).calculateDPDFee(
          addressDetails: enrichedAddressDetails,
          cartList: Provider.of<CartController>(context, listen: false).cartList,
        );
      }
    }
  }

  Widget _buildShippingMethods() {
    return Column(
      children: [
        if (_showShipday)
          ListTile(
            title: const Text('Shipday'),
            subtitle: Text('Fast local delivery (within 40 miles)'),
            leading: Radio<String>(
              value: 'Shipday',
              groupValue: _selectedMethod,
              onChanged: _onShippingMethodSelected,
              activeColor: Theme.of(context).primaryColor,
            ),
          ),

        // Add DPD option here, between Shipday and FedEx
        ListTile(
          title: const Text('DPD'),
          subtitle: Row(
            children: [
              Text('Next Day Delivery'),
              if (_selectedMethod == 'DPD')
                Consumer<CheckoutController>(
                  builder: (context, controller, _) {
                    if (controller.isCalculatingFee) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      );
                    }
                    if (controller.dpdShippingFee > 0) {
                      return Text(
                        '  ${PriceConverter.convertPrice(context, controller.dpdShippingFee)}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
          leading: Radio<String>(
            value: 'DPD',
            groupValue: _selectedMethod,
            onChanged: _onShippingMethodSelected,
            activeColor: Theme.of(context).primaryColor,
          ),
        ),

        ListTile(
          title: const Text('FedEx'),
          subtitle: Row(
            children: [
              Text(_showShipday ? 'Standard shipping' : ''),
              if (_selectedMethod == 'FedEx')
                Consumer<CheckoutController>(
                  builder: (context, controller, _) {
                    if (controller.isCalculatingFee) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      );
                    }
                    if (controller.fedExShippingFee > 0) {
                      return Text(
                        '  ${PriceConverter.convertPrice(context, controller.fedExShippingFee)}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
          leading: Radio<String>(
            value: 'FedEx',
            groupValue: _selectedMethod,
            onChanged: _onShippingMethodSelected,
            activeColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildShipdayDetails() {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidAddress(widget.deliveryAddress)) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            children: [
              Text(
                'Calculating delivery options...',
                style: titilliumRegular,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Shipping Method',
                  style: titilliumSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _buildShippingMethods(),
            if (_showShipday && _selectedMethod == 'Shipday')
              _buildShipdayDetails(),
          ],
        ),
      ),
    );
  }
}