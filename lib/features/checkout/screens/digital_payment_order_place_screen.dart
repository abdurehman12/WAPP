import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/animated_custom_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/order_place_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_payloads/shipping-payload-integrator.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';


class DigitalPaymentScreen extends StatefulWidget {
  final String url;
  final bool fromWallet;
  final Map<String, dynamic> addressDetails;
  final List<CartModel> cartItems;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final double shippingFee;
  final double calculatedDistance;
  final String generatedOrderId;
  const DigitalPaymentScreen({super.key, required this.url,  this.fromWallet = false, required this.addressDetails,
    required this.cartItems,
    required this.totalAmount,
    required this.taxAmount,
    required this.discountAmount,
    required this.shippingFee,
    required this.calculatedDistance,
    required this.generatedOrderId,});

  @override
  DigitalPaymentScreenState createState() => DigitalPaymentScreenState();
}

class DigitalPaymentScreenState extends State<DigitalPaymentScreen> {
  String? selectedUrl;
  double value = 0.0;
  final bool _isLoading = true;

  late WebViewController controllerGlobal;
  PullToRefreshController? pullToRefreshController;
  late MyInAppBrowser browser;

  @override
  void initState() {
    super.initState();
    selectedUrl = widget.url;
    _initData();
  }

  void _initData() async {
    browser = MyInAppBrowser(context,addressDetails: widget.addressDetails,
      cartItems: widget.cartItems,
      totalAmount: widget.totalAmount,
      taxAmount: widget.taxAmount,
      discountAmount: widget.discountAmount,
      shippingFee: widget.shippingFee,
      calculatedDistance: widget.calculatedDistance,
      generatedOrderId: widget.generatedOrderId,);
    if(!Platform.isIOS){
      await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    }

    var options = InAppBrowserClassOptions(
        crossPlatform: InAppBrowserOptions(hideUrlBar: true, hideToolbarTop: Platform.isAndroid),
        inAppWebViewGroupOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(useShouldOverrideUrlLoading: true, useOnLoadResource: true, javaScriptEnabled: true)));

    await browser.openUrlRequest(
        urlRequest: URLRequest(url: Uri.parse(selectedUrl ?? '')),
        options: options);

  }



  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false,
      onPopInvoked: (val) => _exitApp(context),
      child: Scaffold(
        appBar: AppBar(title: const Text(''),backgroundColor: Theme.of(context).cardColor),
        body: Column(crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,children: [

            _isLoading ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor))) : const SizedBox.shrink()])),
    );
  }

  Future<bool> _exitApp(BuildContext context) async {
    if (await controllerGlobal.canGoBack()) {
      controllerGlobal.goBack();
      return Future.value(false);
    } else {
      Navigator.of(Get.context!).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
      showAnimatedDialog(Get.context!, OrderPlaceDialogWidget(
        icon: Icons.clear,
        title: getTranslated('payment_cancelled', Get.context!),
        description: getTranslated('your_payment_cancelled', Get.context!),
        isFailed: true,
      ), dismissible: false, willFlip: true);
      return Future.value(true);
    }
  }
}



class MyInAppBrowser extends InAppBrowser {

  final BuildContext context;

  final Map<String, dynamic> addressDetails;
  final List<CartModel> cartItems;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final double shippingFee;
  final double calculatedDistance;
  final String generatedOrderId;

  MyInAppBrowser(this.context,  {
    super.windowId,
    super.initialUserScripts,
    required this.addressDetails,
    required this.cartItems,
    required this.totalAmount,
    required this.taxAmount,
    required this.discountAmount,
    required this.shippingFee,
    required this.calculatedDistance,
    required this.generatedOrderId,
  });

  bool _canRedirect = true;

  @override
  Future onBrowserCreated() async {
    if (kDebugMode) {
      print("\n\nBrowser Created!\n\n");
    }
  }

  @override
  Future onLoadStart(url) async {
    if (kDebugMode) {
      print("\n\nStarted: $url\n\n");
    }
    bool isNewUser = getIsNewUser(url.toString());
    _pageRedirect(url.toString(), isNewUser);
  }

  @override
  Future onLoadStop(url) async {
    pullToRefreshController?.endRefreshing();
    if (kDebugMode) {
      print("\n\nStopped: $url\n\n");
    }
    bool isNewUser = getIsNewUser(url.toString());
    _pageRedirect(url.toString(), isNewUser);
  }

  @override
  void onLoadError(url, code, message) {
    pullToRefreshController?.endRefreshing();
    if (kDebugMode) {
      print("Can't load [$url] Error: $message");
    }
  }

  @override
  void onProgressChanged(progress) {
    if (progress == 100) {
      pullToRefreshController?.endRefreshing();
    }
    if (kDebugMode) {
      print("Progress: $progress");
    }
  }


  bool getIsNewUser(String url) {
    List<String> parts = url.split('?');
    if (parts.length < 2) {
      return false;
    }

    String queryString = parts[1];
    List<String> queryParams = queryString.split('&');

    for (String param in queryParams) {
      List<String> keyValue = param.split('=');
      if (keyValue.length == 2) {
        if (keyValue[0] == 'new_user') {
          return keyValue[1] == '1';
        }
      }
    }
    return false;
  }

  @override
  void onExit() {
    if(_canRedirect) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
          builder: (_) => const DashBoardScreen()), (route) => false);



      showAnimatedDialog(context, OrderPlaceDialogWidget(
        icon: Icons.clear,
        title: getTranslated('payment_failed', context),
        description: getTranslated('your_payment_failed', context),
        isFailed: true,
      ), dismissible: false, willFlip: true);
    }

    if (kDebugMode) {
      print("\n\nBrowser closed!\n\n");
    }
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(navigationAction) async {
    if (kDebugMode) {
      print("\n\nOverride ${navigationAction.request.url}\n\n");
    }
    return NavigationActionPolicy.ALLOW;
  }

  @override
  void onLoadResource(resource) {
  }

  @override
  void onConsoleMessage(consoleMessage) {
    if (kDebugMode) {
      print("""
    console output:
      message: ${consoleMessage.message}
      messageLevel: ${consoleMessage.messageLevel.toValue()}
   """);
    }
  }

  void _pageRedirect(String url, bool isNewUser) {
    if(_canRedirect) {
      bool isSuccess = url.contains('success') && url.contains(AppConstants.baseUrl);
      bool isFailed = url.contains('fail') && url.contains(AppConstants.baseUrl);
      bool isCancel = url.contains('cancel') && url.contains(AppConstants.baseUrl);
      if(isSuccess || isFailed || isCancel) {
        _canRedirect = false;
        close();
      }
      if(isSuccess){

        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);


        showAnimatedDialog(context, OrderPlaceDialogWidget(
          icon: Icons.done,
          title: getTranslated( isNewUser ? 'order_placed_Account_Created' : 'order_placed', context ),
          description: getTranslated('your_order_placed', context),
        ), dismissible: false, willFlip: true);

        // Add shipping payload integration
        _sendShippingPayload(
          selectedShippingMethod: 'Shipday', // Replace with the actual selected shipping method
          addressDetails: addressDetails, // Replace with the actual address details
          cartItems: cartItems, // Replace with the actual cart items
          totalAmount: totalAmount, // Replace with the actual total amount
          taxAmount: taxAmount, // Replace with the actual tax amount
          discountAmount: discountAmount, // Replace with the actual discount amount
          shippingFee: shippingFee, // Replace with the actual shipping fee
          calculatedDistance: calculatedDistance, // Replace with the actual calculated distance
          generatedOrderId: generatedOrderId, // Replace with the actual generated order ID
        );

      }else if(isFailed) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
            builder: (_) => const DashBoardScreen()), (route) => false);



        showAnimatedDialog(context, OrderPlaceDialogWidget(
          icon: Icons.clear,
          title: getTranslated('payment_failed', context),
          description: getTranslated('your_payment_failed', context),
          isFailed: true,
        ), dismissible: false, willFlip: true);


      }else if(isCancel) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
            builder: (_) => const DashBoardScreen()), (route) => false);


        showAnimatedDialog(context, OrderPlaceDialogWidget(
          icon: Icons.clear,
          title: getTranslated('payment_cancelled', context),
          description: getTranslated('your_payment_cancelled', context),
          isFailed: true,
        ), dismissible: false, willFlip: true);

      }
    }

  }

  void _sendShippingPayload({
    required String selectedShippingMethod,
    required Map<String, dynamic> addressDetails,
    required List<CartModel> cartItems,
    required double totalAmount,
    required double taxAmount,
    required double discountAmount,
    required double shippingFee,
    required double calculatedDistance,
    required String generatedOrderId,
  }) {
    ShippingPayloadIntegrator(
      shippingMethod: selectedShippingMethod,
      addressDetails: addressDetails,
      cartItems: cartItems,
      totalAmount: totalAmount,
      tax: taxAmount,
      discount: discountAmount,
      deliveryFee: shippingFee,
      distance: calculatedDistance,
      orderId: generatedOrderId,
      onPayloadSent: () {
        print('Shipping payload sent successfully');
      },
    );
  }



}