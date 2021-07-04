import 'package:app/models/album.dart';
import 'package:app/providers/album_provider.dart';
import 'package:app/ui/screens/album_details.dart';
import 'package:app/ui/widgets/album_thumbnail.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumsScreen extends StatefulWidget {
  final String? previousPageTitle;

  const AlbumsScreen({Key? key, this.previousPageTitle}) : super(key: key);

  @override
  _AlbumsScreenState createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  late AlbumProvider albumProvider;
  late List<Album> _albums = [];

  @override
  void initState() {
    super.initState();
    albumProvider = context.read();
    setState(() => _albums = albumProvider.albums);
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
              'Albums',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                Album album = _albums[index];
                return InkWell(
                  onTap: () => gotoDetailsScreen(context, album: album),
                  child: ListTile(
                    shape: Border(bottom: Divider.createBorderSide(context)),
                    leading: AlbumThumbnail(album: album),
                    title: Text(album.name, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      album.artist.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
              childCount: _albums.length,
            ),
          ),
          SliverToBoxAdapter(child: bottomSpace()),
        ],
      ),
    );
  }
}
