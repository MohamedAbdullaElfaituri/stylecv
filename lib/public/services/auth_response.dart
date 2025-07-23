import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

@immutable
class AuthResponse {
  final UserModel? user;
  final String? token; // JWT veya erişim tokenı
  final String? error; // Hata mesajı (nullable)

  const AuthResponse({
    this.user,
    this.token,
    this.error,
  });

  // JSON'dan nesne oluşturma
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    try {
      return AuthResponse(
        user: json['user'] != null
            ? UserModel.fromMap(json['user'] as Map<String, dynamic>)
            : null,
        token: json['token'] as String?,
        error: json['error'] as String?,
      );
    } catch (e) {
      throw FormatException('Failed to parse AuthResponse: $e');
    }
  }

  // Nesneyi JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      if (user != null) 'user': user!.toMap(),
      if (token != null) 'token': token,
      if (error != null) 'error': error,
    };
  }

  // Hata yanıtı için kısayol
  factory AuthResponse.error(String message) {
    return AuthResponse(error: message);
  }

  // Başarılı yanıt için kısayol
  factory AuthResponse.success({
    required UserModel user,
    required String token,
  }) {
    return AuthResponse(user: user, token: token);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is AuthResponse &&
              runtimeType == other.runtimeType &&
              user == other.user &&
              token == other.token &&
              error == other.error);

  @override
  int get hashCode => user.hashCode ^ token.hashCode ^ error.hashCode;

  @override
  String toString() {
    return 'AuthResponse('
        'user: ${user?.email ?? "none"}, '
        'token: ${token != null ? "***${token!.substring(token!.length - 4)}" : "none"}, '
        'error: $error)';
  }
}