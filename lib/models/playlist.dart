import 'package:app/models/models.dart';
import 'package:faker/faker.dart';

class Playlist {
  var id; // This might be a UUID string in the near future
  String name;
  bool isSmart;
  String? folderId;
  String? description;
  String? cover;
  List<Playable> playables = [];

  Playlist({
    required this.id,
    required this.name,
    required this.isSmart,
    this.folderId,
    this.description,
    this.cover,
  });

  bool get isEmpty => playables.length == 0;

  bool get isStandard => !isSmart;

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      isSmart: json['is_smart'],
      folderId: json['folder_id'],
      description: json['description'],
      cover: json['cover'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_smart': isSmart,
        'folder_id': folderId,
        'description': description,
        'cover': cover,
      };

  bool get hasCover => cover != null && cover!.isNotEmpty;

  factory Playlist.fake({
    var id,
    String? name,
    bool? isSmart,
    String? folderId,
    String? description,
    String? cover,
  }) {
    Faker faker = Faker();

    return Playlist(
      id: id ?? faker.guid.guid(),
      name: name ?? faker.food.cuisine(),
      isSmart: isSmart ?? false,
      folderId: folderId,
      description: description,
      cover: cover,
    );
  }
}
