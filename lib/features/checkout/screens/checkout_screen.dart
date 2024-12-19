// lib/features/checkout/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/screens/saved_address_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/screens/saved_billing_address_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/payment_method_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/screens/offline_payment_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/controllers/coupon_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/amount_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/animated_custom_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/order_place_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_details_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/wallet_payment_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_method_widget.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartModel> cartList;
  final bool fromProductDetails;
  final double totalOrderAmount;
  final double shippingFee;
  final double discount;
  final double tax;
  final int? sellerId;
  final bool onlyDigital;
  final bool hasPhysical;
  final int quantity;

  const CheckoutScreen({
    super.key,
    required this.cartList,
    this.fromProductDetails = false,
    required this.totalOrderAmount,
    required this.shippingFee,
    required this.discount,
    required this.tax,
    this.sellerId,
    this.onlyDigital = false,
    this.hasPhysical = true,
    required this.quantity,
  });

  @override
  CheckoutScreenState createState() => CheckoutScreenState();
}

class CheckoutScreenState extends State<CheckoutScreen> {
  final GlobalKey<FormState> passwordFormKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _orderNoteController = TextEditingController();
  final FocusNode _orderNoteNode = FocusNode();
  double _order = 0;
  bool _billingAddress = false;
  double? _couponDiscount;

  @override
  void initState() {
    super.initState();
    Provider.of<AddressController>(context, listen: false).getAddressList();
    Provider.of<CouponController>(context, listen: false).removePrevCouponData();
    Provider.of<CartController>(context, listen: false).getCartData(context);
    Provider.of<CheckoutController>(context, listen: false).resetPaymentMethod();

    _billingAddress = Provider.of<SplashController>(context, listen: false)
        .configModel!.billingInputByCustomer == 1;

    if(Provider.of<AuthController>(context, listen: false).isLoggedIn()){
      Provider.of<CouponController>(context, listen: false).getAvailableCouponList();
    }

    Provider.of<CheckoutController>(context, listen: false).clearData();
  }

  void _callback(bool isSuccess, String message, String orderID, bool createAccount) async {
    if(isSuccess) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashBoardScreen()),
              (route) => false
      );
      showAnimatedDialog(context, OrderPlaceDialogWidget(
        icon: Icons.check,
        title: getTranslated(createAccount ? 'order_placed_Account_Created' : 'order_placed', context),
        description: getTranslated('your_order_placed', context),
        isFailed: false,
      ), dismissible: false, willFlip: true);
    } else {
      showCustomSnackBar(message, context, isToaster: true);
    }
  }

  Widget _buildPaymentSection() {
    return Consumer<CheckoutController>(
      builder: (context, checkoutProvider, _) {
        return Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment method header
              Text(
                getTranslated('payment_method', context) ?? 'Payment Method',
                style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Cash on Delivery Option
              // if (!widget.onlyDigital) _buildPaymentOption(
              //   title: getTranslated('cash_on_delivery', context) ?? 'Cash on Delivery',
              //   icon: 'assets/images/cod.png',
              //   isChecked: checkoutProvider.codChecked,
              //   onChanged: (value) => checkoutProvider.setOfflineChecked('cod'),
              // ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Digital Payment Option
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (c) => PaymentMethodBottomSheetWidget(
                      onlyDigital: widget.onlyDigital,
                    ),
                  );
                },
                child: _buildPaymentOption(
                  title: getTranslated('digital_payment', context) ?? 'Digital Payment',
                  icon: 'assets/images/mastercard.png',
                  showArrow: true,
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Wallet Payment Option
              // Consumer<ProfileController>(
              //   builder: (context, profileProvider, _) {
              //     return _buildPaymentOption(
              //       title: '${getTranslated('wallet_payment', context) ?? 'Wallet Payment'} '
              //           '(${PriceConverter.convertPrice(context, profileProvider.balance ?? 0.0)})',
              //       icon: 'assets/images/wallet.png',
              //       isChecked: checkoutProvider.walletChecked,
              //       onChanged: (value) => checkoutProvider.setOfflineChecked('wallet'),
              //     );
              //   },
              // ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Offline Payment Option
              // _buildPaymentOption(
              //   title: getTranslated('offline_payment', context) ?? 'Offline Payment',
              //   icon: 'assets/images/offline_payment.png',
              //   isChecked: checkoutProvider.offlineChecked,
              //   onChanged: (value) => checkoutProvider.setOfflineChecked('offline'),
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String icon,
    bool? isChecked,
    Function(bool?)? onChanged,
    bool showArrow = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Image.asset(
          icon,
          width: 40,
          height: 40,
        ),
        title: Text(title),
        trailing: showArrow
            ? Icon(
          Icons.keyboard_arrow_right,
          color: Theme.of(context).primaryColor,
        )
            : (isChecked != null
            ? Checkbox(
          value: isChecked,
          activeColor: Theme.of(context).primaryColor,
          onChanged: onChanged,
        )
            : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _order = widget.totalOrderAmount + widget.discount;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(title: getTranslated('checkout', context)),

      bottomNavigationBar: Consumer<CheckoutController>(
          builder: (context, orderProvider, _) {
            return Container(
              height: 80,
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeLarge,
                  vertical: Dimensions.paddingSizeDefault
              ),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                      topLeft: Radius.circular(10)
                  )
              ),
              child: Consumer<AddressController>(
                  builder: (context, locationProvider, _) {
                    return CustomButton(
                      onTap: () async {
                        if(orderProvider.addressIndex == null && widget.hasPhysical) {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (BuildContext context) => const SavedAddressListScreen()
                          ));
                          showCustomSnackBar(
                              getTranslated('select_a_shipping_address', context),
                              context,
                              isToaster: true
                          );
                        }
                        else if((orderProvider.billingAddressIndex == null &&
                            !widget.hasPhysical && !_billingAddress) ||
                            (orderProvider.billingAddressIndex == null && _billingAddress &&
                                !orderProvider.sameAsBilling)) {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (BuildContext context) => const SavedBillingAddressListScreen()
                          ));
                          showCustomSnackBar(
                              getTranslated('select_a_billing_address', context),
                              context,
                              isToaster: true
                          );
                        }
                        else {
                          String orderNote = _orderNoteController.text.trim();
                          String couponCode = Provider.of<CouponController>(context, listen: false).discount != null ?
                          Provider.of<CouponController>(context, listen: false).couponCode : '';
                          String couponAmount = Provider.of<CouponController>(context, listen: false).discount != null ?
                          Provider.of<CouponController>(context, listen: false).discount.toString() : '0';

                          String addressId = locationProvider.addressList![orderProvider.addressIndex!].id.toString();
                          String billingAddressId = _billingAddress ?
                          (orderProvider.sameAsBilling ? addressId :
                          locationProvider.addressList![orderProvider.billingAddressIndex!].id.toString()) : '';

                          final selectedAddress = locationProvider.addressList![orderProvider.addressIndex!];
                          Map<String, dynamic> addressDetails = {
                            'contactPersonName': selectedAddress.contactPersonName,
                            'address': selectedAddress.address,
                            'email': selectedAddress.email,
                            'phone': selectedAddress.phone,
                            'latitude': selectedAddress.latitude,
                            'longitude': selectedAddress.longitude,
                            'deliveryInstruction': orderNote,
                          };

                          if (orderProvider.selectedShippingMethod == 'DPD') {
                            print('Placing order with DPD delivery...');
                            orderProvider.placeOrder(
                              callback: _callback,
                              addressID: addressId,
                              billingAddressId: billingAddressId,
                              orderNote: orderNote,
                              couponCode: couponCode,
                              couponAmount: couponAmount,
                              addressDetails: addressDetails,
                              cartList: widget.cartList,
                              totalAmount: _order,
                              tax: widget.tax,
                              discount: widget.discount,
                              deliveryFee: orderProvider.dpdShippingFee,
                            );
                          }

                          else if (orderProvider.selectedShippingMethod == 'Shipday') {
                            print('Placing order with Shipday delivery...');


                            orderProvider.placeOrder(
                              callback: _callback,
                              addressID: addressId,
                              billingAddressId: billingAddressId,
                              orderNote: orderNote,
                              couponCode: couponCode,
                              couponAmount: couponAmount,
                              addressDetails: addressDetails,
                              cartList: widget.cartList,
                              totalAmount: _order,
                              tax: widget.tax,
                              discount: widget.discount,
                              deliveryFee: widget.shippingFee,
                            );
                          }
                          else if(orderProvider.paymentMethodIndex != -1) {
                            orderProvider.placeOrder(
                                callback: _callback,
                                addressID: addressId,
                                billingAddressId: billingAddressId,
                                orderNote: orderNote,
                                couponCode: couponCode,
                                couponAmount: couponAmount
                            );
                          }
                          else if(orderProvider.codChecked && !widget.onlyDigital) {
                            orderProvider.placeOrder(
                                callback: _callback,
                                addressID: addressId,
                                billingAddressId: billingAddressId,
                                orderNote: orderNote,
                                couponCode: couponCode,
                                couponAmount: couponAmount
                            );
                          }
                          else if(orderProvider.offlineChecked) {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => OfflinePaymentScreen(
                                    payableAmount: _order,
                                    callback: _callback
                                )
                            ));
                          }
                          else if(orderProvider.walletChecked) {
                            showAnimatedDialog(context, WalletPaymentWidget(
                                currentBalance: Provider.of<ProfileController>(context, listen: false).balance ?? 0,
                                orderAmount: _order + widget.shippingFee - widget.discount - _couponDiscount! + widget.tax,
                                onTap: () {
                                  if(Provider.of<ProfileController>(context, listen: false).balance! <
                                      (_order + widget.shippingFee - widget.discount - _couponDiscount! + widget.tax)) {
                                    showCustomSnackBar(getTranslated('insufficient_balance', context), context, isToaster: true);
                                  } else {
                                    Navigator.pop(context);
                                    orderProvider.placeOrder(
                                        callback: _callback,
                                        wallet: true,
                                        addressID: addressId,
                                        billingAddressId: billingAddressId,
                                        orderNote: orderNote,
                                        couponCode: couponCode,
                                        couponAmount: couponAmount
                                    );
                                  }
                                }
                            ), dismissible: false, willFlip: true);
                          }
                          else {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (c) => PaymentMethodBottomSheetWidget(
                                  onlyDigital: widget.onlyDigital
                              ),
                            );
                          }
                        }
                      },
                      buttonText: getTranslated('proceed', context),
                    );
                  }
              ),
            );
          }
      ),

      body: Consumer<AuthController>(
          builder: (context, authProvider, _) {
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      ShippingDetailsWidget(
                          hasPhysical: widget.hasPhysical,
                          billingAddress: _billingAddress,
                          passwordFormKey: passwordFormKey
                      ),

                      // In your CheckoutScreen where you use ShippingMethodWidget

                      // Inside your checkout screen
                      // Inside CheckoutScreen class, in the ListView children list

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeSmall
                        ),
                        child: Consumer<AddressController>(
                          builder: (context, addressProvider, _) {
                            final selectedAddress = addressProvider.addressList?[
                            Provider.of<CheckoutController>(context).addressIndex ?? 0
                            ];

                            if (selectedAddress == null) {
                              return const SizedBox.shrink();
                            }

                            // Format address details
                            final addressDetails = {
                              'address': selectedAddress.address ?? '',
                              'city': selectedAddress.city ?? '',
                              'zipCode': selectedAddress.zip ?? '',
                              // Optional: Include any additional address details
                              'contactPersonName': selectedAddress.contactPersonName,
                              'phone': selectedAddress.phone,
                            };

                            return ShippingMethodWidget(
                              onSelect: (String method) async {
                                if (Provider.of<CheckoutController>(context, listen: false).selectedShippingMethod == method) {
                                  return; // Skip if same method is selected
                                }

                                print('Selected shipping method: $method');
                                final checkoutProvider = Provider.of<CheckoutController>(
                                    context,
                                    listen: false
                                );
                                checkoutProvider.setSelectedShippingMethod(method);

                                if (method == 'Shipday') {
                                  await checkoutProvider.calculateShipdayFee(
                                    addressDetails: addressDetails,
                                    cartList: widget.cartList,
                                  );
                                } else if (method == 'FedEx') {
                                  await checkoutProvider.calculateFedExFee(
                                    addressDetails: addressDetails,
                                    cartList: widget.cartList,
                                  );
                                }
                              },
                              deliveryAddress: addressDetails,
                            );
                          },
                        ),
                      ),

// Payment Methods Section
                      _buildPaymentSection(),

                      // Order summary section
                      Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: Text(
                            getTranslated('order_summary', context) ?? '',
                            style: textMedium.copyWith(
                                fontSize: Dimensions.fontSizeLarge
                            )
                        ),
                      ),

                      Consumer<CheckoutController>(
                          builder: (context, checkout, _) {
                            _couponDiscount = Provider.of<CouponController>(context).discount ?? 0;

                            // double shippingFee = checkout.selectedShippingMethod == 'FedEx'
                            //     ? checkout.fedExShippingFee
                            //     : widget.shippingFee;

                            double shippingFee;
                            if (checkout.selectedShippingMethod == 'FedEx') {
                              shippingFee = checkout.fedExShippingFee;
                            } else if (checkout.selectedShippingMethod == 'Shipday') {
                              shippingFee = checkout.shipdayShippingFee;
                            } else if (checkout.selectedShippingMethod == 'DPD') {
                              shippingFee = checkout.dpdShippingFee;
                            } else {
                              shippingFee = widget.shippingFee;
                            }

                            double totalPayable = _order + shippingFee - widget.discount - _couponDiscount! + widget.tax;

                            return Padding(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                              child: Column(
                                children: [
                                  AmountWidget(
                                      title: getTranslated('sub_total', context),
                                      amount: PriceConverter.convertPrice(context, _order)
                                  ),
                                  AmountWidget(
                                      title: getTranslated('discount', context),
                                      amount: PriceConverter.convertPrice(context, widget.discount)
                                  ),
                                  AmountWidget(
                                      title: getTranslated('coupon_discount', context),
                                      amount: PriceConverter.convertPrice(context, _couponDiscount)
                                  ),
                                  AmountWidget(
                                      title: getTranslated('tax', context),
                                      amount: PriceConverter.convertPrice(context, widget.tax)
                                  ),

                                  AmountWidget(
                                    title: getTranslated('shipping_fee', context),
                                    amount: checkout.isCalculatingFee
                                        ? 'Calculating...'
                                        : PriceConverter.convertPrice(context, shippingFee),
                                  ),

                                  AmountWidget(
                                      title: getTranslated('total_payable', context),
                                      amount: checkout.isCalculatingFee
                                          ? 'Calculating...'
                                          : PriceConverter.convertPrice(context, totalPayable)
                                  ),
                                ],
                              ),
                            );
                          }
                      ),

                      // Order Note
                      Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                getTranslated('order_note', context) ?? '',
                                style: textRegular.copyWith(fontSize: Dimensions.fontSizeLarge)
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            TextField(
                              controller: _orderNoteController,
                              focusNode: _orderNoteNode,
                              decoration: InputDecoration(
                                  hintText: getTranslated('enter_note', context),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)
                                  )
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),

                      // Additional Info (if needed)
                      // if (Provider.of<CheckoutController>(context).selectedShippingMethod == 'Shipday')
                      //   Padding(
                      //     padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      //     child: Column(
                      //       crossAxisAlignment: CrossAxisAlignment.start,
                      //       children: [
                      //         Text(
                      //             'Shipday Delivery Information',
                      //             style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge)
                      //         ),
                      //         const SizedBox(height: Dimensions.paddingSizeSmall),
                      //         Container(
                      //           padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      //           decoration: BoxDecoration(
                      //             color: Theme.of(context).cardColor,
                      //             borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                      //             boxShadow: [
                      //               BoxShadow(
                      //                 color: Colors.grey.withOpacity(0.2),
                      //                 spreadRadius: 1,
                      //                 blurRadius: 7,
                      //                 offset: const Offset(0, 1),
                      //               ),
                      //             ],
                      //           ),
                      //           child: Column(
                      //             crossAxisAlignment: CrossAxisAlignment.start,
                      //             children: [
                      //               Text(
                      //                 'Estimated Delivery Time: 40-60 minutes',
                      //                 style: textRegular.copyWith(
                      //                     color: Theme.of(context).primaryColor
                      //                 ),
                      //               ),
                      //               const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      //               Text(
                      //                 'Delivery Partner: Shipday',
                      //                 style: textRegular,
                      //               ),
                      //               const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      //               Text(
                      //                 'Real-time tracking will be available once the order is picked up',
                      //                 style: textRegular.copyWith(
                      //                   fontSize: Dimensions.fontSizeSmall,
                      //                   color: Theme.of(context).hintColor,
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),

                      // Spacing at bottom
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                    ],
                  ),
                ),
              ],
            );
          }
      ),
    );
  }

  @override
  void dispose() {
    _orderNoteController.dispose();
    _orderNoteNode.dispose();
    super.dispose();
  }
}