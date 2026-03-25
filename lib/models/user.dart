import 'package:app/utils/crypto.dart';
import 'package:cached_network_image/cached_network_image.dart';

class User {
  dynamic id;
  String name;
  String email;
  bool isAdmin;
  String? avatarUrl;
  bool continuousPlayback;
  int crossfadeDuration;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
    this.avatarUrl,
    this.continuousPlayback = false,
    this.crossfadeDuration = 0,
  });

  CachedNetworkImageProvider get avatar {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(avatarUrl!);
    }

    String hash = md5(name.trim().toLowerCase());
    return CachedNetworkImageProvider(
      'https://www.gravatar.com/avatar/$hash?s=512&d=robohash',
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final prefs = json['preferences'] as Map<String, dynamic>? ?? {};

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isAdmin: json['is_admin'] ?? false,
      avatarUrl: json['avatar'],
      continuousPlayback: prefs['continuous_playback'] ?? false,
      crossfadeDuration: prefs['crossfade_duration'] ?? 0,
    );
  }
}
