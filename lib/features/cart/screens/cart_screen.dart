import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_loader_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/widgets/cart_page_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/widgets/cart_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/screens/checkout_screen.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  final bool fromCheckout;
  final int sellerId;
  final bool showBackButton;

  const CartScreen({
    super.key,
    this.fromCheckout = false,
    this.sellerId = 1,
    this.showBackButton = true
  });

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  Future<void> _loadData() async {
    await Provider.of<CartController>(context, listen: false).getCartData(context);
    Provider.of<CartController>(context, listen: false).setCartData();
  }

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartController>(
        builder: (context, cart, child) {
      double amount = 0.0;
      double discount = 0.0;
      double tax = 0.0;
      int totalQuantity = 0;
      List<CartModel> cartList = [];
      cartList.addAll(cart.cartList);
      bool isItemChecked = false;

      List<String?> sellerList = [];
      List<CartModel> sellerGroupList = [];
      List<List<CartModel>> cartProductList = [];
      List<List<int>> cartProductIndexList = [];

      // Group items by seller
      for (CartModel cart in cartList) {
        if (cart.isChecked! && !isItemChecked) {
          isItemChecked = true;
        }
        if (!sellerList.contains(cart.cartGroupId)) {
          sellerList.add(cart.cartGroupId);
          cart.isGroupChecked = false;
          sellerGroupList.add(cart);
        }
      }

      // Create seller groups
      for (CartModel? seller in sellerGroupList) {
        List<CartModel> cartLists = [];
        List<int> indexList = [];
        bool isSellerChecked = true;
        for (CartModel cart in cartList) {
          if (seller?.cartGroupId == cart.cartGroupId) {
            cartLists.add(cart);
            indexList.add(cartList.indexOf(cart));
            if (!cart.isChecked!) {
              isSellerChecked = false;
            } else if (cart.isChecked!) {
              seller?.isGroupItemChecked = true;
            }
          }
        }

        cartProductList.add(cartLists);
        cartProductIndexList.add(indexList);
        if (isSellerChecked) {
          seller?.isGroupChecked = true;
        }
      }

      // Calculate totals
      for (int i = 0; i < cart.cartList.length; i++) {
        if (cart.cartList[i].isChecked!) {
          totalQuantity += cart.cartList[i].quantity!;
          amount += (cart.cartList[i].price! - cart.cartList[i].discount!) *
              cart.cartList[i].quantity!;
          discount += cart.cartList[i].discount! * cart.cartList[i].quantity!;
          if (cart.cartList[i].taxModel == "exclude") {
            tax += cart.cartList[i].tax! * cart.cartList[i].quantity!;
          }
        }
      }

      return Scaffold(
          bottomNavigationBar: (!cart.cartLoading && cartList.isNotEmpty)
          ? Container(
        height: 80,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(10),
            topLeft: Radius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Expanded(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${getTranslated('total_price', context)}',
              style: titilliumSemiBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
              ),
            ),
            Text(
              PriceConverter.convertPrice(context, amount + tax),
              style: titilliumBold.copyWith(
                color: Theme.of(context).primaryColor,
                fontSize: Dimensions.fontSizeExtraLarge,
              ),
            ),
          ],
        ),
      ),

            InkWell(
              onTap: () {
                if (Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
                  if (!isItemChecked) {
                    showCustomSnackBar(
                        getTranslated('select_at_least_one_product', context),
                        context
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(
                          quantity: totalQuantity,
                          cartList: cartList,
                          shippingFee: 0,
                          totalOrderAmount: amount,
                          discount: discount,
                          tax: tax,
                        ),
                      ),
                    );
                  }
                } else {
                  showModalBottomSheet(
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (_) => const NotLoggedInBottomSheetWidget(),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeLarge,
                  vertical: Dimensions.paddingSizeDefault,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                ),
                child: Text(
                  getTranslated('checkout', context)!,
                  style: titilliumSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      )
          : null,
    appBar: CustomAppBar(
    title: getTranslated('my_cart', context),
    isBackButtonExist: widget.showBackButton,
    ),

        body: 
        cart.cartLoading
            ? const CartPageShimmerWidget()
            : sellerList.isNotEmpty
            ? RefreshIndicator(
          onRefresh: () async {
            if (Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
              await Provider.of<CartController>(context, listen: false).getCartData(context);
            }
          },
          child: ListView.builder(
            itemCount: sellerList.length,
            padding: const EdgeInsets.all(0),
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    color: Theme.of(context).cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sellerGroupList[index].shopInfo!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 30,
                                  child: Checkbox(
                                    value: sellerGroupList[index].isGroupChecked,
                                    onChanged: (bool? value) async {
                                      List<int> ids = [];
                                      for (CartModel cart in cartProductList[index]) {
                                        ids.add(cart.id!);
                                      }
                                      await cart.addRemoveCartSelectedItem(ids, value!);
                                    },
                                  ),
                                ),
                                Text(
                                  sellerGroupList[index].shopInfo!,
                                  style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                                ),
                              ],
                            ),
                          ),
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: cartProductList[index].length,
                          itemBuilder: (context, i) => CartWidget(
                            cartModel: cartProductList[index][i],
                            index: cartProductIndexList[index][i],
                            fromCheckout: widget.fromCheckout,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                ],
              );
            },
          ),
        )
            : const Center(
          child: NoInternetOrDataScreenWidget(
            icon: Images.emptyCart,
            icCart: true,
            isNoInternet: false,
            message: 'no_product_in_cart',
          ),
        ),
      );
        },
    );
  }
}