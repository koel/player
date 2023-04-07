class Interaction {
  String songId;
  int playCount;
  bool liked;

  Interaction({
    required this.songId,
    required this.liked,
    required this.playCount,
  });

  factory Interaction.fromJson(Map<String, dynamic> json) {
    return Interaction(
      songId: json['song_id'],
      playCount: json['play_count'],
      liked: json['liked'] ?? false,
    );
  }
}
