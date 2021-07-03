import 'package:app/models/playlist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/playlist_provider.dart';
import 'package:app/ui/screens/playlist_details.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistsScreen extends StatefulWidget {
  final String? previousPageTitle;

  const PlaylistsScreen({Key? key, this.previousPageTitle}) : super(key: key);

  @override
  _PlaylistsScreenState createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  late PlaylistProvider playlistProvider;
  late List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    playlistProvider = context.read();
    setState(() => _playlists = playlistProvider.playlists);
  }

  Widget playlistThumbnail({required Playlist playlist}) {
    ImageProvider? thumbnail;

    if (!playlist.isEmpty) {
      // generate a nice thumbnail from the playlist's content
      Song songWithCustomImage = playlist.songs.firstWhere((song) {
        return song.image is NetworkImage &&
            !(song.image as NetworkImage).url.endsWith('unknown-album.png');
      }, orElse: () => playlist.songs[0]);

      thumbnail = songWithCustomImage.image;
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          image: thumbnail != null
              ? DecorationImage(image: thumbnail, fit: BoxFit.cover)
              : null,
        ),
        child: thumbnail == null
            ? Opacity(
                opacity: .5,
                child: Icon(CupertinoIcons.music_note_list),
              )
            : SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: Colors.black,
            previousPageTitle: widget.previousPageTitle,
            largeTitle: Text(
              'Playlists',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                Playlist playlist = _playlists[index];
                return InkWell(
                  onTap: () => gotoDetailsScreen(
                    context,
                    playlist: _playlists[index],
                  ),
                  child: ListTile(
                    shape: Border(bottom: Divider.createBorderSide(context)),
                    leading: playlistThumbnail(playlist: playlist),
                    title: Text(playlist.name, overflow: TextOverflow.ellipsis),
                  ),
                );
              },
              childCount: _playlists.length,
            ),
          ),
          SliverToBoxAdapter(child: bottomSpace()),
        ],
      ),
    );
  }
}
