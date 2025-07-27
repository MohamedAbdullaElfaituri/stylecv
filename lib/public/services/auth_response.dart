

import '../models/user_model.dart';

class AuthResponse {
  final UserModel? user;
  final String? token;
  final String? error;
  final bool? isNewUser;

  AuthResponse({
    this.user,
    this.token,
    this.error,
    this.isNewUser = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: json['user'] != null ? UserModel.fromMap(json['user']) : null,
      token: json['token'],
      error: json['error'],
    );
  }
}