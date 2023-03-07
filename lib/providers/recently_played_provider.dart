import 'package:app/providers/song_provider.dart';
import 'package:flutter/foundation.dart';

class RecentlyPlayedProvider with ChangeNotifier {
  SongProvider songProvider;

  RecentlyPlayedProvider({required this.songProvider});
}
