import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RadioStationsScreen extends StatefulWidget {
  static const routeName = '/radio-stations';

  const RadioStationsScreen({Key? key}) : super(key: key);

  @override
  _RadioStationsScreenState createState() => _RadioStationsScreenState();
}

class _RadioStationsScreenState extends State<RadioStationsScreen> {
  var _loading = false;
  var _errored = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_loading) return;
    setState(() {
      _errored = false;
      _loading = true;
    });

    try {
      await context.read<RadioStationProvider>().fetchAll();
    } catch (_) {
      if (mounted) setState(() => _errored = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupertinoTheme(
        data: const CupertinoThemeData(primaryColor: Colors.white),
        child: GradientDecoratedContainer(
          child: Consumer<RadioStationProvider>(
            builder: (context, provider, navigationBar) {
              final stations = provider.stations
                ..sort((a, b) => a.name.compareTo(b.name));

              return PullToRefresh(
                onRefresh: () => _loading ? Future(() => null) : _fetchData(),
                child: CustomScrollView(
                  slivers: [
                    CupertinoSliverNavigationBar(
                      backgroundColor: AppColors.staticScreenHeaderBackground,
                      largeTitle: const LargeTitle(text: 'Radio'),
                    ),
                    if (_errored && stations.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: OopsBox(onRetry: _fetchData),
                      )
                    else if (stations.isEmpty && !_loading)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.antenna_radiowaves_left_right,
                                size: 56,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No radio stations',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'No radio stations available.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (stations.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= stations.length) return null;
                            final station = stations[index];

                            return Card(
                              child: _RadioStationRow(
                                station: station,
                                onTap: () => _playStation(station),
                              ),
                            );
                          },
                          childCount: stations.length,
                        ),
                      ),
                    if (_loading)
                      SliverToBoxAdapter(
                        child: Container(
                          height: 72,
                          child: const Center(child: Spinner(size: 16)),
                        ),
                      ),
                    const BottomSpace(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _playStation(RadioStation station) async {
    try {
      await context.read<RadioPlayerProvider>().play(station);
    } catch (e) {
      if (mounted) {
        showOverlay(
          context,
          caption: 'Error',
          message: 'Could not play station.',
          icon: CupertinoIcons.exclamationmark_triangle,
        );
      }
    }
  }

}

class _RadioStationRow extends StatelessWidget {
  final RadioStation station;
  final VoidCallback onTap;

  const _RadioStationRow({
    Key? key,
    required this.station,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioPlayerProvider>(
      builder: (context, radioPlayer, _) {
        final isPlaying = radioPlayer.currentStation?.id == station.id;

        return InkWell(
          onTap: onTap,
          child: ListTile(
            shape: Border(bottom: Divider.createBorderSide(context)),
            leading: ClipSmoothRect(
              radius: SmoothBorderRadius(
                cornerRadius: 8,
                cornerSmoothing: .8,
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  children: [
                    if (station.logo != null)
                      CachedNetworkImage(
                        imageUrl: station.logo!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _defaultIcon(),
                      )
                    else
                      _defaultIcon(),
                    if (isPlaying) ...[
                      Container(
                        width: 40,
                        height: 40,
                        color: const Color(0xFF410928).withOpacity(.7),
                      ),
                      if (radioPlayer.loading || radioPlayer.playing)
                        Center(
                          child: SizedBox.square(
                            dimension: 16,
                            child: Image.asset(
                                'assets/images/loading-animation.gif'),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            title: Text(
              station.name,
              overflow: TextOverflow.ellipsis,
              style: isPlaying
                  ? const TextStyle(color: AppColors.highlight)
                  : null,
            ),
            subtitle: station.description != null &&
                    station.description!.isNotEmpty
                ? Text(
                    station.description!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60),
                  )
                : null,
            trailing: Icon(
              CupertinoIcons.antenna_radiowaves_left_right,
              size: 16,
              color: isPlaying ? AppColors.highlight : Colors.white38,
            ),
          ),
        );
      },
    );
  }

  Widget _defaultIcon() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.white12,
      child: const Icon(
        CupertinoIcons.antenna_radiowaves_left_right,
        size: 20,
        color: Colors.white54,
      ),
    );
  }
}
