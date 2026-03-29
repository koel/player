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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _playlistProvider = context.read();
  }

  Widget? _buildBackgroundImage(Playlist playlist, List<Playable> playables) {
    if (playlist.hasCover) {
      return SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(playlist.cover!),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
      );
    }

    return backgroundImageFromPlayables(playables);
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

            final displayedPlayables =
                playables.$sort(sortConfig).$filter(_searchQuery);

            final showScrollbar = AlphabetScrollbar.shouldShow(itemCount: displayedPlayables.length, sortField: sortConfig.field, nameSortField: 'title');

            return PullToRefresh(
              onRefresh: () async {
                await buildRequest(playlist.id, forceRefresh: true);
                if (mounted) setState(() {});
              },
              child: PrimaryScrollController(
                controller: _scrollController,
                child: Stack(
                children: [
                CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  AppBar(
                    headingText: playlist.name,
                    backgroundImage: _buildBackgroundImage(playlist, playables),
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
                            scrollController: _scrollController,
                            rightPadding: showScrollbar ? alphabetScrollbarWidth : 0,
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
                      rightPadding: showScrollbar ? alphabetScrollbarWidth : 0,
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
              if (showScrollbar)
                AlphabetScrollbar(
                  labels: displayedPlayables.map((s) => s.title).toList(),
                  scrollController: _scrollController,
                  itemCount: displayedPlayables.length,
                  scrollOffset: 250,
                ),
              ],
              ),
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
