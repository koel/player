import 'package:app/models/models.dart';
import 'package:faker/faker.dart';

class Playlist {
  var id; // This might be a UUID string in the near future
  String name;
  bool isSmart;
  List<Playable> playables = [];

  Playlist({required this.id, required this.name, required this.isSmart});

  bool get isEmpty => playables.length == 0;

  bool get isStandard => !isSmart;

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      isSmart: json['is_smart'],
    );
  }

  factory Playlist.fake({var id, String? name, bool? isSmart}) {
    Faker faker = Faker();

    return Playlist(
      id: id ?? faker.guid.guid(),
      name: name ?? faker.food.cuisine(),
      isSmart: isSmart ?? false,
    );
  }
}
