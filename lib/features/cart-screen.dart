import 'package:flutter/foundation.dart';
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
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  final bool fromCheckout;
  final int sellerId;
  final bool showBackButton;

  const CartScreen({
    super.key,
    this.fromCheckout = false,
    this.sellerId = 1,
    this.showBackButton = true,
  });

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  Future<void> _loadData() async {
    await Provider.of<CartController>(Get.context!, listen: false).getCartData(Get.context!);
    Provider.of<CartController>(Get.context!, listen: false).setCartData();
  }

  Color _currentColor = Theme.of(Get.context!).cardColor;
  final Duration duration = const Duration(milliseconds: 500);

  void changeColor() {
    setState(() {
      _currentColor = (_currentColor == Theme.of(Get.context!).cardColor)
          ? Colors.grey.withOpacity(.15)
          : Theme.of(Get.context!).cardColor;
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        reBackColor();
      });
    });
  }

  void reBackColor() {
    setState(() {
      _currentColor = (_currentColor == Theme.of(Get.context!).cardColor)
          ? Colors.grey.withOpacity(.15)
          : Theme.of(Get.context!).cardColor;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  final tooltipController = JustTheController();

  @override
  Widget build(BuildContext context) {
    return Consumer<SplashController>(builder: (context, configProvider, _) {
      return Consumer<CartController>(builder: (context, cart, child) {
        double amount = 0.0;
        double discount = 0.0;
        double tax = 0.0;
        int totalQuantity = 0;
        List<CartModel> cartList = [];
        cartList.addAll(cart.cartList);
        bool isItemChecked = false;

        List<String?> sellerList = [];
        List<List<String>> productType = [];
        List<CartModel> sellerGroupList = [];
        List<List<CartModel>> cartProductList = [];
        List<List<int>> cartProductIndexList = [];

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

        for (CartModel? seller in sellerGroupList) {
          List<CartModel> cartLists = [];
          List<int> indexList = [];
          List<String> productTypeList = [];
          bool isSellerChecked = true;
          for (CartModel cart in cartList) {
            if (seller?.cartGroupId == cart.cartGroupId) {
              cartLists.add(cart);
              indexList.add(cartList.indexOf(cart));
              productTypeList.add(cart.productType!);
              if (!cart.isChecked!) {
                isSellerChecked = false;
              } else if (cart.isChecked!) {
                seller?.isGroupItemChecked = true;
              }
            }
          }

          cartProductList.add(cartLists);
          productType.add(productTypeList);
          cartProductIndexList.add(indexList);
          if (isSellerChecked) {
            seller?.isGroupChecked = true;
          }
        }

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
                  height: cartList.isNotEmpty ? 110 : 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                      topLeft: Radius.circular(10)
                    )
                  ),
                  child: cartList.isNotEmpty
                      ? Column(children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Text(
                                    '${getTranslated('total_price', context)} ',
                                    style: titilliumSemiBold.copyWith(
                                      fontSize: Dimensions.fontSizeLarge,
                                      color: Provider.of<ThemeController>(context, listen: false).darkTheme
                                        ? Theme.of(context).hintColor
                                        : Theme.of(context).primaryColor
                                    )
                                  ),
                                  Text(
                                    '${getTranslated('inc_tax', context)}',
                                    style: titilliumSemiBold.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).hintColor
                                    )
                                  )
                                ]),
                                Text(
                                  PriceConverter.convertPrice(context, amount + tax),
                                  style: titilliumSemiBold.copyWith(
                                    color: Provider.of<ThemeController>(context, listen: false).darkTheme
                                      ? Theme.of(context).hintColor
                                      : Theme.of(context).primaryColor,
                                    fontSize: Dimensions.fontSizeLarge
                                  )
                                )
                              ]
                            )
                          ),
                          InkWell(
                            onTap: () {
                              if (configProvider.configModel?.guestCheckOut == 0 &&
                                  !Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
                                showModalBottomSheet(
                                  backgroundColor: Colors.transparent,
                                  context: context,
                                  builder: (_) => const NotLoggedInBottomSheetWidget()
                                );
                              } else if (cart.cartList.isEmpty) {
                                showCustomSnackBar(getTranslated('select_at_least_one_product', context), context);
                              } else if (!isItemChecked) {
                                showCustomSnackBar(getTranslated('please_select_items', context), context);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutScreen(
                                      quantity: totalQuantity,
                                      cartList: cartList,
                                      totalOrderAmount: amount,
                                      shippingFee: 0,
                                      discount: discount,
                                      tax: tax,
                                      onlyDigital: false,
                                      hasPhysical: true,
                                    )
                                  )
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)
                              ),
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeSmall,
                                    vertical: Dimensions.fontSizeSmall
                                  ),
                                  child: Text(
                                    getTranslated('checkout', context)!,
                                    style: titilliumSemiBold.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      color: Colors.white
                                    )
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ])
                      : const SizedBox()
                )
              : null,
          appBar: CustomAppBar(
            title: getTranslated('my_cart', context),
            isBackButtonExist: widget.showBackButton
          ),
          body: 
          Column(children: [
            cart.cartLoading
                ? const Expanded(child: CartPageShimmerWidget())
                : sellerList.isNotEmpty
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: sellerList.length,
                          padding: const EdgeInsets.all(0),
                          itemBuilder: (context, index) {
                            double totalCost = 0;
                            for (CartModel cart in cartProductList[index]) {
                              totalCost += (cart.price! - cart.discount!) * cart.quantity!;
                            }

                            return AnimatedContainer(
                              color: (sellerGroupList[index].minimumOrderAmountInfo! > totalCost)
                                  ? _currentColor
                                  : index.floor().isOdd
                                      ? Theme.of(context).colorScheme.onSecondaryContainer
                                      : Theme.of(context).canvasColor,
                              duration: duration,
                              child: Column(children: [
                                Container(
                                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).highlightColor
                                  ),
                                  child: Column(children: [
                                    if(sellerGroupList[index].shopInfo!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              sellerGroupList[index].shopInfo!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: textBold.copyWith(
                                                fontSize: Dimensions.fontSizeLarge,
                                                color: Provider.of<ThemeController>(context, listen: false).darkTheme
                                                  ? Theme.of(context).hintColor
                                                  : Theme.of(context).primaryColor
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '(${cartProductList[index].length})',
                                            style: textBold.copyWith(
                                              color: Provider.of<ThemeController>(context, listen: false).darkTheme
                                                ? Theme.of(context).hintColor
                                                : Theme.of(context).primaryColor,
                                              fontSize: Dimensions.fontSizeLarge
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ListView.builder(
                                      physics: const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: cartProductList[index].length,
                                      itemBuilder: (context, i) {
                                        return CartWidget(
                                          cartModel: cartProductList[index][i],
                                          index: cartProductIndexList[index][i],
                                          fromCheckout: widget.fromCheckout,
                                        );
                                      },
                                    ),
                                  ]),
                                ),
                              ]),
                            );
                          },
                        ),
                      )
                    : const Expanded(
                        child: NoInternetOrDataScreenWidget(
                          icon: Images.emptyCart,
                          icCart: true,
                          isNoInternet: false,
                          message: 'no_product_in_cart',
                        )
                      ),
          ]),
        );
      });
    });
  }
}
