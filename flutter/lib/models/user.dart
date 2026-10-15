import 'package:app/utils/crypto.dart';
import 'package:cached_network_image/cached_network_image.dart';

class User {
  dynamic id; // This might be a UUID string in the near future
  String name;
  String email;

  /// The user's preferred order of Home screen blocks, by block id. Empty
  /// when the server doesn't expose the preference (older API) or the user
  /// never reordered the blocks.
  final List<String> homeBlocksOrder;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.homeBlocksOrder = const [],
  });

  CachedNetworkImageProvider get avatar {
    String hash = md5(name.trim().toLowerCase());

    return CachedNetworkImageProvider(
      'https://www.gravatar.com/avatar/$hash?s=512&d=robohash',
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final preferences = json['preferences'];
    final order = preferences is Map ? preferences['home_blocks_order'] : null;

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      homeBlocksOrder:
          order is List ? order.whereType<String>().toList() : const [],
    );
  }
}
