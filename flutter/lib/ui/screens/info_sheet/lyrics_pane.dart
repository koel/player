import 'dart:async';
import 'dart:convert';
import 'package:app/models/models.dart';
import 'package:app/ui/screens/info_sheet/info_sheet.dart';
import 'package:app/utils/lrc_parser.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LyricsPane extends StatefulWidget {
  final Song song;
  final ScrollController? parentScrollController;

  LyricsPane({
    Key? key,
    required this.song,
    this.parentScrollController,
  }) : super(key: key);

  @override
  State<LyricsPane> createState() => _LyricsPaneState();
}

class _LyricsPaneState extends State<LyricsPane> {
  List<LrcLine> _lrcLines = [];
  int _currentLineIndex = -1;
  StreamSubscription<Duration>? _positionSubscription;
  bool _isSyncedLyrics = false;
  final List<GlobalKey> _lineKeys = [];

  @override
  void initState() {
    super.initState();
    _parseLyrics();
    if (_isSyncedLyrics) {
      _subscribeToPosition();
    }
  }

  @override
  void didUpdateWidget(LyricsPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _positionSubscription?.cancel();
      _parseLyrics();
      if (_isSyncedLyrics) {
        _subscribeToPosition();
      } else {
        _positionSubscription = null;
      }
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _parseLyrics() {
    final lyrics = widget.song.lyrics;
    _isSyncedLyrics = LrcParser.hasSyncedLyrics(lyrics);

    if (_isSyncedLyrics) {
      _lrcLines = LrcParser.parse(lyrics);
      if (_lrcLines.isEmpty) {
        _isSyncedLyrics = false;
      } else {
        // Initialize GlobalKeys for each line
        _lineKeys.clear();
        for (int i = 0; i < _lrcLines.length; i++) {
          _lineKeys.add(GlobalKey());
        }
      }
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
    if (_currentLineIndex < 0 ||
        _currentLineIndex >= _lineKeys.length ||
        widget.parentScrollController == null ||
        !widget.parentScrollController!.hasClients) {
      return;
    }

    final currentKey = _lineKeys[_currentLineIndex];
    final context = currentKey.currentContext;

    if (context != null) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      final scrollController = widget.parentScrollController!;
      final viewportHeight = scrollController.position.viewportDimension;
      final currentScrollOffset = scrollController.offset;

      final targetOffset =
          currentScrollOffset + position.dy - (viewportHeight / 2) + (size.height / 2);

      final minScrollExtent = scrollController.position.minScrollExtent;
      final maxScrollExtent = scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(minScrollExtent, maxScrollExtent);

      scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      itemCount: _lrcLines.length,
      itemBuilder: (context, index) {
        final isActive = index == _currentLineIndex;
        return Padding(
          key: _lineKeys[index],
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
    final normalizedLyrics = widget.song.lyrics
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final escapedLyrics =
        const HtmlEscape().convert(normalizedLyrics).replaceAll('\n', '<br>');

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: InfoHtml(
        content: escapedLyrics,
        style: Style(fontSize: FontSize.larger),
      ),
    );
  }
}
