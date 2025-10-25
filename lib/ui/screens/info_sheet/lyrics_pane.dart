import 'dart:async';
import 'package:app/models/models.dart';
import 'package:app/ui/screens/info_sheet/info_sheet.dart';
import 'package:app/utils/lrc_parser.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LyricsPane extends StatefulWidget {
  final Song song;

  LyricsPane({Key? key, required this.song}) : super(key: key);

  @override
  State<LyricsPane> createState() => _LyricsPaneState();
}

class _LyricsPaneState extends State<LyricsPane> {
  List<LrcLine> _lrcLines = [];
  int _currentLineIndex = -1;
  StreamSubscription<Duration>? _positionSubscription;
  final ScrollController _scrollController = ScrollController();
  bool _isSyncedLyrics = false;

  @override
  void initState() {
    super.initState();
    _parseLyrics();
    if (_isSyncedLyrics) {
      _subscribeToPosition();
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _parseLyrics() {
    final lyrics = widget.song.lyrics;
    _isSyncedLyrics = LrcParser.hasSyncedLyrics(lyrics);

    if (_isSyncedLyrics) {
      _lrcLines = LrcParser.parse(lyrics);
    }
  }

  void _subscribeToPosition() {
    _positionSubscription = AudioService.position.listen((position) {
      final currentTime = position.inMilliseconds / 1000.0;
      int newIndex = -1;

      for (int i = _lrcLines.length - 1; i >= 0; i--) {
        if (currentTime >= _lrcLines[i].time) {
          newIndex = i;
          break;
        }
      }

      if (newIndex != _currentLineIndex && mounted) {
        setState(() {
          _currentLineIndex = newIndex;
        });
        _scrollToCurrentLine();
      }
    });
  }

  void _scrollToCurrentLine() {
    if (_currentLineIndex < 0 || !_scrollController.hasClients) return;

    final double itemHeight = 60.0; // Approximate height per line
    final double targetPosition = _currentLineIndex * itemHeight;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double offset = targetPosition - screenHeight / 3;

    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.song.lyrics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text(
          'No lyrics available.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    if (_isSyncedLyrics) {
      return _buildSyncedLyrics();
    } else {
      return _buildPlainLyrics();
    }
  }

  Widget _buildSyncedLyrics() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      itemCount: _lrcLines.length,
      itemBuilder: (context, index) {
        final isActive = index == _currentLineIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: isActive ? 20 : 16,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? Colors.white : Colors.white54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            child: Text(_lrcLines[index].text),
          ),
        );
      },
    );
  }

  Widget _buildPlainLyrics() {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: InfoHtml(
        content: widget.song.lyrics
            .replaceAll('\n', '<br>')
            .replaceAll('\r', '<br>'),
        style: Style(fontSize: FontSize.larger),
      ),
    );
  }
}
