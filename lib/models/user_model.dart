// lib/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final bool isReported;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.isReported = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      isReported: map['isReported'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'isReported': isReported,
    };
  }
}
