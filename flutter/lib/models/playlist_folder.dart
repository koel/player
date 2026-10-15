import 'package:faker/faker.dart';

class PlaylistFolder {
  final String id;
  String name;

  PlaylistFolder({required this.id, required this.name});

  factory PlaylistFolder.fromJson(Map<String, dynamic> json) {
    return PlaylistFolder(
      id: json['id'],
      name: json['name'],
    );
  }

  factory PlaylistFolder.fake({String? id, String? name}) {
    final faker = Faker();
    return PlaylistFolder(
      id: id ?? faker.guid.guid(),
      name: name ?? faker.lorem.word(),
    );
  }
}
