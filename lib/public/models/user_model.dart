class UserModel {
  final String? id;
  final String name;
  final String surname;
  final String email;
  final String? password; // Changed to nullable since we won't store it for social logins
  final String? photoUrl; // Added for profile pictures
  final DateTime? createdAt; // Added for user creation timestamp
  final DateTime? lastLogin; // Added for tracking last login

  UserModel({
    this.id,
    required this.name,
    required this.surname,
    required this.email,
    this.password, // Made optional
    this.photoUrl,
    this.createdAt,
    this.lastLogin,
  });

  // Convert to Map for Firebase/Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      // Never store plain passwords in production - this is just for demo
      'password': password,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  // Create from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'] ?? '',
      surname: map['surname'] ?? '',
      email: map['email'] ?? '',
      password: map['password'], // Now nullable
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'])
          : null,
    );
  }

  // For login (email + password only)
  factory UserModel.login({required String email, required String password}) {
    return UserModel(
      name: '',
      surname: '',
      email: email,
      password: password,
    );
  }

  // For social login (Google, etc.)
  factory UserModel.socialLogin({
    required String id,
    required String email,
    String? name,
    String? surname,
    String? photoUrl,
  }) {
    return UserModel(
      id: id,
      name: name ?? '',
      surname: surname ?? '',
      email: email,
      photoUrl: photoUrl,
      lastLogin: DateTime.now(),
    );
  }

  // Copy with method for easy updates
  UserModel copyWith({
    String? id,
    String? name,
    String? surname,
    String? email,
    String? password,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      password: password ?? this.password,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}