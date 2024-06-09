import 'package:app/constants/constants.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

class RecentlyPlayedScreen extends StatefulWidget {
  static const routeName = '/recently-played';

  const RecentlyPlayedScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RecentlyPlayedScreenState();
}

class _RecentlyPlayedScreenState extends State<RecentlyPlayedScreen> {
  late final RecentlyPlayedProvider _recentlyPlayedProvider;
  var _loading = false;
  var _errored = false;
  var _searchQuery = '';
  var _cover = CoverImageStack(playables: []);

  @override
  void initState() {
    super.initState();

    _recentlyPlayedProvider = context.read();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_recentlyPlayedProvider.playables.isEmpty) {
        await fetchData();
      }
    });
  }

  Future<void> fetchData() async {
    if (_loading) return;

    setState(() {
      _errored = false;
      _loading = true;
    });

    try {
      await _recentlyPlayedProvider.fetch();
    } catch (_) {
      setState(() => _errored = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientDecoratedContainer(
        child: Consumer<RecentlyPlayedProvider>(
          builder: (_, provider, __) {
            if (provider.playables.isEmpty) {
              if (_loading) return const PlayableListScreenPlaceholder();
              if (_errored) return OopsBox(onRetry: fetchData);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.hPadding,
                ),
                child: Center(
                  child: Wrap(
                    spacing: 16.0,
                    direction: Axis.vertical,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      const Icon(
                        CupertinoIcons.time,
                        size: 96.0,
                        color: Colors.white30,
                      ),
                      const Text('You have not played any songs yet.'),
                    ],
                  ),
                ),
              );
            }

            _cover = CoverImageStack(playables: provider.playables);

            final playables = provider.playables.$filter(_searchQuery);

            return CustomScrollView(
              slivers: <Widget>[
                AppBar(
                  headingText: 'Recently Played',
                  coverImage: _cover,
                ),
                SliverToBoxAdapter(
                  child: PlayableListHeader(
                    playables: playables,
                    onSearchQueryChanged: (String query) {
                      setState(() => _searchQuery = query);
                    },
                  ),
                ),
                SliverPlayableList(
                  playables: playables,
                  listContext: PlayableListContext.recentlyPlayed,
                ),
                const BottomSpace(),
              ],
            );
          },
        ),
      ),
    );
  }
}
