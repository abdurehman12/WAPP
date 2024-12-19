import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/repositories/checkout_repository_interface.dart';

class CheckoutService implements CheckoutServiceInterface {
  final CheckoutRepositoryInterface checkoutRepositoryInterface;
  final Map<String, double> _distanceCache = {};

  // Warehouse coordinates for both shipping methods
  static const Map<String, double> warehouseCoordinates = {
    'latitude': 53.419040,
    'longitude': -1.455223,
  };

  // API Keys and credentials
  static const String _shipdayApiKey = 'Oaj5nUFMVE.zK5yu1mbsNBy1FYCA1Uf';
  static const String _fedExClientId = 'l72a982c357eff42258a4b7b3ada56e11a';
  static const String _fedExClientSecret = '1400190376404dd6a35937dd41e4067d';
  static const String _fedExAccountNumber = '802255209';

  // API endpoints
  static const String _shipdayBaseUrl = 'https://api.shipday.com/orders';
  static const String _fedExAuthUrl = 'https://apis-sandbox.fedex.com/oauth/token';
  static const String _fedExShipUrl = 'https://apis-sandbox.fedex.com/ship/v1/shipments';
  // static const String _fedExRateUrl = 'https://apis-sandbox.fedex.com/rate/v1/rates/quotes';

  // FedEx token management
  String? _fedExAccessToken;
  DateTime? _tokenExpiryTime;

  // Update DPD constants
  static const String _dpdBaseUrl = 'https://api.dpdlocal.co.uk';
  static const String _dpdAuthToken = 'Basic cGFsbGV0c3J1czpwYWxsZXRzcnVzMjAyNEA=';
  String? _dpdGeoSession;
  DateTime? _dpdTokenExpiryTime;

  CheckoutService({required this.checkoutRepositoryInterface});

  // Utility methods
  double _calculateHaversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {

    // Create a cache key
    String cacheKey = '$lat1,$lon1,$lat2,$lon2';

    // Check if distance is already calculated
    if (_distanceCache.containsKey(cacheKey)) {
      return _distanceCache[cacheKey]!;
    }

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

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00";
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180.0);

  // FedEx authentication
  Future<String?> _getFedExToken() async {
    try {
      if (_fedExAccessToken != null && _tokenExpiryTime != null &&
          DateTime.now().isBefore(_tokenExpiryTime!)) {
        return _fedExAccessToken;
      }

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
        _fedExAccessToken = data['access_token'];
        _tokenExpiryTime = DateTime.now().add(Duration(seconds: data['expires_in'] ?? 3600));
        return _fedExAccessToken;
      }
      print('FedEx auth error: ${response.body}');
      return null;
    } catch (e) {
      print('Error getting FedEx token: $e');
      return null;
    }
  }

  // Rate calculation methods
  Future<double> calculateShippingRate({
    required Map<String, dynamic> addressDetails,
    required List<CartModel> cartList,
    required String shippingMethod,
  }) async {
    try {
      final deliveryLatitude = double.tryParse(addressDetails['calculatedLatitude']?.toString() ?? '') ?? 53.5228957;
      final deliveryLongitude = double.tryParse(addressDetails['calculatedLongitude']?.toString() ?? '') ?? -1.1338375;

      final distance = _calculateHaversineDistance(
        lat1: warehouseCoordinates['latitude']!,
        lon1: warehouseCoordinates['longitude']!,
        lat2: deliveryLatitude,
        lon2: deliveryLongitude,
      );

      print('Distance used for rate calculation: $distance miles');

      if (shippingMethod == 'Shipday') {
        return _calculateShipdayRate(distance, cartList);
      } else if (shippingMethod == 'FedEx') {
        return _calculateFedExRate(distance, cartList, addressDetails);
      }
      return 0.0;
    } catch (e) {
      print('Error calculating shipping rate: $e');
      return 0.0;
    }
  }

  Future<double> _calculateShipdayRate(double distance, List<CartModel> cartList) async {
    try {
      // Round distance to nearest mile
      int roundedDistance = distance.round();
      print('\n=== Shipday Rate Calculation ===');
      print('Calculating rate for distance: $roundedDistance miles');

      try {
        final response = await http.get(
            Uri.parse('https://wholesalepallets.uk/api/get_shipday_rate/$roundedDistance')
        );

        print('API Response Status: ${response.statusCode}');
        print('API Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Parse the response values
          double maxDistance = double.parse(data['max_distance'].toString());
          double totalDistance = double.parse(data['total_distance'].toString());
          double totalRate = double.parse(data['total_rate'].toString());
          double fixDistance = double.parse(data['fix_distance'].toString());
          double fixDistanceRate = double.parse(data['fix_distance_rate'].toString());
          double intervalDistance = double.parse(data['interval_distance'].toString());
          double intervalRate = double.parse(data['interval_rate'].toString());

          print('Parsed API Response:');
          print('Max Distance: $maxDistance miles');
          print('Total Distance: $totalDistance miles');
          print('Total Rate: £$totalRate');
          print('Fix Distance: $fixDistance miles');
          print('Fix Distance Rate: £$fixDistanceRate');
          print('Interval Distance: $intervalDistance mile');
          print('Interval Rate: £$intervalRate per mile');

          print('=== End Shipday Rate Calculation ===\n');
          return totalRate;
        } else {
          print('Error: Failed to get rate from API');
          print('=== End Shipday Rate Calculation ===\n');
          return 0.0;
        }
      } catch (e) {
        print('API Error: $e');
        print('=== End Shipday Rate Calculation ===\n');
        return 0.0;
      }
    } catch (e) {
      print('Error in Shipday rate calculation: $e');
      return 0.0;
    }
  }

  Future<double> _calculateFedExRate(
      double distance,
      List<CartModel> cartList,
      Map<String, dynamic> addressDetails
      ) async {
    try {
      final token = await _getFedExToken();
      if (token == null) {
        print('Failed to get FedEx token, using fallback rate');
        return _calculateFallbackRate(distance, cartList);
      }

      double totalWeight = 0;
      for (var item in cartList) {
        totalWeight += (item.weight ?? 0.5) * (item.quantity ?? 1);
      }

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
                "personName": addressDetails['contactPersonName'] ?? "RECIPIENT NAME",
                "phoneNumber": int.tryParse(addressDetails['phone'] ?? "") ?? 1234567890,
                "companyName": "Recipient Company Name"
              },
              "address": {
                "streetLines": [addressDetails['address'] ?? ""],
                "city": addressDetails['city'] ?? "",
                "postalCode": addressDetails['zipCode'] ?? "",
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
          "labelSpecification": {  // Added required label specification
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

          final totalNetCharge = rateDetails['totalNetCharge'] ?? 0.0;
          return double.parse(totalNetCharge.toString());
        } catch (e) {
          print('Error parsing rate from response: $e');
          return _calculateFallbackRate(distance, cartList);
        }
      }

      return _calculateFallbackRate(distance, cartList);
    } catch (e) {
      print('Error calculating FedEx rate: $e');
      return _calculateFallbackRate(distance, cartList);
    }
  }

  double _calculateFallbackRate(double distance, List<CartModel> cartList) {
    double baseRate = 15.00; // Base handling fee
    double finalRate;

    // Distance based tiers
    if (distance <= 20) {
      finalRate = baseRate + 17.30; // $32.30 for up to 20 miles
    } else if (distance <= 40) {
      finalRate = baseRate + 22.30; // $37.30 for 21-40 miles
    } else if (distance <= 60) {
      finalRate = baseRate + 27.30; // $42.30 for 41-60 miles
    } else {
      // For distances over 60 miles, add $0.50 per additional mile
      double extraMiles = distance - 60;
      finalRate = baseRate + 27.30 + (extraMiles * 0.50);
    }

    // Add weight surcharge
    double totalWeight = 0;
    for (var item in cartList) {
      totalWeight += (item.weight ?? 0.5) * (item.quantity ?? 1);
    }

    if (totalWeight > 10) { // If package is over 10kg
      finalRate += (totalWeight - 10) * 1.50; // $1.50 per kg over 10kg
    }

    // Convert USD to GBP
    final gbpRate = finalRate * 0.80;
    return double.parse(gbpRate.toStringAsFixed(2));
  }
  // Order placement methods
  @override
  Future<ApiResponse> shipdayPlaceOrder({
    required String addressID,
    required String couponCode,
    required String couponDiscountAmount,
    required String billingAddressId,
    required String orderNote,
    required List<CartModel> cartList,
    required Map<String, dynamic> addressDetails,
    required double totalAmount,
    required double tax,
    required double discount,
    required double deliveryFee,
    bool? isCheckCreateAccount,
    String? password,
  }) async {
    try {
      print('Starting Shipday order process');

      final regularOrderResponse = await checkoutRepositoryInterface.cashOnDeliveryPlaceOrder(
          addressID, couponCode, couponDiscountAmount, billingAddressId,
          orderNote, isCheckCreateAccount, password
      );

      if (regularOrderResponse.response?.statusCode == 200) {
        final orderId = regularOrderResponse.response?.data['order_id'] ??
            'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        final deliveryLatitude = double.tryParse(addressDetails['calculatedLatitude']?.toString() ?? '') ?? 53.5228957;
        final deliveryLongitude = double.tryParse(addressDetails['calculatedLongitude']?.toString() ?? '') ?? -1.1338375;

        final distance = _calculateHaversineDistance(
          lat1: warehouseCoordinates['latitude']!,
          lon1: warehouseCoordinates['longitude']!,
          lat2: deliveryLatitude,
          lon2: deliveryLongitude,
        );

        bool shipdaySuccess = await _sendToShipday(
          orderId: orderId,
          cartItems: cartList,
          addressDetails: {
            ...addressDetails,
            'latitude': deliveryLatitude.toString(),
            'longitude': deliveryLongitude.toString(),
          },
          totalAmount: totalAmount,
          tax: tax,
          discount: discount,
          deliveryFee: deliveryFee,
          distance: distance,
        );

        if (shipdaySuccess) {
          return regularOrderResponse;
        } else {
          return ApiResponse.withError('Order placed but failed to create delivery on Shipday');
        }
      }

      return regularOrderResponse;
    } catch (e) {
      print('Error in shipdayPlaceOrder: $e');
      return ApiResponse.withError('Error: $e');
    }
  }

  @override
  Future<ApiResponse> fedExPlaceOrder({
    required String addressID,
    required String couponCode,
    required String couponDiscountAmount,
    required String billingAddressId,
    required String orderNote,
    required List<CartModel> cartList,
    required Map<String, dynamic> addressDetails,
    required double totalAmount,
    required double tax,
    required double discount,
    required double deliveryFee,
    bool? isCheckCreateAccount,
    String? password,
  }) async {
    try {
      print('Starting FedEx order process');

      final regularOrderResponse = await checkoutRepositoryInterface.cashOnDeliveryPlaceOrder(
          addressID, couponCode, couponDiscountAmount, billingAddressId,
          orderNote, isCheckCreateAccount, password
      );

      if (regularOrderResponse.response?.statusCode == 200) {
        final orderId = regularOrderResponse.response?.data['order_id'] ??
            'FDX${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        final deliveryLatitude = double.tryParse(addressDetails['calculatedLatitude']?.toString() ?? '') ?? 53.5228957;
        final deliveryLongitude = double.tryParse(addressDetails['calculatedLongitude']?.toString() ?? '') ?? -1.1338375;

        final distance = _calculateHaversineDistance(
          lat1: warehouseCoordinates['latitude']!,
          lon1: warehouseCoordinates['longitude']!,
          lat2: deliveryLatitude,
          lon2: deliveryLongitude,
        );

        bool fedExSuccess = await _sendToFedEx(
          orderId: orderId,
          cartItems: cartList,
          addressDetails: addressDetails,
          totalAmount: totalAmount,
          tax: tax,
          discount: discount,
          deliveryFee: deliveryFee,
          distance: distance,
        );

        if (fedExSuccess) {
          return regularOrderResponse;
        } else {
          return ApiResponse.withError('Order placed but failed to create FedEx shipping');
        }
      }

      return regularOrderResponse;
    } catch (e) {
      print('Error in fedExPlaceOrder: $e');
      return ApiResponse.withError('Error: $e');
    }
  }

  // Shipping service integration methods
  Future<bool> _sendToShipday({
    required String orderId,
    required List<CartModel> cartItems,
    required Map<String, dynamic> addressDetails,
    required double totalAmount,
    required double tax,
    required double discount,
    required double deliveryFee,
    required double distance,
  }) async {
    try {
      print('=== Shipday Debug Start ===');

      // Format dates properly for Shipday
      final now = DateTime.now();
      final deliveryDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Calculate estimated delivery time (add 2 hours to current time)
      final pickupTime = now;
      final deliveryTime = now.add(Duration(hours: 2));

      // Format times in 24-hour format
      final formattedPickupTime = "${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}:00";
      final formattedDeliveryTime = "${deliveryTime.hour.toString().padLeft(2, '0')}:${deliveryTime.minute.toString().padLeft(2, '0')}:00";

      final Map<String, dynamic> orderData = {
        'orderNumber': orderId,
        'customerName': addressDetails['contactPersonName'] ?? 'Customer',
        'customerAddress': addressDetails['address'] ?? '',
        'customerEmail': addressDetails['email'] ?? '',
        'customerPhoneNumber': addressDetails['phone'] ?? '',
        'restaurantName': '6Valley',
        'restaurantAddress': '15 Tideswell Rd, Sheffield S5 6QR, UK',
        'restaurantPhoneNumber': '+44 0000 000000',
        'expectedDeliveryDate': deliveryDate,
        'expectedPickupTime': formattedPickupTime,
        'expectedDeliveryTime': formattedDeliveryTime,
        'pickupLatitude': warehouseCoordinates['latitude'],
        'pickupLongitude': warehouseCoordinates['longitude'],
        'deliveryLatitude': double.tryParse(addressDetails['latitude'] ?? ''),
        'deliveryLongitude': double.tryParse(addressDetails['longitude'] ?? ''),
        'distance': distance,
        'orderItems': cartItems.map((item) => {
          'name': item.name ?? 'Product',
          'unitPrice': (item.price ?? 0).toDouble(),
          'quantity': item.quantity ?? 1,
        }).toList(),
        'tips': 0.0,
        'tax': tax,
        'discountAmount': discount,
        'deliveryFee': deliveryFee.toString(),
        'totalOrderCost': totalAmount,
        'orderSource': 'Meghra Market App',
        'paymentMethod': 'COD',
        'deliveryInstruction': addressDetails['deliveryInstruction'] ?? '',
        'additionalInfo': {
          'calculatedDistance': '${distance.toStringAsFixed(2)} miles',
          'estimatedDeliveryTime': '${(distance / 20 * 60).round()} minutes',
        },
      };

      print('Shipday Request Data: ${json.encode(orderData)}');

      final response = await http.post(
        Uri.parse(_shipdayBaseUrl),
        headers: {
          'Authorization': 'Basic $_shipdayApiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(orderData),
      );

      print('Shipday Response Status: ${response.statusCode}');
      print('Shipday Response Body: ${response.body}');

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        print('Shipday order created successfully');
        return true;
      } else {
        print('Shipday order creation failed: ${responseData['response']}');
        return false;
      }
    } catch (e) {
      print('Error sending to Shipday: $e');
      return false;
    }
  }

  Future<bool> _sendToFedEx({
    required String orderId,
    required List<CartModel> cartItems,
    required Map<String, dynamic> addressDetails,
    required double totalAmount,
    required double tax,
    required double discount,
    required double deliveryFee,
    required double distance,
  }) async {
    try {
      print('=== FedEx Debug Start ===');
      final token = await _getFedExToken();
      if (token == null) return false;

      double totalWeight = 0;
      for (var item in cartItems) {
        totalWeight += (item.weight ?? 0.5) * (item.quantity ?? 1);
      }

      final Map<String, dynamic> shipmentRequest = {
        "labelResponseOptions": "URL_ONLY",
        "requestedShipment": {
          "shipper": {
            "contact": {
              "companyName": "6Valley",
              "phoneNumber": "+44 0000 000000"
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
                "personName": addressDetails['contactPersonName'] ?? "Recipient",
                "phoneNumber": addressDetails['phone'] ?? "",
                "emailAddress": addressDetails['email'] ?? "",
              },
              "address": {
                "streetLines": [addressDetails['address'] ?? ""],
                "city": addressDetails['city'] ?? "",
                "postalCode": addressDetails['zipCode'] ?? "",
                "countryCode": "GB"
              }
            }
          ],
          "serviceType": "FEDEX_NEXT_DAY_MID_MORNING",
          "packagingType": "FEDEX_PAK",
          "pickupType": "USE_SCHEDULED_PICKUP",
          "shippingChargesPayment": {
            "paymentType": "SENDER"
          },
          "requestedPackageLineItems": [
            {
              "weight": {
                "value": totalWeight,
                "units": "KG"
              },
              // "dimensions": {
              //   "length": 20,
              //   "width": 20,
              //   "height": 20,
              //   "units": "CM"
              // }
            }
          ],
          "customerReferences": [
            {
              "customerReferenceType": "CUSTOMER_REFERENCE",
              "value": orderId
            },
            {
              "customerReferenceType": "INVOICE_NUMBER",
              "value": orderId
            }
          ]
        },
        "accountNumber": {
          "value": _fedExAccountNumber
        }
      };

      final response = await http.post(
        Uri.parse(_fedExShipUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(shipmentRequest),
      );

      print('FedEx Response Status: ${response.statusCode}');
      print('FedEx Response Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending to FedEx: $e');
      return false;
    }
  }

  // Implement other required interface methods
  @override
  Future<ApiResponse> cashOnDeliveryPlaceOrder(
      String? addressID,
      String? couponCode,
      String? couponDiscountAmount,
      String? billingAddressId,
      String? orderNote,
      bool? isCheckCreateAccount,
      String? password
      ) async {
    return await checkoutRepositoryInterface.cashOnDeliveryPlaceOrder(
        addressID, couponCode, couponDiscountAmount, billingAddressId,
        orderNote, isCheckCreateAccount, password
    );
  }

  @override
  Future<ApiResponse> digitalPaymentPlaceOrder(
      String? orderNote,
      String? customerId,
      String? addressId,
      String? billingAddressId,
      String? couponCode,
      String? couponDiscount,
      String? paymentMethod,
      bool? isCheckCreateAccount,
      String? password
      ) async {
    return await checkoutRepositoryInterface.digitalPaymentPlaceOrder(
        orderNote, customerId, addressId, billingAddressId,
        couponCode, couponDiscount, paymentMethod,
        isCheckCreateAccount, password
    );
  }

  @override
  Future<ApiResponse> offlinePaymentList() async {
    return await checkoutRepositoryInterface.offlinePaymentList();
  }

  @override
  Future<ApiResponse> offlinePaymentPlaceOrder(
      String? addressID,
      String? couponCode,
      String? couponDiscountAmount,
      String? billingAddressId,
      String? orderNote,
      List<String?> typeKey,
      List<String> typeValue,
      int? id,
      String name,
      String? paymentNote,
      bool? isCheckCreateAccount,
      String? password
      ) async {
    return await checkoutRepositoryInterface.offlinePaymentPlaceOrder(
        addressID, couponCode, couponDiscountAmount, billingAddressId,
        orderNote, typeKey, typeValue, id, name, paymentNote,
        isCheckCreateAccount, password
    );
  }

  @override
  Future<ApiResponse> walletPaymentPlaceOrder(
      String? addressID,
      String? couponCode,
      String? couponDiscountAmount,
      String? billingAddressId,
      String? orderNote,
      bool? isCheckCreateAccount,
      String? password
      ) async {
    return await checkoutRepositoryInterface.walletPaymentPlaceOrder(
        addressID, couponCode, couponDiscountAmount, billingAddressId,
        orderNote, isCheckCreateAccount, password
    );
  }

  // Test connections
  Future<bool> testShipdayConnection() async {
    try {
      final response = await http.get(
        Uri.parse(_shipdayBaseUrl),
        headers: {
          'Authorization': 'Basic $_shipdayApiKey',
          'Accept': 'application/json',
        },
      );

      print('Shipday Test Connection Status: ${response.statusCode}');
      print('Shipday Test Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Shipday Test Connection Error: $e');
      return false;
    }
  }

  Future<bool> testFedExConnection() async {
    try {
      final token = await _getFedExToken();
      if (token == null) return false;

      // Test FedEx connection using a simple rate quote
      final response = await http.get(
        Uri.parse(_fedExShipUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('FedEx Test Connection Status: ${response.statusCode}');
      print('FedEx Test Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('FedEx Test Connection Error: $e');
      return false;
    }
  }

  // Updated DPD authentication method
  Future<String?> _getDPDGeoSession() async {
    try {
      print('\n=== Getting DPD GeoSession ===');
      print('Making request to: https://api.dpdlocal.co.uk/user/?action=login');
      print('Headers: Authorization: Basic cGFsbGV0c3J1czpwYWxsZXRzcnVzMjAyNEA=');

      final response = await http.post(
          Uri.parse('https://api.dpdlocal.co.uk/user/?action=login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Basic cGFsbGV0c3J1czpwYWxsZXRzcnVzMjAyNEA='
          }
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Correctly access the geoSession from the nested structure
        final geoSession = data['data']?['geoSession'];
        print('Extracted GeoSession: $geoSession');
        print('=== End Getting DPD GeoSession ===\n');
        return geoSession;
      }

      print('Failed to get GeoSession');
      print('=== End Getting DPD GeoSession ===\n');
      return null;
    } catch (e) {
      print('Error getting DPD GeoSession: $e');
      print('=== End Getting DPD GeoSession ===\n');
      return null;
    }
  }

  // Add method to test DPD connection
  Future<bool> testDPDConnection() async {
    try {
      final token = await _getDPDGeoSession();
      if (token == null) {
        print('Failed to get DPD GeoSession token');
        return false;
      }

      // Test DPD connection using a simple tracking request
      final response = await http.get(
        Uri.parse('$_dpdBaseUrl/shipping/status'),
        headers: {
          'GeoSession': token,
          'Content-Type': 'application/json',
          'Authorization': _dpdAuthToken,
        },
      );

      print('DPD Test Connection Status: ${response.statusCode}');
      print('DPD Test Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('DPD Test Connection Error: $e');
      return false;
    }
  }

  // Update the shipping rate calculation for DPD
  Future<double> _calculateDPDRate(double distance, List<CartModel> cartList, Map<String, dynamic> addressDetails) async {
    try {
      final token = await _getDPDGeoSession();
      if (token == null) {
        print('Failed to get DPD token, using fallback rate');
        return _calculateDPDFallbackRate(distance, cartList);
      }

      double totalWeight = 0;
      for (var item in cartList) {
        totalWeight += (item.weight ?? 0.5) * (item.quantity ?? 1);
      }

      final rateRequest = {
        'collectionDetails': {
          'address': {
            'organisation': '6Valley',
            'streetAddress': ['15 Tideswell Rd'],
            'locality': 'Sheffield',
            'postalCode': 'S5 6QR',
            'countryCode': 'GB'
          }
        },
        'deliveryDetails': {
          'address': {
            'organisation': addressDetails['contactPersonName'] ?? '',
            'streetAddress': [addressDetails['address'] ?? ''],
            'locality': addressDetails['city'] ?? '',
            'postalCode': addressDetails['zipCode'] ?? '',
            'countryCode': 'GB'
          }
        },
        'consignment': {
          'weight': totalWeight,
          'numberOfParcels': 1,
          'shippingDate': DateTime.now().toIso8601String().split('T')[0],
          'serviceCode': 'NEXT_DAY'
        }
      };

      final response = await http.post(
        Uri.parse('$_dpdBaseUrl/shipping/price'),
        headers: {
          'GeoSession': token,
          'Content-Type': 'application/json',
          'Authorization': _dpdAuthToken,
        },
        body: jsonEncode(rateRequest),
      );

      print('DPD Rate Response Status: ${response.statusCode}');
      print('DPD Rate Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return double.parse(data['totalPrice'].toString());
      }

      return _calculateDPDFallbackRate(distance, cartList);
    } catch (e) {
      print('Error calculating DPD rate: $e');
      return _calculateDPDFallbackRate(distance, cartList);
    }
  }

  // Helper method to send order to DPD
  Future<bool> _sendToDPD({
    required String orderId,
    required List<CartModel> cartItems,
    required Map<String, dynamic> addressDetails,
    required double totalAmount,
    required double tax,
    required double discount,
    required double deliveryFee,
    required double distance,
  }) async {
    try {
      print('\n=== Starting DPD Shipping Creation ===');
      print('Order ID: $orderId');
      print('Attempting to get DPD GeoSession...');

      final geoSession = await _getDPDGeoSession();
      if (geoSession == null) {
        print('Failed to get GeoSession token');
        return false;
      }
      print('GeoSession obtained successfully');

      double totalWeight = 0;
      print('\nCalculating total weight:');
      for (var item in cartItems) {
        double itemWeight = (item.weight ?? 0.5) * (item.quantity ?? 1);
        totalWeight += itemWeight;
        print('Item: ${item.name}, Weight: ${itemWeight}kg');
      }
      print('Total Order Weight: ${totalWeight}kg');

      List<Map<String, dynamic>> parcelProducts = cartItems.map((item) => {
        "productCode": item.id.toString(),
        "productTypeDescription": item.name,
        "productItemsDescription": item.name,  // Changed from item.details to item.name
        "productFabricContent": item.name,
        "countryOfOrigin": "GB",
        "productHarmonisedCode": "",
        "unitWeight": item.weight ?? 0.5,
        "numberOfItems": item.quantity ?? 1,
        "unitValue": 1,
        "productUrl": "www.dpd.co.uk/productURLtest"
      }).toList();

      final shipmentRequest = {
        "jobId": null,
        "collectionOnDelivery": false,
        "generateCustomsData": "Y",
        "invoice": {
          "invoiceCustomsNumber": "FDA Reg No",
          "invoiceExportReason": "01",
          "invoiceTermsOfDelivery": "DAP",
          "invoiceReference": "Invoice Reference",
          "invoiceType": 1,
          "shippingCost": deliveryFee,
          "invoiceShipperDetails": {
            "contactDetails": {
              "contactName": "Shipper Ali",
              "telephone": "1234567880"
            },
            "address": {
              "organisation": "6 Valley",
              "countryCode": "GB",
              "postcode": "S5 6QR",
              "street": "37 Tideswell Rd",
              "locality": "Shipper Locality",
              "town": "Sheffield Shope",
              "county": "United Kingdom"
            },
            "valueAddedTaxNumber": "None",
            "eoriNumber": "None",
            "ukimsNumber": ""
          },
          "invoiceDeliveryDetails": {
            "contactDetails": {
              "contactName": addressDetails['contactPersonName'],
              "telephone": addressDetails['phone'],
              "email": addressDetails['email']
            },
            "address": {
              "organisation": "Delivery Organisation",
              "countryCode": "GB",
              "postcode": addressDetails['zipCode'],
              "street": addressDetails['address'],
              "locality": "Delivery Locality",
              "town": addressDetails['city'],
              "county": "United Kingdom"
            },
            "valueAddedTaxNumber": "DELIVERY123456789",
            "eoriNumber": "DELIVERY123456789",
            "pidNumber": "",
            "ukimsNumber": "GBUKIMS123456789012202409011000",
            "isBusiness": true,
            "atRisk": true
          }
        },
        "collectionDate": DateTime.now().toIso8601String().split('T')[0],
        "consolidate": false,
        "consignment": [
          {
            "consignmentNumber": null,
            "consignmentRef": null,
            "parcel": [
              {
                "packageNumber": 1,
                "parcelProduct": cartItems.map((item) => {
                  "productCode": item.id.toString(),
                  "productTypeDescription": item.name,
                  "productItemsDescription": item.name,
                  "productFabricContent": "Mixed",
                  "countryOfOrigin": "GB",
                  "productHarmonisedCode": "",
                  "unitWeight": item.weight ?? 0.5,
                  "numberOfItems": item.quantity ?? 1,
                  "unitValue": 1,
                  "productUrl": "www.dpd.co.uk/productURLtest"
                }).toList()
              }
            ],
            "collectionDetails": {
              "contactDetails": {
                "contactName": "Shipper Ali",
                "telephone": "1234567880"
              },
              "address": {
                "organisation": "6 Valley",
                "countryCode": "GB",
                "postcode": "S5 6QR",
                "street": "37 Tideswell Rd",
                "locality": "Shipper Locality",
                "town": "Sheffield Shope",
                "county": "United Kingdom"
              }
            },
            "deliveryDetails": {
              "contactDetails": {
                "contactName": addressDetails['contactPersonName'],
                "telephone": addressDetails['phone']
              },
              "address": {
                "organisation": "Delivery Organisation",
                "countryCode": "GB",
                "postcode": addressDetails['zipCode'],
                "street": addressDetails['address'],
                "locality": "Delivery Locality",
                "town": addressDetails['city'],
                "county": "United Kingdom"
              },
              "notificationDetails": {
                "email": addressDetails['email'],
                "mobile": addressDetails['phone']
              }
            },
            "networkCode": "2^12",
            "numberOfParcels": 1,
            "totalWeight": totalWeight,
            "shippingRef1": " ",
            "shippingRef2": " ",
            "shippingRef3": " ",
            "customsCurrency": "GBP",
            "customsValue": 15,
            "deliveryInstructions": "Delivery Instructions",
            "parcelDescription": "",
            "liabilityValue": null,
            "liability": false,
            "shippersDestinationTaxId": "",
            "vatPaid": "N"
          }
        ]
      };

      print('\nSending request to DPD API:');
      print('URL: https://api.dpdlocal.co.uk/shipping/shipment');
      print('Headers:');
      print('  Content-Type: application/json');
      print('  Accept: application/json');
      print('  GeoSession: $geoSession');
      print('  GeoClient: account/3024542');
      print('\nRequest Body:');
      print(JsonEncoder.withIndent('  ').convert(shipmentRequest));

      final response = await http.post(
          Uri.parse('https://api.dpdlocal.co.uk/shipping/shipment'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'GeoSession': geoSession,
            'GeoClient': 'account/3024542'
          },
          body: jsonEncode(shipmentRequest)
      );

      print('\nDPD API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      print('=== End DPD Shipping Creation ===\n');

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      print('\nError in DPD shipping creation:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Implement the DPD place order method
  @override
  Future<ApiResponse> dpdPlaceOrder({
    required String addressID,
    required String couponCode,
    required String couponDiscountAmount,
    required String billingAddressId,
    required String orderNote,
    required List<CartModel> cartList,
    required Map<String, dynamic> addressDetails,
    required double totalAmount,
    required double tax,
    required double discount,
    required double deliveryFee,
    bool? isCheckCreateAccount,
    String? password,
  }) async {
    try {
      print('Starting DPD order process');

      final regularOrderResponse = await checkoutRepositoryInterface.cashOnDeliveryPlaceOrder(
          addressID,
          couponCode,
          couponDiscountAmount,
          billingAddressId,
          orderNote,
          isCheckCreateAccount,
          password
      );

      if (regularOrderResponse.response?.statusCode == 200) {
        final orderId = regularOrderResponse.response?.data['order_id'] ??
            'DPD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        final deliveryLatitude = double.tryParse(addressDetails['calculatedLatitude']?.toString() ?? '') ?? 53.5228957;
        final deliveryLongitude = double.tryParse(addressDetails['calculatedLongitude']?.toString() ?? '') ?? -1.1338375;

        final distance = _calculateHaversineDistance(
          lat1: warehouseCoordinates['latitude']!,
          lon1: warehouseCoordinates['longitude']!,
          lat2: deliveryLatitude,
          lon2: deliveryLongitude,
        );

        bool dpdSuccess = await _sendToDPD(
          orderId: orderId,
          cartItems: cartList,
          addressDetails: addressDetails,
          totalAmount: totalAmount,
          tax: tax,
          discount: discount,
          deliveryFee: deliveryFee,
          distance: distance,
        );

        if (dpdSuccess) {
          return regularOrderResponse;
        } else {
          return ApiResponse.withError('Order placed but failed to create DPD shipping');
        }
      }

      return regularOrderResponse;
    } catch (e) {
      print('Error in dpdPlaceOrder: $e');
      return ApiResponse.withError('Error: $e');
    }
  }

  // Add the DPD fallback rate calculation
  double _calculateDPDFallbackRate(double distance, List<CartModel> cartList) {
    double baseRate = 12.00; // Base handling fee
    double finalRate;

    // Distance based tiers for DPD
    if (distance <= 20) {
      finalRate = baseRate + 15.30;
    } else if (distance <= 40) {
      finalRate = baseRate + 20.30;
    } else if (distance <= 60) {
      finalRate = baseRate + 25.30;
    } else {
      double extraMiles = distance - 60;
      finalRate = baseRate + 25.30 + (extraMiles * 0.45);
    }

    // Weight surcharge
    double totalWeight = 0;
    for (var item in cartList) {
      totalWeight += (item.weight ?? 0.5) * (item.quantity ?? 1);
    }

    if (totalWeight > 10) {
      finalRate += (totalWeight - 10) * 1.25;
    }

    return double.parse(finalRate.toStringAsFixed(2));
  }



}