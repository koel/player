import 'package:app/models/album.dart';
import 'package:flutter/material.dart';

class AlbumCard extends StatelessWidget {
  final Album album;

  AlbumCard({Key? key, required this.album}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new Container(),
    );
  }
}
