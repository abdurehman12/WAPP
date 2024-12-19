import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_directionality_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/domain/models/coupon_item_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';

class ShopCouponItem extends StatefulWidget {
  final Coupons coupons;
  const ShopCouponItem({super.key, required this.coupons});

  @override
  State<ShopCouponItem> createState() => _ShopCouponItemState();
}

class _ShopCouponItemState extends State<ShopCouponItem> {
  final tooltipController = JustTheController();
  @override
  Widget build(BuildContext context) {
    final bool isLtr = Provider.of<LocalizationController>(context, listen: false).isLtr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Stack(clipBehavior: Clip.none, children: [
        ClipRRect(clipBehavior: Clip.none,
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
            child: Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(color: Theme.of(context).cardColor,
                  boxShadow: Provider.of<ThemeController>(context, listen: false).darkTheme ? null :
                  [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(.12), spreadRadius: 1, blurRadius: 1, offset: const Offset(0,1))],
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(.125))),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.start, children: [
                  Expanded(flex: 4, child: Padding(
                    padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      // mainAxisSize: MainAxisSize.min,
                      children: [

                        SizedBox(width: 30,child: Image.asset(
                          color: widget.coupons.discountType == 'percentage' ? Theme.of(context).primaryColor : null,
                          widget.coupons.couponType == 'free_delivery'
                              ? Images.freeCoupon : widget.coupons.discountType == 'percentage'
                              ? Images.offerIcon : Images.firstOrder,
                        )),

                        widget.coupons.couponType == 'free_delivery'?
                        Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                          child: Text('${getTranslated('free_delivery', context)}',
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),),
                        ):

                        widget.coupons.discountType == 'percentage'?
                        Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                            child: Text('${widget.coupons.discount} ${'% ${getTranslated('off', context)}'}',
                              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).primaryColor),)):
                        Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                          child: Text('${PriceConverter.convertPrice(context, widget.coupons.discount)} ${getTranslated('OFF', context)}',
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).primaryColor),),
                        ),
                        Text(getTranslated(widget.coupons.couponType, context)??'',
                            style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault))
                      ],
                    ),
                  )),

                  Expanded(flex: 6,
                      child: Padding(padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                        child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center,children: [

                          Stack(children: [
                            Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                border: Border.all(color: Theme.of(context).primaryColor),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                              child: Padding(
                                padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                                child: Text(widget.coupons.code ??'', style: titleRegular.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge)),
                              ),
                            ),

                            Positioned.fill(child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                  transform: Matrix4.translationValues(0, -15, 0),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeDefault,
                                    vertical: Dimensions.paddingSizeExtraSmall,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  child: Text('${getTranslated('coupon_code', context)}', style: textMedium.copyWith(
                                    color: Colors.white, fontSize: Dimensions.fontSizeDefault,
                                  )),
                              ),
                            )),
                          ]),
                          const SizedBox(height: Dimensions.paddingSizeSmall),


                          Text('${getTranslated('available_till', context)} ''${
                              DateConverter.estimatedDate(DateTime.parse(widget.coupons.expireDatePlanText!))
                          }', style: textRegular),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),


                          CustomDirectionalityWidget(
                            child: Text('${getTranslated('minimum_purchase_amount', context)} ${PriceConverter.convertPrice(context, widget.coupons.minPurchase)}',
                                style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall), textAlign: TextAlign.center,),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                        ]))),
                  const SizedBox(width: Dimensions.paddingSizeLarge,)
                ])))),

        Positioned.fill(child: Align(alignment: isLtr ? Alignment.topRight : Alignment.topLeft, child: JustTheTooltip(
          backgroundColor: Colors.black87,
          controller: tooltipController,
          preferredDirection: AxisDirection.down,
          tailLength: 10,
          tailBaseWidth: 20,
          content: Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Text(getTranslated('copied', context)!, style: textRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault)),
          ),
          child: InkWell(
              onTap: () async {
                tooltipController.showTooltip();
                await Clipboard.setData(ClipboardData(text: widget.coupons.code??''));
              },
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Icon(Icons.copy_rounded, color: Theme.of(context).primaryColor,size: 30),
              )),
        ))),


      ]),
    );
  }
}