import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/values/values.dart';

extension SongListExtension on List<Song> {
  List<Song> $filter(String keywords) {
    if (keywords.isEmpty) {
      return this;
    }

    keywords = keywords.toLowerCase();

    return where((song) {
      return song.title.toLowerCase().contains(keywords) ||
          song.artistName.toLowerCase().contains(keywords) ||
          song.albumName.toLowerCase().contains(keywords);
    }).toList();
  }

  List<Song> $sort(SongSortConfig config) {
    switch (config.field) {
      case 'title':
        return this
          ..sort(
            (a, b) => config.order == SortOrder.asc
                ? a.title.compareTo(b.title)
                : b.title.compareTo(a.title),
          );
      case 'artist_name':
        return this
          ..sort(
            (a, b) => config.order == SortOrder.asc
                ? '${a.artistName}${a.albumName}${a.track}'
                    .compareTo('${b.artistName}${b.albumName}${b.track}')
                : '${b.artistName}${b.albumName}${b.title}'
                    .compareTo('${a.artistName}${a.albumName}${a.track}'),
          );
      case 'album_name':
        return this
          ..sort(
            (a, b) => config.order == SortOrder.asc
                ? '${a.albumName}${a.albumId}${a.track}'
                    .compareTo('${b.albumName}${b.albumId}${b.track}')
                : '${b.albumName}${b.albumId}${b.track}'
                    .compareTo('${a.albumName}${a.albumId}${a.track}'),
          );
      case 'created_at':
        return this
          ..sort(
            (a, b) => config.order == SortOrder.asc
                ? a.createdAt.compareTo(b.createdAt)
                : b.createdAt.compareTo(a.createdAt),
          );
      case 'track':
        // @todo add sort by disc
        return this
          ..sort(
            (a, b) => config.order == SortOrder.asc
                ? a.track.compareTo(b.track)
                : b.track.compareTo(a.track),
          );
      // @todo sort by disc and length
      default:
        throw Exception('Invalid sort field.');
    }
  }
}
