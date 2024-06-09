import 'dart:ui';

import 'package:app/app_state.dart';
import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/values/values.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class PodcastDetailsScreen extends StatefulWidget {
  static const routeName = '/podcast';

  const PodcastDetailsScreen({Key? key}) : super(key: key);

  @override
  _PodcastDetailsScreen createState() => _PodcastDetailsScreen();
}

class _PodcastDetailsScreen extends State<PodcastDetailsScreen> {
  String _searchQuery = '';

  Future<List<Object>> buildRequest(
    String podcastId, {
    bool forceRefresh = false,
  }) {
    return Future.wait([
      context
          .read<PodcastProvider>()
          .resolve(podcastId, forceRefresh: forceRefresh),
      context
          .read<PlayableProvider>()
          .fetchForPodcast(podcastId, forceRefresh: forceRefresh),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final podcastId = ModalRoute.of(context)!.settings.arguments as String;

    var sortConfig = AppState.get(
      'podcast.sort',
      PlayableSortConfig(field: 'created_at', order: SortOrder.desc),
    )!;

    return Scaffold(
      body: GradientDecoratedContainer(
        child: FutureBuilder(
          future: buildRequest(podcastId),
          builder: (_, AsyncSnapshot<List<Object>> snapshot) {
            if (!snapshot.hasData ||
                snapshot.connectionState == ConnectionState.active)
              return const PlayableListScreenPlaceholder();

            if (snapshot.hasError)
              return OopsBox(onRetry: () => setState(() {}));

            final songs = snapshot.data == null
                ? <Song>[]
                : snapshot.requireData[1] as List<Playable>;

            final podcast = snapshot.requireData[0] as Podcast;
            final displayedPlayables =
                songs.$sort(sortConfig).$filter(_searchQuery);

            return PullToRefresh(
              onRefresh: () => buildRequest(podcastId, forceRefresh: true),
              child: ScrollsToTop(
                child: CustomScrollView(
                  slivers: <Widget>[
                    AppBar(
                      headingText: podcast.title,
                      actions: [
                        SortButton(
                          fields: ['title', 'created_at'],
                          currentField: sortConfig.field,
                          currentOrder: sortConfig.order,
                          onMenuItemSelected: (_sortConfig) {
                            setState(() => sortConfig = _sortConfig);
                            AppState.set('podcast.sort', sortConfig);
                          },
                        ),
                      ],
                      backgroundImage: SizedBox.square(
                        dimension: double.infinity,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 20.0,
                            sigmaY: 20.0,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: podcast.image,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                      coverImage: Hero(
                        tag: "podcast-hero-${podcast.id}",
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: podcast.image,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(16),
                            ),
                            boxShadow: const <BoxShadow>[
                              const BoxShadow(
                                color: Colors.black38,
                                blurRadius: 10.0,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (songs.isNotEmpty)
                      SliverToBoxAdapter(
                        child: PlayableListHeader(
                          playables: displayedPlayables,
                          onSearchQueryChanged: (String query) {
                            setState(() => _searchQuery = query);
                          },
                        ),
                      ),
                    SliverPlayableList(
                      playables: displayedPlayables,
                      listContext: PlayableListContext.podcast,
                    ),
                    const BottomSpace(),
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
