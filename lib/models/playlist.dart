import 'package:app/models/song.dart';

class Playlist {
  int id;
  String name;
  bool isSmart;
  bool populated = false;
  List<Song> songs = [];

  Playlist({required this.id, required this.name, required this.isSmart});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      isSmart: json['is_smart'],
    );
  }

  bool get isEmpty => songs.length == 0;
  bool get isStandard => !isSmart;
}
