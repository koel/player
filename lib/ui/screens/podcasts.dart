import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/placeholders/placeholders.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
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

              final podcasts = provider.podcasts
                ..sort((b, a) => a.subscribedAt.compareTo(b.subscribedAt));

              late var widgets = <Widget>[];

              if (podcasts.isEmpty) {
                widgets = [
                  SliverToBoxAdapter(
                    child: NoPodcastsScreen(
                      onTap: () {
                        widget.router.showAddPodcastSheet(context);
                      },
                    ),
                  )
                ];
              } else {
                widgets = [
                  navigationBar!,
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        var podcast = podcasts[index];

                        return Card(
                          child: Dismissible(
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => confirmUnsubscribe(context),
                            onDismissed: (_) => provider.unsubscribePodcast(
                              podcast,
                            ),
                            background: Container(
                              alignment: AlignmentDirectional.centerEnd,
                              color: AppColors.red,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 28),
                                child: Icon(CupertinoIcons.delete),
                              ),
                            ),
                            key: ValueKey(podcast),
                            child: PodcastRow(
                              podcast: podcast,
                              router: widget.router,
                            ),
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
              trailing: IconButton(
                onPressed: () => widget.router.showAddPodcastSheet(context),
                icon: const Icon(CupertinoIcons.add_circled),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> confirmUnsubscribe(BuildContext context) async {
    return await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(text: 'Unsubscribe from this podcast?'),
          ),
          content: const Text('You cannot undo this action.'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              child: const Text('Confirm'),
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );
  }
}

class PodcastRow extends StatelessWidget {
  final Podcast podcast;
  final AppRouter router;

  const PodcastRow({Key? key, required this.podcast, required this.router})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => router.gotoPodcastDetailsScreen(
          context,
          podcastId: podcast.id,
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
  final void Function() onTap;

  const NoPodcastsScreen({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      alignment: Alignment.center,
      child: Wrap(
        spacing: 16.0,
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Icon(
            CupertinoIcons.exclamationmark_square,
            size: 56.0,
          ),
          const Text('No podcasts available.'),
          ElevatedButton(onPressed: onTap, child: Text('Add a Podcast')),
        ],
      ),
    );
  }
}
