import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/bouncy_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/screens/order_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/update/screen/update_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/screens/wallet_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/network_info.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/push_notification/models/notification_body.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/color_resources.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/inbox_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/maintenance/maintenance_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/screens/notification_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/onboarding/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  final NotificationBody? body;
  const SplashScreen({super.key, this.body});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldMessengerState> _globalKey = GlobalKey();
  // late StreamSubscription<ConnectivityResult> _onConnectivityChanged;

  @override
  void initState() {
    super.initState();

    // bool firstTime = true;
    // _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
    //   if(!firstTime) {
    //     bool isNotConnected = result != ConnectivityResult.wifi && result != ConnectivityResult.mobile;
    //     isNotConnected ? const SizedBox() : ScaffoldMessenger.of(context).hideCurrentSnackBar();
    //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //       backgroundColor: isNotConnected ? Colors.red : Colors.green,
    //       duration: Duration(seconds: isNotConnected ? 6000 : 3),
    //       content: Text(isNotConnected ? getTranslated('no_connection', context)! : getTranslated('connected', context)!,
    //         textAlign: TextAlign.center)));
    //     if(!isNotConnected) {
    //       _route();
    //     }
    //   }
    //   firstTime = false;
    // });

    _route();
  }

  @override
  void dispose() {
    super.dispose();
    // _onConnectivityChanged.cancel();
  }

  void _route() {
    NetworkInfo.checkConnectivity(context);
    Provider.of<SplashController>(context, listen: false).initConfig(context).then((bool isSuccess) {
      if(isSuccess) {
        String? minimumVersion = "0";
        UserAppVersionControl? appVersion = Provider.of<SplashController>(Get.context!, listen: false).configModel?.userAppVersionControl;
        if(Platform.isAndroid) {
          minimumVersion =  appVersion?.forAndroid?.version ?? '0';
        } else if(Platform.isIOS) {
          minimumVersion = appVersion?.forIos?.version ?? '0';
        }
        Provider.of<SplashController>(Get.context!, listen: false).initSharedPrefData();
        Timer(const Duration(seconds: 1), () {
          final config = Provider.of<SplashController>(Get.context!, listen: false).configModel;

          if(compareVersions(minimumVersion!, AppConstants.appVersion) == 1) {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (_) => const UpdateScreen()));
          } else if(
            //Provider.of<SplashController>(Get.context!, listen: false).configModel!.maintenanceMode!
            config?.maintenanceModeData?.maintenanceStatus == 1 && config?.maintenanceModeData?.selectedMaintenanceSystem?.customerApp == 1
          ) {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(
              builder: (_) => const MaintenanceScreen(),
              settings: const RouteSettings(name: 'MaintenanceScreen'),
            ));
          } else if(Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn()){
            Provider.of<AuthController>(Get.context!, listen: false).updateToken(Get.context!);
            if(widget.body != null){
              if (widget.body!.type == 'order') {
                Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>
                    OrderDetailsScreen(orderId: widget.body!.orderId)));
              } else if(widget.body!.type == 'notification') {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>
                const NotificationScreen()));
              } else if(widget.body!.type == 'wallet') {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => const WalletScreen()));
              } else  if (widget.body!.type == 'chatting') {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>
                InboxScreen(isBackButtonExist: true, fromNotification: true,  initIndex: widget.body!.messageKey ==  'message_from_delivery_man' ? 0 : 1)));
              } else {
                Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>  const NotificationScreen(fromNotification: true,)));
              }
            }else{
              Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => const DashBoardScreen()));
            }
          }

          else if(Provider.of<SplashController>(Get.context!, listen: false).showIntro()!){
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => OnBoardingScreen(
              indicatorColor: ColorResources.grey, selectedIndicatorColor: Theme.of(context).primaryColor)));
          }
          else{
            if(Provider.of<AuthController>(context, listen: false).getGuestToken() != null &&
                Provider.of<AuthController>(context, listen: false).getGuestToken() != '1'){
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => const DashBoardScreen()));
            }else{
              Provider.of<AuthController>(context, listen: false).getGuestIdUrl();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
            }
          }
        });
      }
    });
  }


  int compareVersions(String version1, String version2) {
    List<String> v1Components = version1.split('.');
    List<String> v2Components = version2.split('.');
    for (int i = 0; i < v1Components.length; i++) {
      int v1Part = int.parse(v1Components[i]);
      int v2Part = int.parse(v2Components[i]);
      if (v1Part > v2Part) {
        return 1;
      } else if (v1Part < v2Part) {
        return -1;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      key: _globalKey,
      body: Provider.of<SplashController>(context).hasConnection ?
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        BouncyWidget(
            duration: const Duration(milliseconds: 2000), lift: 50, ratio: 0.5, pause: 0.25,
            child: SizedBox(width: 150, child: Image.asset(Images.logoImage, color: Colors.white, width: 150.0))),
        Text(AppConstants.appName,style: textRegular.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: Colors.white)),
        Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            child: Text(AppConstants.slogan,style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white)))]),
      ) : const NoInternetOrDataScreenWidget(isNoInternet: true, child: SplashScreen()),
    );
  }
}
