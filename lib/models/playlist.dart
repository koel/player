import 'package:app/models/song.dart';
import 'package:faker/faker.dart';

class Playlist {
  dynamic id; // This might be a UUID string in the near future
  String name;
  bool isSmart;
  bool populated = false;
  List<Song> songs = [];

  Playlist({required this.id, required this.name, required this.isSmart});

  bool get isEmpty => songs.length == 0;

  bool get isStandard => !isSmart;

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      isSmart: json['is_smart'],
    );
  }

  factory Playlist.fake({
    dynamic id,
    String? name,
    bool? isSmart,
    bool? populated,
  }) {
    Faker faker = Faker();

    return Playlist(
      id: id ?? faker.randomGenerator.integer(100, min: 1),
      name: name ?? faker.food.cuisine(),
      isSmart: isSmart ?? false,
    )..populated = populated ?? false;
  }
}
