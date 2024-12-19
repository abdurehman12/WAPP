import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/seller_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/controllers/coupon_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/color_resources.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/title_row_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/shop_coupon_item_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/shop_featured_product_list_view.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/shop_recommanded_product_list.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ShopOverviewScreen extends StatefulWidget {
  final int sellerId;
  final ScrollController scrollController;
  const ShopOverviewScreen({super.key, required this.sellerId, required this.scrollController});

  @override
  State<ShopOverviewScreen> createState() => _ShopOverviewScreenState();
}

class _ShopOverviewScreenState extends State<ShopOverviewScreen> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    return Consumer<CouponController>(
      builder: (context, couponController, _) {

        return  Column(
          mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: Dimensions.paddingSizeSmall),

              couponController.couponItemModel != null? (couponController.couponItemModel!.coupons != null && couponController.couponItemModel!.coupons!.isNotEmpty)?

              couponController.couponItemModel != null? (couponController.couponItemModel!.coupons != null &&
                  couponController.couponItemModel!.coupons!.isNotEmpty)?
              Stack(children: [
                CarouselSlider.builder(
                  options: CarouselOptions(
                      viewportFraction: 1,
                      aspectRatio: 16 / (size.width > 380 ? 7 : 9),
                      autoPlay: couponController.couponItemModel!.coupons!.length > 1? true : false,
                      enlargeCenterPage: true,
                      disableCenter: true,
                      onPageChanged: (index, reason) {
                        couponController.setCurrentIndex(index);
                      }),

                  itemCount: couponController.couponItemModel!.coupons!.length,
                  itemBuilder: (context, index, _)=> ShopCouponItem(coupons: couponController.couponItemModel!.coupons![index]),
                ),

                Positioned.fill(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Consumer<CouponController>(
                        builder: (context, couponController, _) {
                          return Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: couponController.couponItemModel!.coupons!.map((banner) {
                                int index = couponController.couponItemModel!.coupons!.indexOf(banner);
                                return TabPageSelectorIndicator(backgroundColor: index == couponController.couponCurrentIndex ?
                                Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(.25),
                                    borderColor: index == couponController.couponCurrentIndex ?
                                    Theme.of(context).primaryColor : Theme.of(context).primaryColor.withOpacity(.25), size: 7);
                              }).toList());
                        }
                    ),
                  ),
                )),

                Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge, vertical: Dimensions.paddingSizeDefault),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('${couponController.couponCurrentIndex+1}',
                            style: textMedium.copyWith(color: Theme.of(context).primaryColor),),
                          Text('/${couponController.couponItemModel!.coupons!.length}',
                            style: textRegular.copyWith(color: Theme.of(context).hintColor),),
                        ]),
                      ),
                    )),
              ]) :

            Center(child: Text('${getTranslated('no_coupon_available', context)}')) : Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              enabled: couponController.couponItemModel!.coupons == null,
              child: Container(margin: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), color: ColorResources.white))): const SizedBox() : const Center(child: SizedBox()),



          const SizedBox(height: Dimensions.paddingSizeSmall),
          Consumer<SellerProductController>(
            builder: (context, productController, _) {
              return TitleRowWidget(title: productController.sellerWiseFeaturedProduct != null ?
              (productController.sellerWiseFeaturedProduct!.products != null &&
                  productController.sellerWiseFeaturedProduct!.products!.isNotEmpty)?
              getTranslated('featured_products', context) : getTranslated('recommanded_products', context) : '');
            }),


            Consumer<SellerProductController>(
              builder: (context, productController, _) {
                return Padding(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall,
                    Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, 0),
                  child: ShopFeaturedProductViewList(scrollController: widget.scrollController, sellerId: widget.sellerId));
              }
            ),


            Consumer<SellerProductController>(
              builder: (context, productController, _) {
                return (productController.sellerWiseFeaturedProduct != null &&
                    productController.sellerWiseFeaturedProduct!.products != null &&
                    productController.sellerWiseFeaturedProduct!.products!.isEmpty)?
                Padding(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall,
                    Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, 0),
                  child: ShopRecommandedProductViewList(scrollController: widget.scrollController,
                      sellerId: widget.sellerId),): const SizedBox();
              })]);
      }
    );
  }
}
