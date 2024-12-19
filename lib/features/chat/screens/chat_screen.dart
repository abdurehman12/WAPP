import 'dart:io';

// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/message_body.dart';
import 'package:flutter_sixvalley_ecommerce/helper/image_size_checker.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/widgets/chat_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/widgets/message_bubble_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' as foundation;

class ChatScreen extends StatefulWidget {
  final int? id;
  final String? name;
  final bool isDelivery;
  final String? image;
  final String? phone;
  final bool shopClose;
  final int? userType;
  const ChatScreen({super.key,  this.id, required this.name,  this.isDelivery = false,  this.image, this.phone, this.shopClose = false, this.userType});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  ScrollController scrollController = ScrollController();
  bool emojiPicker = false;

  bool isClosed = false;
  void clickedOnClose(){
    setState(() {
      isClosed = true;
    });
  }


  @override
  void initState() {
    loadDaa();
    super.initState();
  }

  Future<void> loadDaa() async{
   await Provider.of<ChatController>(context, listen: false).getMessageList( context, widget.id, 1, userType: widget.userType);
  }


  @override
  Widget build(BuildContext context) {

    return RefreshIndicator(
      onRefresh: ()async{
        loadDaa();
      },
      child: Scaffold(

        appBar: AppBar(backgroundColor: Theme.of(context).cardColor,
          titleSpacing: 0,
          elevation: 1,
          leading: InkWell(onTap: ()=> Navigator.pop(context),
              child: Icon(CupertinoIcons.back, color: Theme.of(context).textTheme.bodyLarge?.color)),
          title: Row(children: [

            ClipRRect(borderRadius: BorderRadius.circular(100),
              child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(100),
                      border: Border.all(width: .5, color: Theme.of(context).primaryColor.withOpacity(.125))),
                  height: 40, width: 40,child: CustomImageWidget(image: widget.image??''))),


            Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: Text(widget.name??'', style: textRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)))]),
          actions: widget.isDelivery? [InkWell(
            onTap: ()=> _launchUrl("tel:${widget.phone}"),
            child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Container(decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(.125),
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
                  height: 35, width: 35,child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    child: Image.asset(Images.callIcon, color: Theme.of(context).primaryColor)))),
          )]:[]),

        body: Stack(
          children: [
            Consumer<ChatController>(
                builder: (context, chatProvider,child) {
                return Column(children: [
                  chatProvider.messageModel != null? (chatProvider.messageModel!.message != null && chatProvider.messageModel!.message!.isNotEmpty)?
                  Expanded(child:  SingleChildScrollView(controller: scrollController,
                    reverse: true,
                    child: Padding(padding:  const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                      child: PaginatedListView(
                        reverse: false,
                        scrollController: scrollController,
                        onPaginate: (int? offset) => chatProvider.getMessageList(context,widget.id,offset!, reload: false),
                        totalSize: chatProvider.messageModel!.totalSize,
                        offset: int.parse(chatProvider.messageModel!.offset!),
                        enabledPagination: chatProvider.messageModel == null,
                        itemView: ListView.builder(
                          itemCount: chatProvider.dateList.length,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return  Column(mainAxisSize: MainAxisSize.min, children: [
                              Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall,
                                vertical: Dimensions.paddingSizeSmall),
                                child: Text(chatProvider.dateList[index].toString(),
                                  style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.5)),
                                  textDirection: TextDirection.ltr)),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: chatProvider.messageList[index].length,
                                  itemBuilder: (context, subIndex){
                                  if(subIndex !=0){
                                    return MessageBubbleWidget(
                                      message: chatProvider.messageList[index][subIndex],
                                      previous: subIndex == (chatProvider.messageList[index].length -1) ?  null :
                                      chatProvider.messageList[index].elementAt(subIndex+1),
                                      next: chatProvider.messageList[index][subIndex-1],
                                    );
                                  }else{
                                    return MessageBubbleWidget(
                                      message: chatProvider.messageList[index][subIndex],
                                      previous: subIndex == (chatProvider.messageList[index].length -1) ?  null :
                                      chatProvider.messageList[index].elementAt(subIndex+1),
                                    );
                                  }
                              })
                            ],);
                          },
                        ),
                      ),
                    )),
                  ) : const Expanded(child: NoInternetOrDataScreenWidget(isNoInternet: false)):
                  const Expanded(child: ChatShimmerWidget()),



                  Container(
                    color:  chatProvider.isLoading == false && ((chatProvider.pickedImageFileStored!=null && chatProvider.pickedImageFileStored!.isNotEmpty) || (chatProvider.objFile != null && chatProvider.objFile!.isNotEmpty)) ?
                    Theme.of(context).primaryColor.withOpacity(0.1) : null,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ((chatProvider.pickedImageFileStored!=null && chatProvider.pickedImageFileStored!.isNotEmpty)  || (chatProvider.objFile != null && chatProvider.objFile!.isNotEmpty)) ?
                          const SizedBox(height: Dimensions.paddingSizeSmall) : const SizedBox(),

                        // Bottom TextField
                        (chatProvider.pickedImageFileStored != null && chatProvider.pickedImageFileStored!.isNotEmpty) ?
                        Container(
                            height: (chatProvider.pickedFIleCrossMaxLimit || chatProvider.pickedFIleCrossMaxLength || chatProvider.singleFIleCrossMaxLimit) ? 110 : 90,
                            width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 80,
                                child: ListView.builder(scrollDirection: Axis.horizontal,
                                  itemBuilder: (context,index){
                                    return  Stack(children: [
                                      Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                                          child: ClipRRect(borderRadius: BorderRadius.circular(10),
                                              child: SizedBox(height: 80, width: 80,
                                                  child: Image.file(File(chatProvider.pickedImageFileStored![index].path), fit: BoxFit.cover)))),


                                      Positioned(right: 5, child: InkWell(child: const Icon(Icons.cancel_outlined, color: Colors.red),
                                          onTap: () => chatProvider.pickMultipleImage(true,index: index)))],
                                    );}, itemCount: chatProvider.pickedImageFileStored!.length,
                                ),
                              ),

                              if(chatProvider.pickedFIleCrossMaxLimit || chatProvider.pickedFIleCrossMaxLength || chatProvider.singleFIleCrossMaxLimit)
                                Text( "${chatProvider.pickedFIleCrossMaxLength ? "• ${getTranslated('can_not_select_more_than', context)!} ${AppConstants.maxLimitOfTotalFileSent.floor()} 'files' " :""} "
                                    "${chatProvider.pickedFIleCrossMaxLimit ? "• ${getTranslated('total_images_size_can_not_be_more_than', context)!} ${AppConstants.maxLimitOfFileSentINConversation.floor()} MB" : ""} "
                                    "${chatProvider.singleFIleCrossMaxLimit ? "• ${getTranslated('single_file_size_can_not_be_more_than', context)!} ${AppConstants.maxSizeOfASingleFile.floor()} MB" : ""} ",
                                  style: textRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                                  ),
                                ),

                            ],

                          )
                        ) : const SizedBox(),


                        chatProvider.objFile != null && chatProvider.objFile!.isNotEmpty && chatProvider.isLoading == false ?
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 70,
                                child: ListView.separated(
                                  shrinkWrap: true, scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.only(bottom: 5),
                                  separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
                                  itemCount: chatProvider.objFile!.length,
                                  itemBuilder: (context, index){
                                    String fileSize =  ImageSize.getFileSizeFromPlatformFileToString(chatProvider.objFile![index]);
                                    return Container(width: 180,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                      ),
                                      padding: const EdgeInsets.only(left: 10, right: 5),
                                      child: Row(crossAxisAlignment: CrossAxisAlignment.center,children: [

                                        Image.asset(Images.fileIcon,height: 30, width: 30,),
                                        const SizedBox(width: Dimensions.paddingSizeExtraSmall,),

                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.center, children: [

                                          Text(chatProvider.objFile![index].name,
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                                          ),

                                          Text(fileSize, style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                                            color: Theme.of(context).hintColor,
                                          )),
                                        ])),


                                        InkWell(
                                          onTap: () {
                                            chatProvider.pickOtherFile(true, index: index);
                                          },
                                          child: Padding(padding: const EdgeInsets.only(top: 5),
                                            child: Align(alignment: Alignment.topRight,
                                              child: Icon(Icons.close,
                                                size: Dimensions.paddingSizeLarge,
                                                color: Theme.of(context).hintColor,
                                              ),
                                            ),
                                          ),
                                        )
                                      ]),
                                    );
                                  },
                                ),
                              ),


                              if(chatProvider.pickedFIleCrossMaxLimit || chatProvider.pickedFIleCrossMaxLength || chatProvider.singleFIleCrossMaxLimit)
                                Text( "${chatProvider.pickedFIleCrossMaxLength ? "• ${getTranslated('can_not_select_more_than', context)!} ${AppConstants.maxLimitOfTotalFileSent.floor()} 'files' " :""} "
                                    "${chatProvider.pickedFIleCrossMaxLimit ? "• ${getTranslated('total_images_size_can_not_be_more_than', context)!} ${AppConstants.maxLimitOfFileSentINConversation.floor()} MB" : ""} "
                                    "${chatProvider.singleFIleCrossMaxLimit ? "• ${getTranslated('single_file_size_can_not_be_more_than', context)!} ${AppConstants.maxSizeOfASingleFile.floor()} MB" : ""} ",
                                  style: textRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                        ) : const SizedBox(),


                        Padding(padding: const EdgeInsets.fromLTRB( Dimensions.paddingSizeDefault,  0,
                            Dimensions.paddingSizeSmall,  Dimensions.paddingSizeDefault),
                          child: SizedBox(height: 60,
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Expanded(child: CustomTextFieldWidget(
                                inputAction: TextInputAction.send,
                                //showLabelText: false,
                                prefixIcon: Images.emoji,
                                prefixColor: Theme.of(context).colorScheme.onSecondary.withOpacity(0.50),
                                suffixIcon: Images.attachment,
                                suffixIcon2: Images.file,
                                suffixColor: Theme.of(context).primaryColor,
                                isPassword: false,
                                onTap: (){
                                  setState(() {
                                    emojiPicker = false;
                                  });
                                },
                                prefixOnTap: (){
                                  setState(() {
                                    emojiPicker = !emojiPicker;
                                    FocusManager.instance.primaryFocus?.unfocus();
                                  });
                                },
                                suffixOnTap: (){
                                  chatProvider.pickMultipleImage(false);
                                },
                                suffix2OnTap: (){
                                  chatProvider.pickOtherFile(false);
                                },
                                controller: _controller,
                                labelText: getTranslated('send_a_message', context),
                                hintText: getTranslated('send_a_message', context))),
                              const SizedBox(width: Dimensions.paddingSizeDefault,),

                              chatProvider.isSendButtonActive ? const Padding(
                                  padding: EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall),
                                  child: Center(child: CircularProgressIndicator())):

                              InkWell(onTap: (){
                                if(_controller.text.isEmpty && chatProvider.pickedImageFileStored!.isEmpty && chatProvider.objFile!.isEmpty){

                                }else{
                                  MessageBody messageBody = MessageBody(id : widget.id,  message: _controller.text);
                                  chatProvider.sendMessage(messageBody, userType: widget.userType).then((value){
                                    _controller.clear();
                                  });
                                }
                              },

                              child: chatProvider.isLoading ? const Padding(padding: EdgeInsets.all(8.0),
                                child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator())) :

                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(width: 50, height: 50, decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                    border: Border.all(width: 2, color: Theme.of(context).hintColor)),
                                    child: Center(child: Padding(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeExtraExtraSmall,
                                        Dimensions.paddingSizeExtraExtraSmall, Dimensions.paddingSizeExtraExtraSmall,8),
                                        child: Image.asset(Images.send, color: Provider.of<ThemeController>(context).darkTheme ? Colors.white: null)))),
                                ),
                              ),

                            ]),
                          ),
                        ),

                      ],
                    ),
                  ),







                  // if(emojiPicker)
                  //   SizedBox(height: 250,
                  //     child: EmojiPicker(
                  //       onBackspacePressed: () {},
                  //       textEditingController: _controller,
                  //       config: Config(
                  //         height: 256,
                  //         checkPlatformCompatibility: true,
                  //         emojiViewConfig: EmojiViewConfig(
                  //           // Issue: https://github.com/flutter/flutter/issues/28894
                  //           emojiSizeMax: 28 *
                  //               (foundation.defaultTargetPlatform ==
                  //                   TargetPlatform.iOS
                  //                   ? 1.2
                  //                   : 1.0),
                  //         ),
                  //         swapCategoryAndBottomBar: false,
                  //         skinToneConfig: const SkinToneConfig(),
                  //         categoryViewConfig: const CategoryViewConfig(),
                  //         bottomActionBarConfig: const BottomActionBarConfig(),
                  //         searchViewConfig: const SearchViewConfig(),
                  //         // columns: 7,
                  //         // emojiSizeMax: 32 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0),
                  //         // verticalSpacing: 0,
                  //         // horizontalSpacing: 0,
                  //         // gridPadding: EdgeInsets.zero,
                  //         // initCategory: Category.RECENT,
                  //         // bgColor: const Color(0xFFF2F2F2),
                  //         // indicatorColor: Colors.blue,
                  //         // iconColor: Colors.grey,
                  //         // iconColorSelected: Colors.blue,
                  //         // backspaceColor: Colors.blue,
                  //         // skinToneDialogBgColor: Colors.white,
                  //         // skinToneIndicatorColor: Colors.grey,
                  //         // enableSkinTones: true,
                  //         // recentTabBehavior: RecentTabBehavior.RECENT,
                  //         // recentsLimit: 28,
                  //         // noRecents: const Text('No Recents', style: TextStyle(fontSize: 20, color: Colors.black26),
                  //         //   textAlign: TextAlign.center), // Needs to be const Widget
                  //         // loadingIndicator: const SizedBox.shrink(), // Needs to be const Widget
                  //         // tabIndicatorAnimDuration: kTabScrollDuration,
                  //         // categoryIcons: const CategoryIcons(),
                  //         // buttonMode: ButtonMode.MATERIAL,
                  //       ),
                  //     ),
                  //   ),
                ]);
              }
            ),

            if(widget.shopClose && !isClosed)
              Container(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                decoration: const BoxDecoration(color: Color(0xFFFEF7D1)),
                child: Row(children: [
                  Expanded(child: Text("${getTranslated("shop_close_message", context)}",
                    style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color))),
                  const SizedBox(width: Dimensions.paddingSizeSmall,),
                  InkWell(onTap: ()=> clickedOnClose(),
                    child: Icon(Icons.cancel, size: 35, color: Theme.of(context).hintColor, ))
                ],
              ),)
          ],
        ),
      ),
    );
  }
}



Future<void> _launchUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw 'Could not launch $url';
  }
}

