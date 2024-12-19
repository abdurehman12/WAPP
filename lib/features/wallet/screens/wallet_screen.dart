import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/shimmers/transaction_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/controllers/wallet_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/widgets/transaction_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/widgets/wallet_bonus_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/widgets/wallet_card_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/color_resources.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_loggedin_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/widgets/transaction_filter_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/aster_theme_home_screen.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';


class WalletScreen extends StatefulWidget {
  final bool isBacButtonExist;
  const WalletScreen({super.key, this.isBacButtonExist = true});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final tooltipController = JustTheController();
  final TextEditingController inputAmountController = TextEditingController();
  final FocusNode focusNode = FocusNode();


  final ScrollController scrollController = ScrollController();
  bool darkMode = Provider.of<ThemeController>(Get.context!, listen: false).darkTheme;
  bool isGuestMode = !Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn();

  @override
  void initState() {
    if(Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
      Provider.of<ProfileController>(context, listen: false).getUserInfo(context);
      Provider.of<WalletController>(context, listen: false).getWalletBonusBannerList();
      Provider.of<WalletController>(context, listen: false).setSelectedFilterType('All Transaction', 0, reload: false);

    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvoked: (val){
        if(Navigator.canPop(context)){
          return;
        }else{
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=> const DashBoardScreen()), (route) => false);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
          body: RefreshIndicator(
            color: Theme.of(context).cardColor,
            backgroundColor: Theme.of(context).primaryColor,
            onRefresh: () async {
              Provider.of<WalletController>(context, listen: false).getTransactionList(context,1, "all", reload: true);
            },
            child: CustomScrollView(
              controller: scrollController, slivers: [
                SliverAppBar(floating: true,
                  pinned: true,
                  iconTheme:  IconThemeData(color: ColorResources.getTextTitle(context)),
                  backgroundColor: Theme.of(context).cardColor,
                  title: Text(getTranslated('wallet', context)!,style: TextStyle(color: ColorResources.getTextTitle(context)),),),

              SliverToBoxAdapter(
                child: Column(children: [

                  isGuestMode ? NotLoggedInWidget(message: getTranslated('to_view_the_wishlist', context)) :
                  Column(children: [
                    Consumer<WalletController>(builder: (context, walletP,_) {
                    return Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                        child: Container(height: MediaQuery.of(context).size.width/3.0,
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                          margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                          decoration: BoxDecoration(color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                          Theme.of(context).cardColor : Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                              boxShadow: [BoxShadow(color: Colors.grey[darkMode ? 900 : 200]!, spreadRadius: 0.5, blurRadius: 0.3)]),
                          child: WalletCardWidget(tooltipController: tooltipController, focusNode: focusNode,
                              inputAmountController: inputAmountController),));}),

                    const WalletBonusWidget()

                  ])],)),


               SliverPersistentHeader(pinned: true,delegate: SliverDelegate(child: Container(
                 color: Theme.of(context).scaffoldBackgroundColor,
                 child: Column(children: [
                   const SizedBox(height: Dimensions.paddingSizeLarge,),
                   Consumer<WalletController>(builder: (context, transactionProvider, child) {
                       return Padding(padding: const EdgeInsets.only(left: Dimensions.homePagePadding,right: Dimensions.homePagePadding),
                         child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                           Text('${getTranslated('wallet_history', context)}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),),

                           InkWell(onTap: ()=> showModalBottomSheet(backgroundColor: Colors.transparent,
                               context: context, builder: (_)=> const TransactionFilterBottomSheetWidget()),
                             child: Container(width: MediaQuery.of(context).size.width * .5, height: 35,
                                 decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                                     color: Theme.of(context).cardColor, border: Border.all(color: Colors.grey)),
                                 child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                                   child: Row(children: [
                                     Expanded(child: Text('${getTranslated(transactionProvider.selectedFilterType, context)}',
                                         maxLines: 1,overflow: TextOverflow.ellipsis)),
                                     const Icon(Icons.arrow_drop_down)])))),
                         ]));
                     })])), height: 60)),

                SliverToBoxAdapter(
                  child: isGuestMode ? const NotLoggedInWidget() : Consumer<WalletController>(
                    builder: (context, walletController, _) {
                      return (walletController.walletTransactionModel?.walletTransactioList?.isNotEmpty ?? false) ?  PaginatedListView(
                        scrollController: scrollController,
                        onPaginate: (int? offset) async => await  walletController.getTransactionList(context, offset ?? 1, walletController.selectedFilterType, reload: false),
                        totalSize: walletController.walletTransactionModel?.totalWalletTransactio,
                        offset: walletController.walletTransactionModel?.offset,
                        itemView: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: walletController.walletTransactionModel?.walletTransactioList?.length,
                          itemBuilder: (ctx,index){
                            return TransactionWidget(
                              transactionModel: walletController.walletTransactionModel?.walletTransactioList?[index],
                              isLastIndex: index + 1 == walletController.walletTransactionModel?.walletTransactioList?.length,
                            );

                          },
                        ),

                      ) : (walletController.walletTransactionModel?.walletTransactioList?.isEmpty ?? false) ?  const NoInternetOrDataScreenWidget(
                        isNoInternet: false, message: 'no_transaction_history', icon: Images.noTransaction,
                      ) : const TransactionShimmer();
                    }
                  ),
                )
              ],
            ),
          )

      ),
    );
  }
}






