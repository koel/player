import 'package:faker/faker.dart';

class Genre {
  String id;
  String name;
  int songCount;
  num length;

  Genre({
    required this.id,
    required this.name,
    this.songCount = 0,
    this.length = 0,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] ?? json['public_id'] ?? '',
      name: json['name'] ?? '',
      songCount: json['song_count'] ?? 0,
      length: json['length'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'song_count': songCount,
        'length': length,
      };

  Genre merge(Genre remote) {
    this
      ..name = remote.name
      ..songCount = remote.songCount
      ..length = remote.length;
    return this;
  }

  String get formattedLength {
    final totalSeconds = length.toInt();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  factory Genre.fake({String? id, String? name, int? songCount, num? length}) {
    final faker = Faker();
    final genres = ['Rock', 'Pop', 'Jazz', 'Classical', 'Hip Hop', 'Electronic',
      'R&B', 'Country', 'Metal', 'Blues', 'Folk', 'Reggae', 'Punk'];

    return Genre(
      id: id ?? faker.guid.guid(),
      name: name ?? genres[faker.randomGenerator.integer(genres.length)],
      songCount: songCount ?? faker.randomGenerator.integer(500),
      length: length ?? faker.randomGenerator.integer(100000),
    );
  }

  static List<Genre> fakeMany(int count) =>
      List.generate(count, (_) => Genre.fake());

  @override
  bool operator ==(Object other) => other is Genre && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
