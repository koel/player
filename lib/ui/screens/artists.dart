import 'package:app/models/artist.dart';
import 'package:app/providers/artist_provider.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'artist_details.dart';

class ArtistsScreen extends StatefulWidget {
  final String? previousPageTitle;

  const ArtistsScreen({
    Key? key,
    this.previousPageTitle,
  }) : super(key: key);

  @override
  _ArtistsScreenState createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  late ArtistProvider artistProvider;
  late List<Artist> _artists = [];

  @override
  void initState() {
    super.initState();
    artistProvider = context.read();
    setState(() => _artists = artistProvider.artists);
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
              'Artists',
              style: TextStyle(color: Colors.white),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                Artist artist = _artists[index];
                return InkWell(
                  onTap: () => gotoDetailsScreen(context, artist: artist),
                  child: ListTile(
                    shape: Border(bottom: Divider.createBorderSide(context)),
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: artist.image,
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                    ),
                    title: Text(artist.name, overflow: TextOverflow.ellipsis),
                  ),
                );
              },
              childCount: _artists.length,
            ),
          ),
          SliverToBoxAdapter(child: bottomSpace()),
        ],
      ),
    );
  }
}
