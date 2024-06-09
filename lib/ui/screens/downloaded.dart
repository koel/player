import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/values/values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide AppBar;
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class DownloadedScreen extends StatefulWidget {
  static const routeName = '/downloaded';
  bool inOfflineMode = false;

  DownloadedScreen({Key? key, this.inOfflineMode = false}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadedScreenState();
}

class _DownloadedScreenState extends State<DownloadedScreen> {
  var _searchQuery = '';
  var _cover = CoverImageStack(playables: []);

  @override
  Widget build(BuildContext context) {
    var sortConfig = AppState.get(
      'downloaded.sort',
      PlayableSortConfig(field: 'title', order: SortOrder.asc),
    )!;

    return Scaffold(
      body: GradientDecoratedContainer(
        child: Consumer<DownloadProvider>(
          builder: (_, provider, __) {
            if (provider.playables.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.hPadding,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'No downloaded songs',
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
                                  CupertinoIcons.cloud_download_fill,
                                  size: 16.0,
                                ),
                              ),
                            ),
                            TextSpan(
                              text: 'icon next to a song to download it for '
                                  'offline playback.',
                            ),
                          ],
                        ),
                      ),
                      if (Navigator.canPop(context)) ...[
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Go back'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            if (_cover.isEmpty) {
              _cover = CoverImageStack(playables: provider.playables);
            }

            final displayedPlayables =
                provider.playables.$sort(sortConfig).$filter(_searchQuery);

            return ScrollsToTop(
              child: CustomScrollView(
                slivers: <Widget>[
                  AppBar(
                    headingText: 'Downloaded',
                    coverImage: _cover,
                    actions: [
                      SortButton(
                        fields: ['title', 'artist_name', 'created_at'],
                        currentField: sortConfig.field,
                        currentOrder: sortConfig.order,
                        onMenuItemSelected: (_sortConfig) {
                          setState(() => sortConfig = _sortConfig);
                          AppState.set('downloaded.sort', _sortConfig);
                        },
                      ),
                    ],
                  ),
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
                    listContext: PlayableListContext.downloads,
                    onDismissed: provider.removeForPlayable,
                  ),
                  const BottomSpace(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
