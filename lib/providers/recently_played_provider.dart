import 'package:app/providers/providers.dart';
import 'package:flutter/foundation.dart';

class RecentlyPlayedProvider with ChangeNotifier {
  SongProvider songProvider;

  RecentlyPlayedProvider({required this.songProvider});
}
