import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String? id;
  final String name;
  final String surname;
  final String email;
  final String? hashedPassword;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserModel._({
    this.id,
    required this.name,
    required this.surname,
    required this.email,
    this.hashedPassword,
    this.photoUrl,
    required this.createdAt,
    this.lastLogin,
  });

  // 🏭 Main Factory
  factory UserModel({
    String? id,
    required String name,
    required String surname,
    required String email,
    String? password,
    String? hashedPassword,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    if (email.isEmpty || !email.contains('@')) {
      throw ArgumentError('Invalid email');
    }

    return UserModel._(
      id: id,
      name: name.trim(),
      surname: surname.trim(),
      email: email.toLowerCase().trim(),
      hashedPassword: hashedPassword ?? _hashPassword(password, email), // 🔐 Email parametre olarak geçildi
      photoUrl: photoUrl,
      createdAt: createdAt ?? DateTime.now().toUtc(),
      lastLogin: lastLogin,
    );
  }

  // 🔄 From Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      return UserModel(
        id: map['id'] as String?,
        name: (map['name'] as String?) ?? 'Unknown',
        surname: (map['surname'] as String?) ?? '',
        email: map['email'] as String? ?? '',
        hashedPassword: map['hashedPassword'] as String?,
        photoUrl: map['photoUrl'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String).toUtc()
            : null,
        lastLogin: map['lastLogin'] != null
            ? DateTime.parse(map['lastLogin'] as String).toUtc()
            : null,
      );
    } catch (e) {
      throw FormatException('Failed to parse UserModel: $e');
    }
  }

  // 🌐 Social Login
  factory UserModel.socialLogin({
    required String id,
    required String email,
    String? name,
    String? surname,
    String? photoUrl,
  }) {
    return UserModel(
      id: id,
      name: name ?? 'Guest',
      surname: surname ?? '',
      email: email,
      photoUrl: photoUrl,
      lastLogin: DateTime.now().toUtc(),
    );
  }

  // 📦 To Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      if (hashedPassword != null) 'hashedPassword': hashedPassword,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      if (lastLogin != null) 'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  // ✏️ CopyWith
  UserModel copyWith({
    String? id,
    String? name,
    String? surname,
    String? email,
    String? password,
    String? hashedPassword,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      hashedPassword: hashedPassword ?? this.hashedPassword,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  // 🔐 Static Password Hashing
  static String? _hashPassword(String? password, String email) { // 💡 Email artık parametre
    if (password == null || password.isEmpty) return null;
    // ⚠️ Gerçek projede: bcrypt.hash(password + email) kullanın
    return 'hashed_${password.length}_${email.split('@').first}';
  }

  // ⚖️ Equality
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is UserModel &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              email == other.email);

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() => 'UserModel($email, $name $surname)';
}