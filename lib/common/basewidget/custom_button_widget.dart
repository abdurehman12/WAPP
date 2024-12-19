import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class CustomButton extends StatelessWidget {
  final Function()? onTap;
  final String? buttonText;
  final bool isBuy;
  final bool isBorder;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? radius;
  final double? fontSize;
  final String? leftIcon;
  final double? borderWidth;
  final bool isLoading;


  const CustomButton({
    super.key, this.onTap, required this.buttonText, this.isBuy= false,
    this.isBorder = false, this.backgroundColor, this.radius, this.textColor,
    this.fontSize, this.leftIcon, this.borderColor, this.borderWidth,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onTap as void Function()?,
      style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
      child: Container(height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: isBorder? Border.all(color: borderColor??Theme.of(context).primaryColor, width:  borderWidth ??1): null,
          color: onTap == null ? Theme.of(context).disabledColor : backgroundColor ?? (isBuy? const Color(0xffFE961C) : Theme.of(context).primaryColor),
            borderRadius: BorderRadius.circular(radius !=null ? radius! : isBorder? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeSmall)),
        child: isLoading ? Center(child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 15, width: 15,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Text(getTranslated('loading', context)!, style: textBold.copyWith(color: Colors.white)),
          ],
        )) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if(leftIcon != null)
            Padding(padding: const EdgeInsets.only(right: 5),
              child: SizedBox(width: 30, child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: Image.asset(leftIcon!),
              )),
            ),
            Flexible(
              child: Text(buttonText??"", style: titilliumSemiBold.copyWith(fontSize: fontSize?? 16,
                    color: textColor ?? (Provider.of<ThemeController>(context, listen: false).darkTheme? Colors.white : Theme.of(context).highlightColor),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
