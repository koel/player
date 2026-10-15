import 'package:faker/faker.dart';

class RadioStation {
  final String id;
  String name;
  String url;
  String? logo;
  String? description;
  bool isPublic;

  /// Whether the current user is allowed to edit this radio station.
  /// Sourced from the koel >= 9.2.0 `permissions` object on the JSON
  /// resource. Defaults to `false` when the server didn't include
  /// permissions (older koel) so the UI hides the action by default.
  bool canEdit;

  /// Whether the current user is allowed to delete this radio station.
  /// See [canEdit] for sourcing.
  bool canDelete;

  /// Whether the current user has favorited this radio station.
  bool favorite;

  RadioStation({
    required this.id,
    required this.name,
    required this.url,
    this.logo,
    this.description,
    this.isPublic = false,
    this.canEdit = false,
    this.canDelete = false,
    this.favorite = false,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    final permissions = json['permissions'];

    return RadioStation(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      logo: json['logo'],
      description: json['description'],
      isPublic: json['is_public'] ?? false,
      canEdit: permissions is Map ? permissions['edit'] == true : false,
      canDelete: permissions is Map ? permissions['delete'] == true : false,
      favorite: json['favorite'] == true,
    );
  }

  factory RadioStation.fake({
    String? id,
    String? name,
    String? url,
    bool canEdit = false,
    bool canDelete = false,
    bool favorite = false,
  }) {
    final faker = Faker();
    return RadioStation(
      id: id ?? faker.guid.guid(),
      name: name ?? '${faker.address.city()} FM',
      url: url ?? 'https://stream.example.com/live',
      canEdit: canEdit,
      canDelete: canDelete,
      favorite: favorite,
    );
  }
}
