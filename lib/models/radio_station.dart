import 'package:faker/faker.dart';

class RadioStation {
  final String id;
  String name;
  String url;
  String? logo;
  String? description;
  bool isPublic;

  RadioStation({
    required this.id,
    required this.name,
    required this.url,
    this.logo,
    this.description,
    this.isPublic = false,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      logo: json['logo'],
      description: json['description'],
      isPublic: json['is_public'] ?? false,
    );
  }

  factory RadioStation.fake({
    String? id,
    String? name,
    String? url,
  }) {
    final faker = Faker();
    return RadioStation(
      id: id ?? faker.guid.guid(),
      name: name ?? '${faker.address.city()} FM',
      url: url ?? 'https://stream.example.com/live',
    );
  }
}
