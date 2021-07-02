import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class InteractionProvider with ChangeNotifier {
  SongProvider _songProvider;

  final BehaviorSubject<Song> _songLiked = BehaviorSubject();
  ValueStream<Song> get songLikedStream => _songLiked.stream;

  final BehaviorSubject<Song> _songUnliked = BehaviorSubject();
  ValueStream<Song> get songUnlikedStream => _songUnliked.stream;

  InteractionProvider({required SongProvider songProvider})
      : _songProvider = songProvider;

  List<Song> get favorites =>
      _songProvider.songs.where((song) => song.liked).toList();

  Future<void> like(Song song) async {
    // broadcast the event first regardless
    _songLiked.add(song);
    song.liked = true;
  }

  Future<void> unlike(Song song) async {
    // broadcast the event first regardless
    _songUnliked.add(song);
    song.liked = false;
  }

  Future<void> toggleLike(Song song) async {
    return song.liked ? unlike(song) : like(song);
  }
}
