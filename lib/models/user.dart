import 'package:app/utils/crypto.dart';
import 'package:flutter/cupertino.dart';

class User {
  int id;
  String name;
  String email;
  bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
  });

  NetworkImage get avatar {
    String hash = md5(name.trim().toLowerCase());
    return NetworkImage(
        'https://www.gravatar.com/avatar/$hash?s=512&d=robohash');
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isAdmin: json['is_admin'],
    );
  }
}
