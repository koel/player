import 'package:app/constants/dimens.dart';
import 'package:app/models/album.dart';
import 'package:app/models/artist.dart';
import 'package:app/models/song.dart';
import 'package:app/providers/search_provider.dart';
import 'package:app/ui/widgets/album_card.dart';
import 'package:app/ui/widgets/artist_card.dart';
import 'package:app/ui/widgets/bottom_space.dart';
import 'package:app/ui/widgets/headings.dart';
import 'package:app/ui/widgets/song_list.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _initial = true;
  List<Song> _songs = [];
  List<Artist> _artists = [];
  List<Album> _albums = [];

  late SearchProvider searchProvider;
  late TextEditingController _searchInputController;

  @override
  void initState() {
    super.initState();
    searchProvider = context.read();
    _searchInputController = TextEditingController(text: '');
  }

  search(String keywords) => EasyDebounce.debounce(
        'search',
        const Duration(microseconds: 500), // typing on a phone isn't that fast
        () async {
          if (keywords.length == 0) return resetSearch();
          if (keywords.length < 2) return;

          SearchResult result =
              await searchProvider.searchExcerpts(keywords: keywords);
          setState(() {
            _initial = false;
            _songs = result.songs;
            _albums = result.albums;
            _artists = result.artists;
          });
        },
      );

  Widget get noResults {
    return Padding(
      padding: const EdgeInsets.only(left: AppDimens.horizontalPadding),
      child: Text(
        'None found.',
        style: TextStyle(color: Colors.white.withOpacity(.5)),
      ),
    );
  }

  void resetSearch() {
    _searchInputController.text = '';
    this.setState(() => _initial = true);
  }

  Widget get searchField {
    return Container(
      padding: const EdgeInsets.all(AppDimens.horizontalPadding),
      color: Colors.black,
      child: CupertinoSearchTextField(
        controller: _searchInputController,
        style: const TextStyle(color: Colors.white),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.1),
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        placeholder: 'Search your library',
        onChanged: search,
        onSuffixTap: resetSearch,
      ),
    );
  }

  Widget get albumResult {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: AppDimens.horizontalPadding),
          child: heading1(text: 'Albums'),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _albums.isNotEmpty
              ? Row(
                  children: <Widget>[
                    ..._albums.expand(
                      (album) => <Widget>[
                        SizedBox(width: AppDimens.horizontalPadding),
                        AlbumCard(album: album),
                      ],
                    ),
                  ],
                )
              : noResults,
        ),
      ],
    );
  }

  Widget get artistResult {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: AppDimens.horizontalPadding),
          child: heading1(text: 'Artists'),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _artists.isNotEmpty
              ? Row(
                  children: [
                    ..._artists.expand(
                      (artist) => <Widget>[
                        SizedBox(width: AppDimens.horizontalPadding),
                        ArtistCard(artist: artist),
                      ],
                    ),
                  ],
                )
              : noResults,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          searchField,
          _initial
              ? SizedBox.shrink()
              : Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SongList(songs: _songs),
                        SizedBox(height: 32),
                        albumResult,
                        SizedBox(height: 32),
                        artistResult,
                        bottomSpace(),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
