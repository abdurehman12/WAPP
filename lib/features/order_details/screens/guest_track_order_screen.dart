import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/screens/order_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/velidate_check.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:provider/provider.dart';

class GuestTrackOrderScreen extends StatefulWidget {
  const GuestTrackOrderScreen({super.key});

  @override
  State<GuestTrackOrderScreen> createState() => _GuestTrackOrderScreenState();
}

class _GuestTrackOrderScreenState extends State<GuestTrackOrderScreen> {
  TextEditingController orderIdController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(title: getTranslated('TRACK_ORDER', context)),
      body: Consumer<OrderDetailsController>(
        builder: (context, orderTrackingProvider, _) {
          return Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Form(
              key: formKey,
              child: ListView(children: [
                const SizedBox(height: Dimensions.paddingSizeSmall),
                CustomTextFieldWidget(controller: orderIdController,
                  prefixIcon: Images.orderIdIcon,
                  isAmount: true,
                  inputType: TextInputType.phone,
                  hintText: getTranslated('order_id', context),
                  labelText: getTranslated('order_id', context),
                  required: true,
                  showLabelText: false,
                  validator: (value)=> ValidateCheck.validateEmptyText(value, 'order_id_is_required'),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),


                CustomTextFieldWidget(
                  isAmount: true,
                  inputType: TextInputType.phone,
                  prefixIcon: Images.callIcon,
                  controller: phoneNumberController,
                  inputAction: TextInputAction.done,
                  hintText: '123 1235 123',
                  required: true,
                  labelText: '${getTranslated('phone_number', context)}',
                  showLabelText: false,
                  validator: (value)=> ValidateCheck.validateEmptyText(value, 'phone_number_is_required'),

                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                CustomButton(
                  isLoading: orderTrackingProvider.searching,
                  buttonText: '${getTranslated('search_order', context)}',
                  onTap: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    String orderId = orderIdController.text.trim();
                    String phone = phoneNumberController.text.trim();

                    if(formKey.currentState?.validate() ?? false) {
                      await orderTrackingProvider.trackOrder(orderId: orderId.toString(), phoneNumber: phone, isUpdate: true).then((value) {
                        if(value.response?.statusCode == 200){
                          Navigator.push(context, MaterialPageRoute(builder: (_)=> OrderDetailsScreen(
                            fromTrack: true,
                            orderId: int.parse(orderIdController.text.trim()),
                            phone: phone,
                          )));
                        }
                      });
                    }
                  },
                ),

              ]),
            ),
          );
        }
      )
    );
  }
}
