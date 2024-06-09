import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/values/values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  static const routeName = '/favorites';

  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  var _errored = false;
  var _loading = false;
  var _searchQuery = '';
  var cover = CoverImageStack(playables: []);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => makeRequest());
  }

  Future<void> makeRequest({bool forceRefresh = false}) async {
    if (_loading) return;

    setState(() {
      _errored = false;
      _loading = true;
    });

    try {
      await context.read<FavoriteProvider>().fetch(forceRefresh: forceRefresh);
    } catch (_) {
      setState(() => _errored = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var sortConfig = AppState.get(
      'favorites.sort',
      PlayableSortConfig(field: 'title', order: SortOrder.asc),
    )!;

    final emptyWidget = SliverFillRemaining(
      hasScrollBody: false,
      fillOverscroll: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.hPadding),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                CupertinoIcons.heart,
                size: 56.0,
                color: Colors.grey,
              ),
              const SizedBox(height: 16.0),
              Text(
                'No favorites',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16.0),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(color: Colors.white54),
                  children: <InlineSpan>[
                    TextSpan(text: 'Tap the'),
                    WidgetSpan(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.0),
                        child: Icon(
                          CupertinoIcons.heart_solid,
                          size: 16.0,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: 'icon in a song’s menu to mark it as '
                          'favorite.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: GradientDecoratedContainer(
        child: Consumer<FavoriteProvider>(
          builder: (_, provider, __) {
            if (provider.playables.isEmpty) {
              if (_loading) return const PlayableListScreenPlaceholder();
              if (_errored) return OopsBox(onRetry: makeRequest);
            }

            if (cover.isEmpty) {
              cover = CoverImageStack(playables: provider.playables);
            }

            final songs =
                provider.playables.$sort(sortConfig).$filter(_searchQuery);

            return PullToRefresh(
              onRefresh: () {
                return _loading
                    ? Future(() => null)
                    : makeRequest(forceRefresh: true);
              },
              child: ScrollsToTop(
                child: CustomScrollView(
                  slivers: provider.playables.isEmpty
                      ? <Widget>[emptyWidget]
                      : <Widget>[
                          AppBar(
                            headingText: 'Favorites',
                            coverImage: cover,
                            actions: [
                              SortButton(
                                fields: ['title', 'artist_name', 'created_at'],
                                currentField: sortConfig.field,
                                currentOrder: sortConfig.order,
                                onMenuItemSelected: (_sortConfig) {
                                  setState(() => sortConfig = _sortConfig);
                                  AppState.set('favorites.sort', sortConfig);
                                },
                              ),
                            ],
                          ),
                          SliverToBoxAdapter(
                            child: PlayableListHeader(
                              playables: songs,
                              onSearchQueryChanged: (String query) {
                                setState(() => _searchQuery = query);
                              },
                            ),
                          ),
                          SliverPlayableList(
                            playables: songs,
                            listContext: PlayableListContext.favorites,
                            onDismissed: provider.unlike,
                            dismissIcon: const Icon(CupertinoIcons.heart_slash),
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
