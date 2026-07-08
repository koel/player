import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoriteButton extends StatelessWidget {
  final Song song;
  final Color inactiveColor;

  const FavoriteButton({
    Key? key,
    required this.song,
    required this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<InteractionProvider, FavoriteProvider>(
      builder: (_, interactionProvider, __, ___) => IconButton(
        onPressed: () => interactionProvider.toggleLike(song: song),
        icon: Icon(
          song.liked ? CupertinoIcons.star_fill : CupertinoIcons.star,
          color: song.liked ? Colors.white : inactiveColor,
        ),
      ),
    );
  }
}
