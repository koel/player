import 'package:app/constants/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class User {
  dynamic id; // This might be a UUID string in the near future
  String name;
  String email;

  final String? avatarUrl;

  /// The user's preferred order of Home screen blocks, by block id. Empty
  /// when the server doesn't expose the preference (older API) or the user
  /// never reordered the blocks.
  final List<String> homeBlocksOrder;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.homeBlocksOrder = const [],
  });

  ImageProvider get avatar {
    final avatarUrl = this.avatarUrl;

    return avatarUrl == null
        ? AppImages.defaultImage.image
        : CachedNetworkImageProvider(avatarUrl);
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final preferences = json['preferences'];
    final order = preferences is Map ? preferences['home_blocks_order'] : null;

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatar'],
      homeBlocksOrder:
          order is List ? order.whereType<String>().toList() : const [],
    );
  }
}
