import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/message_body.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/chat_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/message_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/services/chat_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/image_size_checker.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:open_file_plus/open_file_plus.dart';

enum SenderType {
  customer,
  seller,
  admin,
  deliveryMan,
  unknown
}

class ChatController extends ChangeNotifier {
  final ChatServiceInterface? chatServiceInterface;
  ChatController({required this.chatServiceInterface});

  bool _isSendButtonActive = false;
  bool get isSendButtonActive => _isSendButtonActive;
  bool _isSearching = false;
  bool get isSearching => _isSearching;
  File? _imageFile;
  File? get imageFile => _imageFile;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  int _userTypeIndex = 0;
  int get userTypeIndex =>  _userTypeIndex;

  ChatModel? chatModel;
  ChatModel? deliverymanChatModel;

  ChatModel? searchChatModel;
  ChatModel? searchDeliverymanChatModel;

  bool sellerChatCall= false;
  bool deliveryChatCall= false;

  bool _isActiveSuffixIcon = false;
  bool get isActiveSuffixIcon => _isActiveSuffixIcon;

  bool _isSearchComplete = false;
  bool get isSearchComplete => _isSearchComplete;

  bool _pickedFIleCrossMaxLimit = false;
  bool get pickedFIleCrossMaxLimit => _pickedFIleCrossMaxLimit;

  bool _pickedFIleCrossMaxLength = false;
  bool get pickedFIleCrossMaxLength => _pickedFIleCrossMaxLength;

  bool _singleFIleCrossMaxLimit = false;
  bool get singleFIleCrossMaxLimit => _singleFIleCrossMaxLimit;

  List<PlatformFile>? objFile;

  String _onImageOrFileTimeShowID = '';
  String get onImageOrFileTimeShowID => _onImageOrFileTimeShowID;

  bool _isClickedOnImageOrFile = false;
  bool get isClickedOnImageOrFile => _isClickedOnImageOrFile;

  bool _isClickedOnMessage = false;
  bool get isClickedOnMessage => _isClickedOnMessage;

  String _onMessageTimeShowID = '';
  String get onMessageTimeShowID => _onMessageTimeShowID;


  Future<void> getChatList( int offset, {bool reload = true, int? userType}) async {
    if(reload){
      notifyListeners();
    }

    if(offset == 1){
      if(offset == 1 && userType == 0){
        deliverymanChatModel = null;
      }else if (offset == 1 && userType == 1) {
        chatModel = null;
      }
      if(userType == null){
        notifyListeners();
      }
    }

    ApiResponse apiResponse = await chatServiceInterface!.getChatList(userType!= null ? userType  == 0 ? 'delivery-man' : 'seller' : _userTypeIndex == 0 ? 'delivery-man' : 'seller', offset);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        if(userType == 0) {
          deliverymanChatModel = null;
          deliverymanChatModel = ChatModel.fromJson(apiResponse.response!.data);
        }else {
          chatModel = null;
          chatModel = ChatModel.fromJson(apiResponse.response!.data);
        }
      }else{
        if(userType == 0) {
          deliverymanChatModel?.chat?.addAll(ChatModel.fromJson(apiResponse.response!.data).chat!);
          deliverymanChatModel?.offset  = (ChatModel.fromJson(apiResponse.response!.data).offset!);
          deliverymanChatModel?.totalSize  = (ChatModel.fromJson(apiResponse.response!.data).totalSize!);
        } else {
          chatModel?.chat?.addAll(ChatModel.fromJson(apiResponse.response!.data).chat!);
          chatModel?.offset  = (ChatModel.fromJson(apiResponse.response!.data).offset!);
          chatModel?.totalSize  = (ChatModel.fromJson(apiResponse.response!.data).totalSize!);
        }
      }
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    // if(userType == null){
      notifyListeners();
    // }
  }

  Future<void> searchChat(BuildContext context, String search, int userIndex) async {
    _isLoading = true;
    searchChatModel = null;
    _isSearchComplete = false;
    notifyListeners();
    ApiResponse apiResponse = await chatServiceInterface!.searchChat(userIndex == 0? 'seller' : 'delivery-man', search);
    if (apiResponse.response != null && apiResponse.response?.statusCode == 200 && apiResponse.response is !List) {
      if(userIndex == 0) {
        searchChatModel = null;
        searchChatModel = ChatModel(totalSize: 1, limit: '10', offset: '1', chat: []);

        apiResponse.response!.data.forEach((chat) => searchChatModel!.chat!.add(Chat.fromJson(chat)));
        searchChatModel?.chat = searchChatModel!.chat;
      } else {
        searchDeliverymanChatModel = null;
        searchDeliverymanChatModel = ChatModel(totalSize: 1, limit: '10', offset: '1', chat: []);

        apiResponse.response!.data.forEach((chat) => searchDeliverymanChatModel!.chat!.add(Chat.fromJson(chat)));
        searchDeliverymanChatModel?.chat = searchDeliverymanChatModel!.chat;
      }
    } else {
      _isLoading = false;
      ApiChecker.checkApi( apiResponse);
    }

    // if(tabController?.index == 0 && searchDeliverymanChatModel!.chat!.isEmpty && searchChatModel!.chat!.isNotEmpty){
    //   tabController?.index = 1;
    // } else if(tabController?.index == 1 && searchChatModel!.chat!.isEmpty && searchDeliverymanChatModel!.chat!.isNotEmpty){
    //   tabController?.index = 0;
    // }

    _isLoading = false;
    _isSearchComplete = true;
    notifyListeners();
  }


  List<String> dateList = [];
  List<dynamic> messageList=[];
  List<Message> allMessageList=[];
  MessageModel? messageModel;

  Future<void> getMessageList(BuildContext context, int? id, int offset, {bool reload = true, int? userType}) async {
    if(reload){
      messageModel = null;
      dateList = [];
      messageList = [];
      allMessageList = [];
    }
    _isLoading = true;
    ApiResponse apiResponse = await chatServiceInterface!.getMessageList(userType != null ? userType == 0 ? 'delivery-man' : 'seller' : _userTypeIndex == 0? 'delivery-man' : 'seller', id, offset);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        messageModel = null;
        dateList = [];
        messageList = [];
        allMessageList = [];
        messageModel = MessageModel.fromJson(apiResponse.response!.data);
        for (var data in messageModel!.message!) {
          if(!dateList.contains(DateConverter.dateStringMonthYear(DateTime.tryParse(data.createdAt!)))) {
            dateList.add(DateConverter.dateStringMonthYear(DateTime.tryParse(data.createdAt!)));
          }
          allMessageList.add(data);
        }
        for(int i=0; i< dateList.length; i++){
          messageList.add([]);
          for (var element in allMessageList) {
            if(dateList[i]== DateConverter.dateStringMonthYear(DateTime.tryParse(element.createdAt!))){
              messageList[i].add(element);
            }
          }
        }
      } else{
        messageModel = MessageModel(message: [], totalSize: 0, offset: '0');
        messageModel?.message = [];
        messageModel!.totalSize =  MessageModel.fromJson(apiResponse.response!.data).totalSize;
        messageModel!.offset =  MessageModel.fromJson(apiResponse.response!.data).offset;
        messageModel!.message!.addAll(MessageModel.fromJson(apiResponse.response!.data).message!) ;

        for (var data in messageModel!.message!) {
          if(!dateList.contains(DateConverter.dateStringMonthYear(DateTime.tryParse(data.createdAt!)))) {
            dateList.add(DateConverter.dateStringMonthYear(DateTime.tryParse(data.createdAt!)));
          }
          allMessageList.add(data);
        }

        for(int i=0; i< dateList.length; i++) {
          messageList.add([]);
          for (var element in allMessageList) {
            if(dateList[i]== DateConverter.dateStringMonthYear(DateTime.tryParse(element.createdAt!))){
              messageList[i].add(element);
            }}
        }
      }
    } else {
      _isLoading = false;
      ApiChecker.checkApi( apiResponse);
    }
    _isLoading = false;
    notifyListeners();
  }



  Future<http.StreamedResponse> sendMessage(MessageBody messageBody,{int? userType}) async {
    _isLoading = true;
    notifyListeners();
    http.StreamedResponse response = await chatServiceInterface!.sendMessage(messageBody, userType != null ? userType == 0 ? 'delivery-man' : 'seller' : _userTypeIndex == 0? 'delivery-man' : 'seller', pickedImageFileStored ?? [], objFile ?? []);

    if (response.statusCode == 200) {
      getMessageList(Get.context!, messageBody.id, 1, reload: false, userType: userType);
      _pickedImageFiles = [];
      pickedImageFileStored = [];
      _isLoading = false;
    } else {
      _isLoading = false;
    }
    _pickedImageFiles = [];
    pickedImageFileStored = [];
    objFile = [];
    _isLoading = false;
    notifyListeners();
    return response;
  }


  Future<ApiResponse> seenMessage(BuildContext context, int? sellerId, int? deliveryId) async {
    ApiResponse apiResponse = await chatServiceInterface!.seenMessage(_userTypeIndex == 0? sellerId!: deliveryId!, _userTypeIndex == 0? 'delivery-man' : 'seller');
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      // await getChatList(1);
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
    return apiResponse;
  }




  void toggleSendButtonActivity() {
    _isSendButtonActive = !_isSendButtonActive;
    notifyListeners();
  }

  void setImage(File image) {
    _imageFile = image;
    _isSendButtonActive = true;
    notifyListeners();
  }

  void removeImage(String text) {
    _imageFile = null;
    text.isEmpty ? _isSendButtonActive = false : _isSendButtonActive = true;
    notifyListeners();
  }

  void toggleSearch() {
    _isSearching = !_isSearching;
    notifyListeners();
  }
  void setUserTypeIndex(BuildContext context, int index, {bool searchActive = false, bool isUpdate = true}) {
    _userTypeIndex = index;
    if(!searchActive){
      // getChatList(1);
    }

    if(isUpdate){
      notifyListeners();
    }
  }

  List <XFile> _pickedImageFiles =[];
  List <XFile>? get pickedImageFile => _pickedImageFiles;
  List <XFile>?  pickedImageFileStored = [];
  void pickMultipleImage(bool isRemove,{int? index}) async {
    _pickedFIleCrossMaxLimit = false;
    _pickedFIleCrossMaxLength = false;
    if(isRemove) {
      if(index != null){
        pickedImageFileStored?.removeAt(index);
      }
    }else {
      _pickedImageFiles = await ImagePicker().pickMultiImage(imageQuality: 40);
      pickedImageFileStored?.addAll(_pickedImageFiles);
    }
    if(pickedImageFileStored!.length > AppConstants.maxLimitOfTotalFileSent){
      _pickedFIleCrossMaxLength = true;
    }
    if( _pickedImageFiles.length == AppConstants.maxLimitOfTotalFileSent && await ImageSize.getMultipleImageSizeFromXFile(pickedImageFileStored!) > AppConstants.maxLimitOfFileSentINConversation){
      _pickedFIleCrossMaxLimit = true;
    }
    notifyListeners();
  }

  void showSuffixIcon(context,String text){
    if(text.isNotEmpty){
      _isActiveSuffixIcon = true;
    }else if(text.isEmpty){
      _isActiveSuffixIcon = false;
      _isSearchComplete = false;
    }
    notifyListeners();
  }


  bool isSameUserWithPreviousMessage(Message? previousConversation, Message currentConversation){
    if(getSenderType(previousConversation) == getSenderType(currentConversation) && previousConversation?.message != null && currentConversation.message !=null){
      return true;
    }
    return false;
  }
  bool isSameUserWithNextMessage( Message currentConversation, Message? nextConversation){
    if(getSenderType(currentConversation) == getSenderType(nextConversation) && nextConversation?.message != null && currentConversation.message !=null){
      return true;
    }
    return false;
  }


  SenderType getSenderType(Message? senderData) {
    if (senderData?.sentByCustomer == true) {
      return SenderType.customer;
    } else if (senderData?.sentBySeller == true) {
      return SenderType.seller;
    } else if (senderData?.sentByAdmin == true) {
      return SenderType.admin;
    } else if (senderData?.sentByDeliveryman == true) {
      return SenderType.deliveryMan;
    } else {
      return SenderType.unknown;
    }
  }



  String getChatTime (String todayChatTimeInUtc , String? nextChatTimeInUtc) {
    String chatTime = '';
    DateTime todayConversationDateTime = DateConverter.isoUtcStringToLocalTimeOnly(todayChatTimeInUtc);
    DateTime nextConversationDateTime;
    DateTime currentDate = DateTime.now();

    if(nextChatTimeInUtc == null){
      String chatTime = DateConverter.isoStringToLocalDateAndTime(todayChatTimeInUtc);
      return chatTime;
    }else{
      nextConversationDateTime = DateConverter.isoUtcStringToLocalTimeOnly(nextChatTimeInUtc);

      // print('====NextConversationTime=====>>${nextConversationDateTime}');
      // print('====TodayConversationTime=====>>${todayConversationDateTime}');
      // print("======>>${chatTime}");
      //
      // print("==IF==01==>>${todayConversationDateTime.difference(nextConversationDateTime) < const Duration(minutes: 30)}");


      if(todayConversationDateTime.difference(nextConversationDateTime) < const Duration(minutes: 30) &&
          todayConversationDateTime.weekday == nextConversationDateTime.weekday){
        chatTime = '';
      }else if(currentDate.weekday != todayConversationDateTime.weekday
          && DateConverter.countDays(todayConversationDateTime) < 6){

        if( (currentDate.weekday -1 == 0 ? 7 : currentDate.weekday -1) == todayConversationDateTime.weekday){
          chatTime = DateConverter.convert24HourTimeTo12HourTimeWithDay(todayConversationDateTime, false);
        }else{
          chatTime = DateConverter.convertStringTimeToDate(todayConversationDateTime);
        }

      }else if(currentDate.weekday == todayConversationDateTime.weekday
          && DateConverter.countDays(todayConversationDateTime) < 6){
        chatTime = DateConverter.convert24HourTimeTo12HourTimeWithDay(todayConversationDateTime, true);
      }else{
        chatTime = DateConverter.isoStringToLocalDateAndTimeConversation(todayChatTimeInUtc);
      }
    }
    return chatTime;
  }

  Future<void> pickOtherFile(bool isRemove, {int? index}) async {
    _pickedFIleCrossMaxLimit = false;
    _pickedFIleCrossMaxLength = false;
    _singleFIleCrossMaxLimit = false;
    List<String> allowedExtentions = ['doc', 'docx', 'txt', 'csv', 'xls', 'xlsx', 'rar', 'tar', 'targz', 'zip', 'pdf'];

    if(isRemove){
      if(objFile!=null){
        objFile!.removeAt(index!);
      }
    }else{
      List<PlatformFile>? platformFile = (await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtentions,
        allowMultiple: true,
        withReadStream: true,
      ))?.files ;

      objFile = [];
      // _pickedImageFiles = [];
      // pickedImageFileStored = [];

      platformFile?.forEach((element) {
        if(ImageSize.getFileSizeFromPlatformFileToDouble(element) > AppConstants.maxSizeOfASingleFile) {
          _singleFIleCrossMaxLimit = true;
        } else{
          if(!allowedExtentions.contains(element.extension)){
            showCustomSnackBar(getTranslated('file_type_should_be', Get.context!), Get.context!);
          } else if(  objFile!.length < AppConstants.maxLimitOfTotalFileSent){
            if((ImageSize.getMultipleFileSizeFromPlatformFiles(objFile!) + ImageSize.getFileSizeFromPlatformFileToDouble(element)) < AppConstants.maxLimitOfFileSentINConversation){
              objFile!.add(element);
            }
          }
        }
      });

      if(objFile?.length == AppConstants.maxLimitOfTotalFileSent && platformFile != null &&   platformFile.length > AppConstants.maxLimitOfTotalFileSent){
        _pickedFIleCrossMaxLength = true;
      }
      if(objFile?.length == AppConstants.maxLimitOfTotalFileSent && platformFile != null && ImageSize.getMultipleFileSizeFromPlatformFiles(platformFile) > AppConstants.maxLimitOfFileSentINConversation){
        _pickedFIleCrossMaxLimit = true;
      }
    }
    notifyListeners();
  }

  List<String> getExtensions(List<PlatformFile> files) {
    return files.map((file) {
      return file.extension ?? '';
    }).toList();
  }

  void downloadFile(String url, String dir, String openFileUrl, String fileName) async {

    var snackBar = const SnackBar(content: Text('Downloading....'),backgroundColor: Colors.black54, duration: Duration(seconds: 1),);
    ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);

    final task  = await FlutterDownloader.enqueue(
      url: url,
      savedDir: dir,
      fileName: fileName,
      showNotification: true,
      saveInPublicStorage: true,
      openFileFromNotification: true,
    );

    if(task !=null){
      await OpenFile.open(openFileUrl);
    }
  }


  String getChatTimeWithPrevious (Message currentChat, Message? previousChat) {
    DateTime todayConversationDateTime = DateConverter
        .isoUtcStringToLocalTimeOnly(currentChat.createdAt ?? "");

    DateTime previousConversationDateTime;

    if (previousChat?.createdAt == null) {
      return 'Not-Same';
    } else {
      previousConversationDateTime =
          DateConverter.isoUtcStringToLocalTimeOnly(previousChat!.createdAt!);
      if (kDebugMode) {
        print("The Difference is ${previousConversationDateTime.difference(todayConversationDateTime) < const Duration(minutes: 30)}");
      }
      if (previousConversationDateTime.difference(todayConversationDateTime) <
          const Duration(minutes: 30) &&
          todayConversationDateTime.weekday ==
              previousConversationDateTime.weekday && isSameUserWithPreviousMessage(currentChat, previousChat)) {
        return '';
      } else {
        return 'Not-Same';
      }
    }

  }


  void toggleOnClickMessage ({required String onMessageTimeShowID}) {
    _onImageOrFileTimeShowID = '';
    _isClickedOnImageOrFile = false;
    if(_isClickedOnMessage && _onMessageTimeShowID != onMessageTimeShowID){
      _onMessageTimeShowID = onMessageTimeShowID;
    }else if(_isClickedOnMessage && _onMessageTimeShowID == onMessageTimeShowID){
      _isClickedOnMessage = false;
      _onMessageTimeShowID = '';
    }else{
      _isClickedOnMessage = true;
      _onMessageTimeShowID = onMessageTimeShowID;
    }
    notifyListeners();
  }


  String? getOnPressChatTime(Message currentConversation){
    if(currentConversation.id.toString() == _onMessageTimeShowID || currentConversation.id.toString() == _onImageOrFileTimeShowID){
      DateTime currentDate = DateTime.now();
      DateTime todayConversationDateTime = DateConverter.isoUtcStringToLocalTimeOnly(
          currentConversation.createdAt ?? ""
      );

      if(currentDate.weekday != todayConversationDateTime.weekday
          && DateConverter.countDays(todayConversationDateTime) <= 7){
        return DateConverter.convertStringTimeToDateChatting(todayConversationDateTime);
      }else if(currentDate.weekday == todayConversationDateTime.weekday
          && DateConverter.countDays(todayConversationDateTime) <= 7){
        return  DateConverter.convert24HourTimeTo12HourTime(todayConversationDateTime);
      }else{
        return DateConverter.isoStringToLocalDateAndTime(currentConversation.createdAt!);
      }
    }else{
      return null;
    }
  }


  void resetIsSearchComplete(){
    _isSearchComplete = false;
    notifyListeners();
  }


}
