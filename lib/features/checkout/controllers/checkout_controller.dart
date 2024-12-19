// lib/features/checkout/controllers/checkout_controller.dart

import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/domain/models/offline_payment_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/screens/digital_payment_order_place_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CheckoutController with ChangeNotifier {
  final CheckoutServiceInterface checkoutServiceInterface;
  CheckoutController({required this.checkoutServiceInterface});

  String? _selectedShippingMethod;
  String? get selectedShippingMethod => _selectedShippingMethod;

  // Add this with your other properties
  double _dpdShippingFee = 0.0;
  double get dpdShippingFee => _dpdShippingFee;


  double _fedExShippingFee = 0.0;
  double get fedExShippingFee => _fedExShippingFee;
  bool _isCalculatingFee = false;
  bool get isCalculatingFee => _isCalculatingFee;

  double _shipdayShippingFee = 0.0;
  double get shipdayShippingFee => _shipdayShippingFee;

  double? _lastCalculatedDistance;
  // String? _lastCalculatedMethod;


  int? _addressIndex;
  int? _billingAddressIndex;
  int? get billingAddressIndex => _billingAddressIndex;
  int? _shippingIndex;
  bool _isLoading = false;
  bool _isCheckCreateAccount = false;
  bool _newUser = false;
  int _paymentMethodIndex = -1;
  bool _onlyDigital = true;

  bool get onlyDigital => _onlyDigital;
  int? get addressIndex => _addressIndex;
  int? get shippingIndex => _shippingIndex;
  bool get isLoading => _isLoading;
  int get paymentMethodIndex => _paymentMethodIndex;
  bool get isCheckCreateAccount => _isCheckCreateAccount;

  String? _lastCalculatedAddress;
  String? _lastCalculatedMethod;

  String selectedPaymentName = '';
  void setSelectedPayment(String payment) {
    selectedPaymentName = payment;
    notifyListeners();
  }

  void setSelectedShippingMethod(String method) {
    if (_selectedShippingMethod != method) {
      _selectedShippingMethod = method;
      _lastCalculatedMethod = null; // Reset last calculated method
      _lastCalculatedDistance = null; // Reset last calculated distance
      print('Shipping method set to: $method');
      notifyListeners();
    }
  }

  final TextEditingController orderNoteController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  List<String> inputValueList = [];

  Future<void> calculateFedExFee({
    required Map<String, dynamic> addressDetails,
    required List<CartModel> cartList,
  }) async {
    String addressKey = '${addressDetails['address']}_${addressDetails['zipCode']}';
    if (_lastCalculatedAddress == addressKey &&
        _lastCalculatedMethod == 'FedEx') {
      return;
    }

    _isCalculatingFee = true;
    notifyListeners();

    try {
      _fedExShippingFee = await checkoutServiceInterface.calculateShippingRate(
        addressDetails: addressDetails,
        cartList: cartList,
        shippingMethod: 'FedEx',
      );
      _lastCalculatedAddress = addressKey;
      _lastCalculatedMethod = 'FedEx';
    } catch (e) {
      print('Error calculating FedEx fee: $e');
      _fedExShippingFee = 0.0;
    }

    _isCalculatingFee = false;
    notifyListeners();
  }

  Future<void> placeOrder({
    required Function callback,
    String? addressID,
    String? couponCode,
    String? couponAmount,
    String? billingAddressId,
    String? orderNote,
    String? transactionId,
    String? paymentNote,
    int? id,
    String? name,
    bool isfOffline = false,
    bool wallet = false,
    Map<String, dynamic>? addressDetails,
    List<CartModel>? cartList,
    double? totalAmount,
    double? tax,
    double? discount,
    double? deliveryFee,
  }) async {
    _isLoading = true;
    _newUser = false;
    notifyListeners();

    try {
      ApiResponse apiResponse;
      inputValueList.clear();

      // Add debug logs to check shipping method
      print('\n=== Order Placement Debug ===');
      print('Selected Shipping Method: $_selectedShippingMethod');
      print('Address Details Present: ${addressDetails != null}');
      print('Cart List Present: ${cartList != null}');

      if (_selectedShippingMethod == 'DPD' && addressDetails != null && cartList != null) {
        print('Initiating DPD Order Process');
        apiResponse = await checkoutServiceInterface.dpdPlaceOrder(
          addressID: addressID ?? '',
          couponCode: couponCode ?? '',
          couponDiscountAmount: couponAmount ?? '',
          billingAddressId: billingAddressId ?? '',
          orderNote: orderNote ?? '',
          cartList: cartList,
          addressDetails: addressDetails,
          totalAmount: totalAmount ?? 0,
          tax: tax ?? 0,
          discount: discount ?? 0,
          deliveryFee: _dpdShippingFee,
          isCheckCreateAccount: _isCheckCreateAccount,
          password: passwordController.text.trim(),
        );
        print('DPD Order Process Complete');
      }

      if (_selectedShippingMethod == 'FedEx' && addressDetails != null && cartList != null) {
        print('Processing FedEx order');
        apiResponse = await checkoutServiceInterface.fedExPlaceOrder(
          addressID: addressID ?? '',
          couponCode: couponCode ?? '',
          couponDiscountAmount: couponAmount ?? '',
          billingAddressId: billingAddressId ?? '',
          orderNote: orderNote ?? '',
          cartList: cartList,
          addressDetails: addressDetails,
          totalAmount: totalAmount ?? 0,
          tax: tax ?? 0,
          discount: discount ?? 0,
          deliveryFee: _fedExShippingFee,
          isCheckCreateAccount: _isCheckCreateAccount,
          password: passwordController.text.trim(),
        );
      }

      if (selectedShippingMethod == 'Shipday' && addressDetails != null && cartList != null) {
        print('Processing Shipday order');
        for(TextEditingController textEditingController in inputFieldControllerList) {
          inputValueList.add(textEditingController.text.trim());
        }

        // First place regular order then send to Shipday
        apiResponse = await checkoutServiceInterface.shipdayPlaceOrder(
          addressID: addressID ?? '',
          couponCode: couponCode ?? '',
          couponDiscountAmount: couponAmount ?? '',
          billingAddressId: billingAddressId ?? '',
          orderNote: orderNote ?? '',
          cartList: cartList,
          addressDetails: addressDetails,
          totalAmount: totalAmount ?? 0,
          tax: tax ?? 0,
          discount: discount ?? 0,
          deliveryFee: deliveryFee ?? 0,
          isCheckCreateAccount: _isCheckCreateAccount,
          password: passwordController.text.trim(),
        );
      } else if (isfOffline) {
        for(TextEditingController textEditingController in inputFieldControllerList) {
          inputValueList.add(textEditingController.text.trim());
        }
        apiResponse = await checkoutServiceInterface.offlinePaymentPlaceOrder(
            addressID, couponCode, couponAmount, billingAddressId, orderNote,
            keyList, inputValueList, offlineMethodSelectedId,
            offlineMethodSelectedName, paymentNote, _isCheckCreateAccount,
            passwordController.text.trim()
        );
      } else if (wallet) {
        apiResponse = await checkoutServiceInterface.walletPaymentPlaceOrder(
            addressID, couponCode, couponAmount, billingAddressId, orderNote,
            _isCheckCreateAccount, passwordController.text.trim()
        );
      } else {
        apiResponse = await checkoutServiceInterface.cashOnDeliveryPlaceOrder(
            addressID, couponCode, couponAmount, billingAddressId, orderNote,
            _isCheckCreateAccount, passwordController.text.trim()
        );
      }

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        _isCheckCreateAccount = false;
        _isLoading = false;
        _addressIndex = null;
        _billingAddressIndex = null;
        sameAsBilling = false;

        if(!Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn()) {
          _newUser = apiResponse.response!.data['new_user'];
        }

        String message = apiResponse.response!.data.toString();
        callback(true, message, '', _newUser);
      } else {
        _isLoading = false;
        ApiChecker.checkApi(apiResponse);
      }
    } catch (e) {
      _isLoading = false;
      print('Error in placeOrder: $e');
      callback(false, e.toString(), '', false);
    }
    notifyListeners();
  }

  void setAddressIndex(int index) {
    _addressIndex = index;
    notifyListeners();
  }

  void setBillingAddressIndex(int index) {
    _billingAddressIndex = index;
    notifyListeners();
  }

  void resetPaymentMethod() {
    _paymentMethodIndex = -1;
    codChecked = false;
    walletChecked = false;
    offlineChecked = false;
    _lastCalculatedAddress = null;
    _lastCalculatedMethod = null;
  }

  void shippingAddressNull() {
    _addressIndex = null;
    notifyListeners();
  }

  void billingAddressNull() {
    _billingAddressIndex = null;
    notifyListeners();
  }

  void setSelectedShippingAddress(int index) {
    _shippingIndex = index;
    notifyListeners();
  }

  void setSelectedBillingAddress(int index) {
    _billingAddressIndex = index;
    notifyListeners();
  }

  bool offlineChecked = false;
  bool codChecked = false;
  bool walletChecked = false;

  void setOfflineChecked(String type) {
    if(type == 'offline') {
      offlineChecked = !offlineChecked;
      codChecked = false;
      walletChecked = false;
      _paymentMethodIndex = -1;
      setOfflinePaymentMethodSelectedIndex(0);
    } else if(type == 'cod') {
      codChecked = !codChecked;
      offlineChecked = false;
      walletChecked = false;
      _paymentMethodIndex = -1;
    } else if(type == 'wallet') {
      walletChecked = !walletChecked;
      offlineChecked = false;
      codChecked = false;
      _paymentMethodIndex = -1;
    }
    notifyListeners();
  }

  String selectedDigitalPaymentMethodName = '';
  // String get selectedDigitalPaymentMethodName => _selectedDigitalPaymentMethodName;
  String? _paymentUrl;
  String? get paymentUrl => _paymentUrl;
  void setDigitalPaymentMethodName(int index, String name) {
    _paymentMethodIndex = index;
    selectedDigitalPaymentMethodName = name;
    codChecked = false;
    walletChecked = false;
    offlineChecked = false;
    notifyListeners();
  }

  void digitalOnly(bool value, {bool isUpdate = false}) {
    _onlyDigital = value;
    if(isUpdate) {
      notifyListeners();
    }
  }

  OfflinePaymentModel? offlinePaymentModel;
  Future<ApiResponse> getOfflinePaymentList() async {
    ApiResponse apiResponse = await checkoutServiceInterface.offlinePaymentList();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      offlineMethodSelectedIndex = 0;
      offlinePaymentModel = OfflinePaymentModel.fromJson(apiResponse.response?.data);
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  List<TextEditingController> inputFieldControllerList = [];
  List<String?> keyList = [];
  int offlineMethodSelectedIndex = -1;
  int offlineMethodSelectedId = 0;
  String offlineMethodSelectedName = '';

  void setOfflinePaymentMethodSelectedIndex(int index, {bool notify = true}) {
    keyList = [];
    inputFieldControllerList = [];
    offlineMethodSelectedIndex = index;
    if(offlinePaymentModel != null && offlinePaymentModel!.offlineMethods != null && offlinePaymentModel!.offlineMethods!.isNotEmpty) {
      offlineMethodSelectedId = offlinePaymentModel!.offlineMethods![offlineMethodSelectedIndex].id!;
      offlineMethodSelectedName = offlinePaymentModel!.offlineMethods![offlineMethodSelectedIndex].methodName!;
    }

    if(offlinePaymentModel!.offlineMethods != null &&
        offlinePaymentModel!.offlineMethods!.isNotEmpty &&
        offlinePaymentModel!.offlineMethods![index].methodInformations!.isNotEmpty) {
      for(int i = 0; i < offlinePaymentModel!.offlineMethods![index].methodInformations!.length; i++) {
        inputFieldControllerList.add(TextEditingController());
        keyList.add(offlinePaymentModel!.offlineMethods![index].methodInformations![i].customerInput);
      }
    }
    if(notify) {
      notifyListeners();
    }
  }

  void handlePaymentError(ApiResponse apiResponse) {
    if (apiResponse.error == 'Already registered') {
      showCustomSnackBar(getTranslated(apiResponse.error, Get.context!), Get.context!);
    } else {
      showCustomSnackBar(
          getTranslated('payment_method_not_properly_configured', Get.context!),
          Get.context!
      );
    }
  }

  Future<ApiResponse> digitalPaymentPlaceOrder({
    String? orderNote,
    String? customerId,
    String? addressId,
    String? billingAddressId,
    String? couponCode,
    String? couponDiscount,
    String? paymentMethod
  }) async {
    _isLoading = true;
    notifyListeners();

    ApiResponse apiResponse = await checkoutServiceInterface.digitalPaymentPlaceOrder(
        orderNote, customerId, addressId, billingAddressId,
        couponCode, couponDiscount, paymentMethod,
        _isCheckCreateAccount, passwordController.text.trim()
    );

    if (apiResponse.response?.statusCode == 200) {
      _paymentUrl = apiResponse.response?.data['redirect_link'];
      _addressIndex = null;
      _billingAddressIndex = null;
      sameAsBilling = false;
      _isLoading = false;

      if (_paymentUrl != null) {
        Navigator.pushReplacement(
            Get.context!,
            MaterialPageRoute(builder: (_) => DigitalPaymentScreen(url: _paymentUrl!))
        );
      }
    } else {
      _isLoading = false;
      if(apiResponse.error == 'Already registered ') {
        showCustomSnackBar('${getTranslated(apiResponse.error, Get.context!)}', Get.context!);
      } else {
        showCustomSnackBar('${getTranslated('payment_method_not_properly_configured', Get.context!)}', Get.context!);
      }
    }

    notifyListeners();
    return apiResponse;
  }

  bool sameAsBilling = false;
  void setSameAsBilling() {
    sameAsBilling = !sameAsBilling;
    notifyListeners();
  }

  void clearData() {
    orderNoteController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    _isCheckCreateAccount = false;
  }

  void setIsCheckCreateAccount(bool isCheck, {bool update = true}) {
    _isCheckCreateAccount = isCheck;
    if(update) {
      notifyListeners();
    }
  }
  Future<void> calculateShipdayFee({
    required Map<String, dynamic> addressDetails,
    required List<CartModel> cartList,
  }) async {
    String addressKey = '${addressDetails['address']}_${addressDetails['zipCode']}';
    if (_lastCalculatedAddress == addressKey &&
        _lastCalculatedMethod == 'Shipday') {
      return;
    }

    _isCalculatingFee = true;
    notifyListeners();

    try {
      _shipdayShippingFee = await checkoutServiceInterface.calculateShippingRate(
        addressDetails: addressDetails,
        cartList: cartList,
        shippingMethod: 'Shipday',
      );
      _lastCalculatedAddress = addressKey;
      _lastCalculatedMethod = 'Shipday';
    } catch (e) {
      print('Error calculating Shipday fee: $e');
      _shipdayShippingFee = 0.0;
    }

    _isCalculatingFee = false;
    notifyListeners();
  }

  Future<void> calculateDPDFee({
    required Map<String, dynamic> addressDetails,
    required List<CartModel> cartList,
  }) async {
    _isCalculatingFee = true;
    notifyListeners();

    double totalWeight = 0;

    print('\n=== DPD Weight Calculation Debug ===');
    print('Number of items in cart: ${cartList.length}');

    for (var item in cartList) {
      double itemWeight = (item.weight ?? 0.5) * (item.quantity ?? 1);
      totalWeight += itemWeight;

      print('Item: ${item.name}');
      print('  - Base Weight: ${item.weight ?? 0.5}kg');
      print('  - Quantity: ${item.quantity}');
      print('  - Total Item Weight: ${itemWeight.toStringAsFixed(2)}kg');
      print('-------------------');
    }

    print('Total Order Weight: ${totalWeight.toStringAsFixed(2)}kg');
    print('Fetching DPD rate from API...');

    try {
      final response = await http.get(
          Uri.parse('https://wholesalepallets.uk/api/dpd_rate/${totalWeight.ceil()}')
      );

      print('DPD Rate API Response:');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Directly parse the response body as double
        _dpdShippingFee = double.parse(response.body);
        print('Rate from API: £${_dpdShippingFee.toStringAsFixed(2)}');
      } else {
        print('Error getting rate from API');
        _dpdShippingFee = 0.0;
      }
    } catch (e) {
      print('Error calculating DPD rate: $e');
      _dpdShippingFee = 0.0;
    }

    print('Final shipping fee: £${_dpdShippingFee.toStringAsFixed(2)}');
    print('=== End DPD Weight Calculation ===\n');

    _isCalculatingFee = false;
    notifyListeners();
  }

  void setDPDShippingFee(double fee) {
    _dpdShippingFee = fee;
    notifyListeners();
  }




}