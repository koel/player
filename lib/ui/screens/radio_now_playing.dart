import 'dart:ui';

import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RadioNowPlayingScreen extends StatefulWidget {
  const RadioNowPlayingScreen({Key? key}) : super(key: key);

  @override
  State<RadioNowPlayingScreen> createState() => _RadioNowPlayingScreenState();
}

class _RadioNowPlayingScreenState extends State<RadioNowPlayingScreen> {
  var _dragOffset = 0.0;

  void _onPointerMove(PointerMoveEvent event) {
    if (_dragOffset > 0 || event.delta.dy > 0) {
      setState(() {
        _dragOffset =
            (_dragOffset + event.delta.dy).clamp(0.0, double.infinity);
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_dragOffset <= 0) return;

    final screenHeight = MediaQuery.of(context).size.height;

    if (_dragOffset > screenHeight * 0.15) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioPlayerProvider>(
      builder: (context, radioPlayer, _) {
        if (!radioPlayer.active) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
          return const SizedBox.shrink();
        }

        final station = radioPlayer.currentStation!;
        final screenHeight = MediaQuery.of(context).size.height;

        final ImageProvider<Object> stationImage = station.logo != null
            ? CachedNetworkImageProvider(station.logo!)
            : const AssetImage('assets/images/default-image.webp') as ImageProvider<Object>;

        final frostBackground = SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: stationImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          ),
        );

        return Listener(
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          child: AnimatedContainer(
            duration: _dragOffset == 0
                ? const Duration(milliseconds: 200)
                : Duration.zero,
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, _dragOffset, 0),
            child: ClipRRect(
              borderRadius:
                  Theme.of(context).platform == TargetPlatform.iOS
                      ? const BorderRadius.vertical(
                          top: Radius.circular(38.5))
                      : BorderRadius.zero,
              child: Material(
                type: MaterialType.transparency,
                child: Stack(
                  children: <Widget>[
                    const GradientDecoratedContainer(),
                    frostBackground,
                    Container(color: Colors.black38),
                    SafeArea(
                      child: Container(
                        height: screenHeight,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            // Drag handle
                            Center(
                              child: Container(
                                width: 36,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white30,
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                            ),
                            // Station image
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox.square(
                                  dimension: 256,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: stationImage,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Station info
                            Column(
                              children: <Widget>[
                                MarqueeText(
                                  text: radioPlayer.streamTitle ??
                                      station.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                MarqueeText(
                                  text: radioPlayer.streamTitle != null
                                      ? station.name
                                      : 'Radio',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Live indicator
                                if (radioPlayer.loading)
                                  const Text(
                                    'Connecting…',
                                    style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 14),
                                  )
                                else if (radioPlayer.playing)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            // Play/pause control
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                const IconButton(
                                  onPressed: null,
                                  icon: Icon(CupertinoIcons.backward_fill,
                                      color: Colors.white12),
                                  iconSize: 48,
                                ),
                                IconButton(
                                  onPressed: radioPlayer.togglePlayPause,
                                  icon: Icon(
                                    radioPlayer.playing
                                        ? CupertinoIcons.pause_solid
                                        : CupertinoIcons.play_fill,
                                  ),
                                  iconSize: 64,
                                ),
                                const IconButton(
                                  onPressed: null,
                                  icon: Icon(CupertinoIcons.forward_fill,
                                      color: Colors.white12),
                                  iconSize: 48,
                                ),
                              ],
                            ),
                            // Volume slider
                            const VolumeSlider(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
