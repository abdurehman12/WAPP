import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/repositories/cart_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/services/cart_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';

class CartService implements CartServiceInterface {
  CartRepositoryInterface cartRepositoryInterface;
  CartService({required this.cartRepositoryInterface});

  double getOrderAmount(List<CartModel> cartList, {double? discount, String? discountType}) {
    double amount = 0;
    for(int i = 0; i < cartList.length; i++) {
      amount += (cartList[i].price! - cartList[i].discount!) * cartList[i].quantity!;
    }
    return amount;
  }

  static double getOrderTaxAmount(List<CartModel> cartList, {double? discount, String? discountType}) {
    double tax = 0;
    for(int i = 0; i < cartList.length; i++) {
      if(cartList[i].taxModel == "exclude") {
        tax += cartList[i].tax! * cartList[i].quantity!;
      }
    }
    return tax;
  }

  static double getOrderDiscountAmount(List<CartModel> cartList, {double? discount, String? discountType}) {
    double discount = 0;
    for(int i = 0; i < cartList.length; i++) {
      discount += cartList[i].discount! * cartList[i].quantity!;
    }
    return discount;
  }

  static List<String?> getSellerList(List<CartModel> cartList, {double? discount, String? discountType}) {
    List<String?> sellerList = [];
    for(CartModel cart in cartList) {
      if(!sellerList.contains(cart.cartGroupId)) {
        sellerList.add(cart.cartGroupId);
      }
    }
    return sellerList;
  }

  static List<CartModel> getSellerGroupList(List<String?> sellerList, List<CartModel> cartList, {double? discount, String? discountType}) {
    List<CartModel> sellerGroupList = [];
    for(CartModel cart in cartList) {
      if(!sellerList.contains(cart.cartGroupId)) {
        sellerList.add(cart.cartGroupId);
        sellerGroupList.add(cart);
      }
    }
    return sellerGroupList;
  }

  static bool checkMinimumOrderAmount(List<List<CartModel>> cartProductList, List<CartModel> cartList) {
    bool minimum = false;
    double total = 0;
    for(int index = 0; index < cartProductList.length; index++) {
      for(CartModel cart in cartProductList[index]) {
        total += (cart.price! - cart.discount!) * cart.quantity! + getOrderTaxAmount(cartList);
        if(total < cart.minimumOrderAmountInfo!) {
          minimum = true;
        }
      }
    }
    return minimum;
  }

  @override
  Future addToCartListData(CartModelBody cart, List<ChoiceOptions> choiceOptions, List<int>? variationIndexes, [int buyNow = 0]) async {
    return await cartRepositoryInterface.addToCartListData(cart, choiceOptions, variationIndexes, buyNow);
  }

  @override
  Future updateQuantity(int? key, int quantity) async {
    return await cartRepositoryInterface.updateQuantity(key, quantity);
  }

  @override
  Future delete(int id) async {
    return await cartRepositoryInterface.delete(id);
  }

  @override
  Future getList() async {
    return await cartRepositoryInterface.getList();
  }

  @override
  Future addRemoveCartSelectedItem(Map<String, dynamic> data) async {
    return await cartRepositoryInterface.addRemoveCartSelectedItem(data);
  }
}