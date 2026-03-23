import 'package:app/app_state.dart';
import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/values/values.dart';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  static const routeName = '/playlist';

  const PlaylistDetailsScreen({Key? key}) : super(key: key);

  @override
  _PlaylistDetailsScreen createState() => _PlaylistDetailsScreen();
}

class _PlaylistDetailsScreen extends State<PlaylistDetailsScreen> {
  late PlaylistProvider _playlistProvider;
  String _searchQuery = '';
  CoverImageStack _cover = CoverImageStack(playables: []);
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _playlistProvider = context.read();
  }

  Future<List<Playable>> buildRequest(
    var playlistId, {
    bool forceRefresh = false,
  }) {
    return context
        .read<PlayableProvider>()
        .fetchForPlaylist(playlistId, forceRefresh: forceRefresh);
  }

  @override
  Widget build(BuildContext context) {
    final playlist = ModalRoute.of(context)!.settings.arguments as Playlist;
    var sortConfig = AppState.get(
      'playlist.sort',
      PlayableSortConfig(field: 'title', order: SortOrder.asc),
    )!;

    return Scaffold(
      body: GradientDecoratedContainer(
        child: FutureBuilder(
          future: buildRequest(playlist.id),
          builder: (BuildContext _, AsyncSnapshot<List<Playable>> snapshot) {
            if (!snapshot.hasData ||
                snapshot.connectionState == ConnectionState.active)
              return const PlayableListScreenPlaceholder();

            if (snapshot.hasError)
              return OopsBox(onRetry: () => setState(() {}));

            final playables =
                snapshot.data == null ? <Playable>[] : snapshot.requireData;

            Widget coverWidget;

            if (playlist.hasCover) {
              coverWidget = DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(playlist.cover!),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(16),
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 10.0,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
              );
            } else {
              if (_cover.isEmpty && playables.isNotEmpty) {
                _cover = CoverImageStack(playables: playables);
              }
              coverWidget = _cover;
            }

            final displayedPlayables =
                playables.$sort(sortConfig).$filter(_searchQuery);

            return PullToRefresh(
              onRefresh: () => buildRequest(playlist.id, forceRefresh: true),
              child: Stack(
                children: [
                CustomScrollView(
                controller: _scrollController,
                slivers: <Widget>[
                  AppBar(
                    headingText: playlist.name,
                    coverImage: coverWidget,
                    backgroundImage: playlist.hasCover
                        ? SizedBox.square(
                            dimension: double.infinity,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 20.0,
                                sigmaY: 20.0,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      playlist.cover!,
                                    ),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : null,
                    actions: [
                      SortButton(
                        fields: ['title', 'artist_name', 'created_at'],
                        currentField: sortConfig.field,
                        currentOrder: sortConfig.order,
                        onMenuItemSelected: (_sortConfig) {
                          setState(() => sortConfig = _sortConfig);
                          AppState.set('playlist.sort', _sortConfig);
                        },
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: playables.isEmpty
                        ? const SizedBox.shrink()
                        : PlayableListHeader(
                            playables: displayedPlayables,
                            onSearchQueryChanged: (query) {
                              setState(() => _searchQuery = query);
                            },
                          ),
                  ),
                  if (playables.isEmpty)
                    SliverToBoxAdapter(
                      child: const Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: Center(
                          child: Text(
                            'The playlist is empty.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPlayableList(
                      playables: displayedPlayables,
                      onDismissed: playlist.isStandard
                          ? (playable) => _playlistProvider.removeFromPlaylist(
                                playable,
                                playlist: playlist,
                              )
                          : null,
                    ),
                  const BottomSpace(),
                ],
              ),
              if (AlphabetScrollbar.shouldShow(itemCount: displayedPlayables.length, sortField: sortConfig.field, nameSortField: 'title'))
                AlphabetScrollbar(
                  labels: displayedPlayables.map((s) => s.title).toList(),
                  scrollController: _scrollController,
                  itemCount: displayedPlayables.length,
                  scrollOffset: 250,
                ),
              ],
              ),
            );
          },
        ),
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
