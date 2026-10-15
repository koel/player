class Interaction {
  String songId;
  int playCount;

  Interaction({
    required this.songId,
    required this.playCount,
  });

  factory Interaction.fromJson(Map<String, dynamic> json) {
    return Interaction(
      songId: json['song_id'],
      playCount: json['play_count'],
    );
  }
}
