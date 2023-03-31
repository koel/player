import 'package:app/constants/constants.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/app_bar.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/gradient_decorated_container.dart';
import 'package:app/ui/widgets/sliver_song_list.dart';
import 'package:app/ui/widgets/song_list_header.dart';
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
  var _loading = false;
  var _searchQuery = '';
  var _cover = CoverImageStack(songs: []);

  @override
  void initState() {
    super.initState();

    var provider = context.read<RecentlyPlayedProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (provider.songs.isEmpty) {
        setState(() => _loading = true);
        await provider.fetch();
        setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientDecoratedContainer(
        child: Consumer<RecentlyPlayedProvider>(
          builder: (_, provider, __) {
            if (_loading) return const SongListScreenPlaceholder();

            if (provider.songs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.horizontalPadding,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        CupertinoIcons.time,
                        size: 96.0,
                        color: Colors.white30,
                      ),
                      const SizedBox(height: 16.0),
                      const Text('You have not played any songs yet.'),
                    ],
                  ),
                ),
              );
            }

            _cover = CoverImageStack(songs: provider.songs);

            final songs = provider.songs.$filter(_searchQuery);

            return CustomScrollView(
              slivers: <Widget>[
                AppBar(
                  headingText: 'Recently Played',
                  coverImage: _cover,
                ),
                SliverToBoxAdapter(
                  child: SongListHeader(
                    songs: songs,
                    onSearchQueryChanged: (String query) {
                      setState(() => _searchQuery = query);
                    },
                  ),
                ),
                SliverSongList(
                  songs: songs,
                  listContext: SongListContext.recentlyPlayed,
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
