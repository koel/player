import 'package:app/enums.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/pull_to_refresh.dart';
import 'package:app/ui/widgets/song_list_buttons.dart';
import 'package:app/ui/widgets/song_row.dart';
import 'package:app/ui/widgets/song_list_sort_button.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:app/values/values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';
import 'package:app/extensions/extensions.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  static const routeName = '/playlist';

  const PlaylistDetailsScreen({Key? key}) : super(key: key);

  @override
  _PlaylistDetailsScreen createState() => _PlaylistDetailsScreen();
}

class _PlaylistDetailsScreen extends State<PlaylistDetailsScreen> {
  late PlaylistProvider _playlistProvider;
  String _searchQuery = '';
  CoverImageStack _cover = CoverImageStack(songs: []);

  @override
  void initState() {
    super.initState();
    _playlistProvider = context.read();
  }

  Future<List<Song>> buildRequest(
    int playlistId, {
    bool forceRefresh = false,
  }) {
    return context
        .read<SongProvider>()
        .fetchForPlaylist(playlistId, forceRefresh: forceRefresh);
  }

  @override
  Widget build(BuildContext context) {
    final Playlist playlist =
        ModalRoute.of(context)!.settings.arguments as Playlist;
    final AppStateProvider appState = context.read();
    SongSortConfig sortConfig = appState.get('playlist.sort') ??
        SongSortConfig(field: 'title', order: SortOrder.asc);

    return Scaffold(
      body: FutureBuilder(
        future: buildRequest(playlist.id),
        builder: (BuildContext context, AsyncSnapshot<List<Song>> snapshot) {
          if (!snapshot.hasData) return const Center(child: const Spinner());

          if (snapshot.hasError) {
            return GestureDetector(
              child: Center(child: const Text('Error. Tap to try again.')),
              onTap: () => setState(() {}),
            );
          }

          List<Song> songs = snapshot.data == null ? [] : snapshot.data!;

          if (_cover.isEmpty && songs.isNotEmpty) {
            _cover = CoverImageStack(songs: snapshot.data!);
          }

          var displayedSongs =
              songs.$sort(sortConfig).$filter(_searchQuery) ?? [];

          return PullToRefresh(
            onRefresh: () => buildRequest(playlist.id, forceRefresh: true),
            child: CustomScrollView(
              slivers: <Widget>[
                AppBar(
                  headingText: playlist.name,
                  coverImage: _cover,
                  actions: [
                    SortButton(
                      fields: ['title', 'artist_name', 'created_at'],
                      currentField: sortConfig.field,
                      currentOrder: sortConfig.order,
                      onActionSheetActionPressed: (_sortConfig) {
                        setState(() => sortConfig = _sortConfig);
                        appState.set('playlist.sort', _sortConfig);
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: songs.isEmpty
                      ? const SizedBox.shrink()
                      : SongListButtons(
                          songs: displayedSongs,
                          onSearchChanged: (String query) {
                            setState(() => _searchQuery = query);
                          },
                        ),
                ),
                if (songs.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(
                        child: Text(
                          'The playlist is empty.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, int index) {
                        final bool dismissible = playlist.isStandard;
                        final Song song = displayedSongs[index];
                        return dismissible
                            ? Dismissible(
                                direction: DismissDirection.endToStart,
                                onDismissed: (DismissDirection direction) {
                                  _playlistProvider.removeSongFromPlaylist(
                                    song: song,
                                    playlist: playlist,
                                  );
                                },
                                background: Container(
                                  alignment: AlignmentDirectional.centerEnd,
                                  color: Colors.red,
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 28),
                                    child: Icon(CupertinoIcons.delete_simple),
                                  ),
                                ),
                                key: ValueKey(song),
                                child: SongRow(
                                  key: ValueKey(song),
                                  song: song,
                                ),
                              )
                            : SongRow(song: song);
                      },
                      childCount: displayedSongs.length,
                    ),
                  ),
                const BottomSpace(),
              ],
            ),
          );
        },
      ),
    );
  }
}

void gotoDetailsScreen(BuildContext context, {required Playlist playlist}) {
  Navigator.of(context, rootNavigator: true).pushNamed(
    PlaylistDetailsScreen.routeName,
    arguments: playlist,
  );
}
