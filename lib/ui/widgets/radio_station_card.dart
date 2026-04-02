import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RadioStationCard extends StatefulWidget {
  final RadioStation station;
  final VoidCallback? onTap;

  const RadioStationCard({Key? key, required this.station, this.onTap})
      : super(key: key);

  @override
  _RadioStationCardState createState() => _RadioStationCardState();
}

class _RadioStationCardState extends State<RadioStationCard> {
  var _opacity = 1.0;
  final _cardWidth = 144.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _opacity = 0.4),
      onTapUp: (_) => setState(() => _opacity = 1.0),
      onTapCancel: () => setState(() => _opacity = 1.0),
      onTap: widget.onTap ??
          () => context.read<RadioPlayerProvider>().play(widget.station),
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _opacity,
        child: Column(
          children: <Widget>[
            ClipSmoothRect(
              radius: SmoothBorderRadius(
                cornerRadius: 16,
                cornerSmoothing: .8,
              ),
              child: SizedBox(
                width: _cardWidth,
                height: _cardWidth,
                child: widget.station.logo != null
                    ? CachedNetworkImage(
                        imageUrl: widget.station.logo!,
                        width: _cardWidth,
                        height: _cardWidth,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _defaultIcon(),
                        errorWidget: (_, __, ___) => _defaultIcon(),
                      )
                    : _defaultIcon(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: _cardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.station.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.station.description != null &&
                      widget.station.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.station.description!,
                      style: const TextStyle(color: Colors.white54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultIcon() {
    return Container(
      width: _cardWidth,
      height: _cardWidth,
      color: Colors.white12,
      child: const Icon(
        CupertinoIcons.antenna_radiowaves_left_right,
        size: 48,
        color: Colors.white54,
      ),
    );
  }
}
