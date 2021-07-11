import 'dart:ui';

import 'package:app/constants/dimensions.dart';
import 'package:app/models/song.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppBar extends StatelessWidget {
  final String headingText;
  final Widget coverImage;
  final Widget? backgroundImage;
  final List<Widget> actions;

  const AppBar({
    Key? key,
    required this.headingText,
    required this.coverImage,
    this.backgroundImage,
    this.actions = const [],
  }) : super(key: key);

  final Widget _gradientEffect = const SizedBox(
    width: double.infinity,
    height: double.infinity,
    child: const DecoratedBox(
      decoration: const BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 290,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.horizontalPadding,
          ),
          child: Text(
            headingText,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        background: Stack(
          children: <Widget>[
            if (backgroundImage != null) backgroundImage!,
            _gradientEffect,
            Center(
              child: SizedBox(
                width: 192,
                height: 192,
                child: coverImage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoverImageStack extends StatelessWidget {
  final List<Song> songs;

  const CoverImageStack({Key? key, required this.songs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const imageCount = 4;
    List<ImageProvider> images = [];

    if (songs.isNotEmpty) {
      images = songs
          .where((song) {
            return song.image is NetworkImage &&
                !(song.image as NetworkImage).url.endsWith('unknown-album.png');
          })
          .map((song) => song.image)
          .toList();

      images.shuffle();
      images = images.take(imageCount).toList();
    }

    // fill up to 4 images
    for (int i = images.length; i < imageCount; ++i) {
      images.insert(0, AssetImage('assets/images/unknown-album.png'));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: -16,
          top: -24,
          child: CoverImage(image: images[0], overlayOpacity: .8),
        ),
        Positioned(
          left: 32,
          top: -16,
          child: CoverImage(image: images[1], overlayOpacity: .6),
        ),
        Positioned(
          left: 14,
          top: 20,
          child: CoverImage(image: images[2], overlayOpacity: .4),
        ),
        CoverImage(image: images[3]),
      ],
    );
  }
}

class CoverImage extends StatelessWidget {
  final double overlayOpacity;
  final ImageProvider<Object> image;

  const CoverImage({
    Key? key,
    required this.image,
    this.overlayOpacity = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(overlayOpacity),
              BlendMode.srcOver,
            ),
            image: image,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: const <BoxShadow>[
            const BoxShadow(
              color: Colors.black38,
              blurRadius: 10.0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      ),
    );
  }
}
