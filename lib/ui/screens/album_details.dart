import 'dart:ui';

import 'package:app/constants/dimens.dart';
import 'package:app/models/album.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/song_provider.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumDetailsScreen extends StatelessWidget {
  final Album album;

  AlbumDetailsScreen({Key? key, required this.album}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Song> _songs = Provider.of<SongProvider>(context).byAlbum(album);
    _songs.sort((a, b) => a.title.compareTo(b.title));

    ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      primary: Colors.grey.shade900,
      onPrimary: Colors.red,
      textStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 290,
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(album.name, overflow: TextOverflow.ellipsis),
              ),
              background: Stack(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: album.image,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: 192,
                      height: 192,
                      child: Hero(
                        tag: "album-hero-${album.id}",
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: album.image,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.3),
                                blurRadius: 10.0,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(AppDimens.horizontalPadding),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints.expand(
                        width: double.infinity,
                        height: 48,
                      ),
                      child: ElevatedButton(
                        style: _buttonStyle,
                        onPressed: () async {
                          List<MediaItem> mediaItems = await Future.wait(
                            _songs.map(
                              (song) async => await song.asMediaItem(),
                            ),
                          );
                          AudioService.updateQueue(mediaItems);
                        },
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.play_arrow),
                            Expanded(
                              child: Text(
                                'Play All',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints.expand(
                        width: double.infinity,
                        height: 48,
                      ),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: _buttonStyle,
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.shuffle),
                            Expanded(
                              child: Text(
                                'Shuffle',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SongList(songs: _songs),
        ],
      ),
    );
  }
}
