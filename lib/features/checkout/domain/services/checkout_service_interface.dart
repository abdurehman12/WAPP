import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';

abstract class CheckoutServiceInterface {
  Future<ApiResponse> cashOnDeliveryPlaceOrder(
      String? addressID,
      String? couponCode,
      String? couponDiscountAmount,
      String? billingAddressId,
      String? orderNote,
      bool? isCheckCreateAccount,
      String? password,
      );

  Future<ApiResponse> digitalPaymentPlaceOrder(
      String? orderNote,
      String? customerId,
      String? addressId,
      String? billingAddressId,
      String? couponCode,
      String? couponDiscount,
      String? paymentMethod,
      bool? isCheckCreateAccount,
      String? password,
      );

  Future<ApiResponse> walletPaymentPlaceOrder(
      String? addressID,
      String? couponCode,
      String? couponDiscountAmount,
      String? billingAddressId,
      String? orderNote,
      bool? isCheckCreateAccount,
      String? password,
      );

  Future<ApiResponse> offlinePaymentList();

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
      String? password,
      );

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
  });

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
  });

  // Add the DPD place order method to the interface
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
  });

  Future<double> calculateShippingRate({
    required Map<String, dynamic> addressDetails,
    required List<CartModel> cartList,
    required String shippingMethod,
  });
}