import 'package:app/app_state.dart';
import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/extensions/extensions.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PodcastsScreen extends StatefulWidget {
  static const routeName = '/podcasts';
  final AppRouter router;

  const PodcastsScreen({
    Key? key,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _PodcastScreenState createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastsScreen> {
  var _loading = false;
  var _errored = false;
  late PodcastSortConfig _sortConfig;

  Future<void> fetchData() async {
    if (_loading) return;

    setState(() {
      _errored = false;
      _loading = true;
    });

    try {
      await context.read<PodcastProvider>().fetchAll();
    } catch (_) {
      setState(() => _errored = true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _sortConfig = AppState.get(
      'podcast.sort',
      PodcastSortConfig(
        field: PodcastSortField.lastPlayedAt,
        order: SortOrder.desc,
      ),
    )!;

    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupertinoTheme(
        data: const CupertinoThemeData(primaryColor: Colors.white),
        child: GradientDecoratedContainer(
          child: Consumer<PodcastProvider>(
            builder: (context, provider, navigationBar) {
              if (provider.podcasts.isEmpty) {
                if (_loading) return const PodcastsScreenPlaceholder();
                if (_errored) return OopsBox(onRetry: fetchData);
              }

              final podcasts = provider.podcasts.$sort(_sortConfig);

              late var widgets = <Widget>[];

              if (podcasts.isEmpty) {
                widgets = [
                  navigationBar!,
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: NoPodcastsScreen(),
                  )
                ];
              } else {
                widgets = [
                  navigationBar!,
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        var podcast = podcasts[index];

                        return Dismissible(
                          key: ValueKey(podcast.id),
                          direction: DismissDirection.endToStart,
                          background: const SizedBox.shrink(),
                          secondaryBackground: const SwipeDestructiveBackground(
                            label: 'Unsubscribe',
                          ),
                          confirmDismiss: (_) => confirmUnsubscribePodcast(
                            context,
                            podcast: podcast,
                          ),
                          onDismissed: (_) => unsubscribePodcastWithFeedback(
                            context,
                            podcast: podcast,
                          ),
                          child: PodcastRow(
                            podcast: podcast,
                            router: widget.router,
                          ),
                        );
                      },
                      childCount: podcasts.length,
                    ),
                  ),
                  const BottomSpace(),
                ];
              }

              return PullToRefresh(
                onRefresh: () => _loading ? Future(() => null) : fetchData(),
                child: CustomScrollView(slivers: widgets),
              );
            },
            child: CupertinoSliverNavigationBar(
              backgroundColor: AppColors.staticScreenHeaderBackground,
              largeTitle: const LargeTitle(text: 'Podcasts'),
              trailing: PodcastSortButton(
                currentField: _sortConfig.field,
                currentOrder: _sortConfig.order,
                onMenuItemSelected: (config) {
                  setState(() => _sortConfig = config);
                  AppState.set('podcast.sort', _sortConfig);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class PodcastRow extends StatefulWidget {
  final Podcast podcast;
  final AppRouter router;

  const PodcastRow({Key? key, required this.podcast, required this.router})
      : super(key: key);

  @override
  State<PodcastRow> createState() => _PodcastRowState();
}

class _PodcastRowState extends State<PodcastRow> {
  Offset? _lastTapPosition;

  @override
  Widget build(BuildContext context) {
    final podcast = widget.podcast;

    return Card(
      child: InkWell(
        onTap: () => widget.router.gotoPodcastDetailsScreen(
          context,
          podcastId: podcast.id,
        ),
        onTapDown: (details) => _lastTapPosition = details.globalPosition,
        onLongPress: () => showPodcastActionsMenu(
          context,
          podcast: podcast,
          position: _lastTapPosition ?? Offset.zero,
        ),
        child: ListTile(
          shape: Border(bottom: Divider.createBorderSide(context)),
          leading: AlbumArtistThumbnail.sm(entity: podcast, asHero: true),
          title: Text(podcast.title, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            podcast.author,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60),
          ),
        ),
      ),
    );
  }
}

class NoPodcastsScreen extends StatelessWidget {
  const NoPodcastsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      // Slightly above visual center to compensate for the mini-player +
      // tab bar at the bottom, which makes a true Center feel low.
      alignment: const Alignment(0, -0.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.podcast,
              size: 56,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No podcasts',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              "Subscribe to a podcast and it'll show up here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  const AppRouter().showAddPodcastSheet(context),
              icon: const Icon(CupertinoIcons.add, size: 18),
              label: const Text('Add a Podcast'),
            ),
          ],
        ),
      ),
    );
  }
}

class PodcastSortConfig {
  PodcastSortField field;
  SortOrder order;

  PodcastSortConfig({required this.field, required this.order});
}

class PodcastSortButton extends StatelessWidget {
  final void Function(PodcastSortConfig sortConfig)? onMenuItemSelected;

  final PodcastSortField currentField;
  final SortOrder currentOrder;

  static const fields = <PodcastSortField, String>{
    PodcastSortField.lastPlayedAt: 'Last played',
    PodcastSortField.subscribedAt: 'Subscribed',
    PodcastSortField.title: 'Title',
    PodcastSortField.author: 'Author',
  };

  const PodcastSortButton({
    Key? key,
    required this.currentField,
    required this.currentOrder,
    this.onMenuItemSelected,
  }) : super(key: key);

  PopupMenuItem<PodcastSortField> buildMenuItem(
    PodcastSortField field,
    String label,
  ) {
    final active = field == currentField;
    final style = active ? const TextStyle(color: AppColors.white) : null;

    return PopupMenuItem<PodcastSortField>(
      value: field,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            child: Text(
              active ? (currentOrder == SortOrder.asc ? '↓ ' : '↑ ') : '',
              style: style,
            ),
          ),
          Text(label, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PodcastSortField>(
      offset: const Offset(-12, 48),
      icon: const Icon(
        CupertinoIcons.sort_down,
        size: 25,
      ),
      onSelected: (item) {
        final newOrder = item == currentField
            ? (currentOrder == SortOrder.asc ? SortOrder.desc : SortOrder.asc)
            : SortOrder.asc;

        onMenuItemSelected?.call(PodcastSortConfig(
          field: item,
          order: newOrder,
        ));
      },
      itemBuilder: (_) =>
          fields.keys.map((key) => buildMenuItem(key, fields[key]!)).toList(),
    );
  }
}
