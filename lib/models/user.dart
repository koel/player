import 'package:app/utils/crypto.dart';
import 'package:cached_network_image/cached_network_image.dart';

class User {
  dynamic id; // This might be a UUID string in the near future
  String name;
  String email;
  bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
  });

  CachedNetworkImageProvider get avatar {
    String hash = md5(name.trim().toLowerCase());

    return CachedNetworkImageProvider(
      'https://www.gravatar.com/avatar/$hash?s=512&d=robohash',
    );
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
