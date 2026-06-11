import 'dart:convert';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString(),
        role: json['role']?.toString() ?? 'kurir',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        'role': role,
      };

  String toRawJson() => jsonEncode(toJson());

  static UserModel fromRawJson(String str) =>
      UserModel.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
