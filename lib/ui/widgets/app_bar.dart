import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle/figma_squircle.dart';
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
            AppColors.flexibleScreenHeaderBackground,
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final backgroundImage = this.backgroundImage;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 290,
      actions: actions,
      backgroundColor: AppColors.flexibleScreenHeaderBackground,
      flexibleSpace: FrostedGlassBackground(
        child: FlexibleSpaceBar(
          expandedTitleScale: 1.3,
          titlePadding: EdgeInsets.symmetric(
            horizontal: 48,
            vertical: 12,
          ),
          title: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.hPadding,
            ),
            child: Text(
              headingText,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          background: Stack(
            children: <Widget>[
              if (backgroundImage != null) backgroundImage,
              _gradientEffect,
              Center(
                child: SizedBox.square(
                  dimension: 192,
                  child: coverImage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoverImageStack extends StatelessWidget {
  final List<Playable> playables;

  const CoverImageStack({Key? key, required this.playables}) : super(key: key);

  bool get isEmpty => playables.isEmpty;

  @override
  Widget build(BuildContext context) {
    const imageCount = 4;
    List<String?> images = [];

    if (playables.isNotEmpty) {
      images = playables.where((playable) => playable.hasCustomImage).map(
        (playable) {
          if (playable is Song) {
            return playable.albumCoverUrl;
          } else if (playable is Episode) {
            return playable.imageUrl;
          }
        },
      ).toList();

      images.shuffle();
      images = images.take(imageCount).toList();
    }

    // fill up to 4 images
    for (int i = images.length; i < imageCount; ++i) {
      images.insert(0, null);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: -16,
          top: -24,
          child: CoverImage(imageUrl: images[0], overlayOpacity: .8),
        ),
        Positioned(
          left: 32,
          top: -16,
          child: CoverImage(imageUrl: images[1], overlayOpacity: .6),
        ),
        Positioned(
          left: 14,
          top: 20,
          child: CoverImage(imageUrl: images[2], overlayOpacity: .4),
        ),
        CoverImage(imageUrl: images[3]),
      ],
    );
  }
}

class CoverImage extends StatelessWidget {
  final double overlayOpacity;
  final String? imageUrl;

  const CoverImage({
    Key? key,
    required this.imageUrl,
    this.overlayOpacity = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = this.imageUrl;

    return SizedBox(
      width: 160,
      height: 160,
      child: ClipSmoothRect(
        radius: SmoothBorderRadius(
          cornerRadius: 16,
          cornerSmoothing: .8,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              colorFilter: ColorFilter.mode(
                AppColors.flexibleScreenHeaderBackground
                    .withOpacity(overlayOpacity),
                BlendMode.srcOver,
              ),
              image: imageUrl == null
                  ? AppImages.defaultImage.image
                  : CachedNetworkImageProvider(imageUrl),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            boxShadow: const <BoxShadow>[
              const BoxShadow(
                color: AppColors.flexibleScreenHeaderBackground,
                blurRadius: 10.0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
