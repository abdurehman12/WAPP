import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/interface/repo_interface.dart';

abstract class AuthRepoInterface<T> implements RepositoryInterface{

  Future<ApiResponse> socialLogin(Map<String, dynamic> body);

  Future<ApiResponse> registration(Map<String, dynamic> body);

  Future<ApiResponse> login(String? userInput, String? password, String? type);

  Future<ApiResponse> logout();

  Future<ApiResponse> getGuestId();

  Future<ApiResponse> updateDeviceToken();
  
  String getUserToken();
  
  String? getGuestIdToken();
  
  bool isGuestIdExist();
  
  bool isLoggedIn();
  
  Future<bool> clearSharedData();
  
  Future<bool> clearGuestId();
  
  String getUserEmail();
  
  String getUserPassword();
  
  Future<bool> clearUserEmailAndPassword();

  Future<void> saveUserToken(String token);

  Future<ApiResponse> setLanguageCode(String code);

  Future<ApiResponse> forgetPassword(String identity, String yout);

  Future<void> saveGuestId(String id);

  Future<ApiResponse> sendOtpToEmail(String email, String token);

  Future<ApiResponse> resendEmailOtp(String email, String token);

  Future<ApiResponse> verifyEmail(String email, String code, String token);

  Future<ApiResponse> sendOtpToPhone(String phone,  String token);

  Future<ApiResponse> resendPhoneOtp(String phone,  String token);

  Future<ApiResponse> verifyPhone(String phone,  String otp, String token);

  Future<ApiResponse> verifyOtp(String otp,  String identity);
  
  Future<void> saveUserEmailAndPassword(String userData);

  Future<ApiResponse> resetPassword(String otp,  String identity, String password, String confirmPassword);

  Future<ApiResponse> checkEmail(String mail);

  Future<ApiResponse> checkPhone(String phone);

  Future<ApiResponse> firebaseAuthVerify({required String phoneNumber, required String session, required String otp, required bool isForgetPassword});

  Future<ApiResponse> registerWithOtp(String name, {String? email, required String phone});

  Future<ApiResponse> registerWithSocialMedia(String name, {required String email,String? phone});

  Future<ApiResponse> verifyToken(String email, String token);

  Future<ApiResponse> existingAccountCheck({required String email, required int userResponse, required String medium});

  Future<ApiResponse> verifyProfileInfo(String userInput, String token, String type);

  Future<ApiResponse> firebaseAuthTokenStore(String userInput, String token);

}