import 'dart:convert';

import 'package:app/constants/constants.dart';
import 'package:app/exceptions/http_response_exception.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class RadioStationsScreen extends StatefulWidget {
  static const routeName = '/radio-stations';

  const RadioStationsScreen({Key? key}) : super(key: key);

  @override
  _RadioStationsScreenState createState() => _RadioStationsScreenState();
}

class _RadioStationsScreenState extends State<RadioStationsScreen> {
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      await context.read<RadioStationProvider>().fetchAll();
    } catch (_) {
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
                      trailing: IconButton(
                        onPressed: () => _showAddStation(context, provider),
                        icon: const Icon(CupertinoIcons.add_circled),
                      ),
                    ),
                    if (stations.isEmpty && !_loading)
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
                                'Add a station to start listening.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= stations.length) return null;
                            final station = stations[index];

                            return GestureDetector(
                              onLongPress: () => _showStationActions(
                                context,
                                station: station,
                                provider: provider,
                              ),
                              child: Card(
                                child: Dismissible(
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) async {
                                    return await _confirmDelete(
                                      context,
                                      station: station,
                                    );
                                  },
                                  onDismissed: (_) => provider.remove(station),
                                  background: Container(
                                    alignment: AlignmentDirectional.centerEnd,
                                    color: AppColors.red,
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 28),
                                      child: Icon(CupertinoIcons.delete),
                                    ),
                                  ),
                                  key: ValueKey(station.id),
                                  child: _RadioStationRow(
                                    station: station,
                                    onTap: () => _playStation(station),
                                  ),
                                ),
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

  void _showAddStation(
      BuildContext context, RadioStationProvider provider) async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final descController = TextEditingController();
    var isPublic = false;

    await showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
        title: const Text('Add Radio Station'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: nameController,
              placeholder: 'Station Name',
              autofocus: true,
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill,
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: urlController,
              placeholder: 'Stream URL',
              keyboardType: TextInputType.url,
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill,
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: descController,
              placeholder: 'Description (optional)',
              maxLines: 2,
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill,
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CupertinoSwitch(
                  value: isPublic,
                  onChanged: (v) => setState(() => isPublic = v),
                ),
                const SizedBox(width: 8),
                const Text('This station is public', style: TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add'),
            onPressed: () async {
              final name = nameController.text.trim();
              final url = urlController.text.trim();
              if (name.isEmpty || url.isEmpty) return;

              try {
                await provider.create(
                  name: name,
                  url: url,
                  description: descController.text.trim(),
                  isPublic: isPublic,
                );
                Navigator.pop(context);
                showOverlay(context, caption: 'Station added');
              } catch (e) {
                Navigator.pop(context);
                var message = 'Something went wrong.';
                if (e is HttpResponseException) {
                  try {
                    final body = jsonDecode(e.response.body);
                    if (body['message'] != null) {
                      message = body['message'];
                    }
                  } catch (_) {}
                }
                showOverlay(
                  context,
                  caption: 'Error',
                  message: message,
                  icon: CupertinoIcons.exclamationmark_triangle,
                );
              }
            },
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _showStationActions(
    BuildContext context, {
    required RadioStation station,
    required RadioStationProvider provider,
  }) async {
    HapticFeedback.mediumImpact();

    await showCupertinoModalPopup(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(station.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _playStation(station);
            },
            child: const Text('Play'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _showEditStation(context, station: station, provider: provider);
            },
            child: const Text('Edit'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(sheetContext);
              final confirmed =
                  await _confirmDelete(context, station: station);
              if (confirmed) provider.remove(station);
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _showEditStation(
    BuildContext context, {
    required RadioStation station,
    required RadioStationProvider provider,
  }) async {
    final nameController = TextEditingController(text: station.name);
    final urlController = TextEditingController(text: station.url);
    final descController =
        TextEditingController(text: station.description ?? '');
    var isPublic = station.isPublic;

    await showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
        title: const Text('Edit Radio Station'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: nameController,
              placeholder: 'Station Name',
              autofocus: true,
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill,
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: urlController,
              placeholder: 'Stream URL',
              keyboardType: TextInputType.url,
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill,
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: descController,
              placeholder: 'Description (optional)',
              maxLines: 2,
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill,
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CupertinoSwitch(
                  value: isPublic,
                  onChanged: (v) => setState(() => isPublic = v),
                ),
                const SizedBox(width: 8),
                const Text('This station is public', style: TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () async {
              final name = nameController.text.trim();
              final url = urlController.text.trim();
              if (name.isEmpty || url.isEmpty) return;

              try {
                await provider.update(
                  station,
                  name: name,
                  url: url,
                  description: descController.text.trim(),
                  isPublic: isPublic,
                );
                Navigator.pop(context);
                showOverlay(context, caption: 'Station updated');
              } catch (_) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context, {
    required RadioStation station,
  }) async {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Delete "${station.name}"?'),
            content: const Text('You cannot undo this action.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;
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
    return InkWell(
      onTap: onTap,
      child: ListTile(
        shape: Border(bottom: Divider.createBorderSide(context)),
        leading: ClipOval(
          child: station.logo != null
              ? CachedNetworkImage(
                  imageUrl: station.logo!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _defaultIcon(),
                )
              : _defaultIcon(),
        ),
        title: Text(station.name, overflow: TextOverflow.ellipsis),
        subtitle: station.description != null &&
                station.description!.isNotEmpty
            ? Text(
                station.description!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60),
              )
            : null,
        trailing: const Icon(
          CupertinoIcons.antenna_radiowaves_left_right,
          size: 16,
          color: Colors.white38,
        ),
      ),
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
