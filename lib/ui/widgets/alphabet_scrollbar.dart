import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const alphabetScrollbarWidth = 20.0;

class AlphabetScrollbar extends StatefulWidget {
  final List<String> labels;
  final ScrollController scrollController;
  final int itemCount;
  final double itemExtent;

  /// Offset in pixels from the top of the scroll view to the first item
  /// (accounts for headers, nav bars, etc.)
  final double scrollOffset;
  final int minItemCount;

  const AlphabetScrollbar({
    Key? key,
    required this.labels,
    required this.scrollController,
    required this.itemCount,
    this.itemExtent = 72.0,
    this.scrollOffset = 0.0,
    this.minItemCount = 100,
  }) : super(key: key);

  @override
  _AlphabetScrollbarState createState() => _AlphabetScrollbarState();

  static bool shouldShow({
    required int itemCount,
    required String sortField,
    required String nameSortField,
    int minItemCount = 100,
  }) {
    return sortField == nameSortField && itemCount >= minItemCount;
  }
}

class _AlphabetScrollbarState extends State<AlphabetScrollbar> {
  String? _activeLetter;

  Map<String, int> _buildLetterIndex() {
    final index = <String, int>{};

    for (var i = 0; i < widget.labels.length; i++) {
      final label = widget.labels[i];
      if (label.isEmpty) continue;

      final char = label[0].toUpperCase();
      final letter = RegExp(r'[A-Z]').hasMatch(char) ? char : '#';
      index.putIfAbsent(letter, () => i);
    }

    return index;
  }

  void _scrollToLetter(String letter, Map<String, int> letterIndex) {
    final itemIndex = letterIndex[letter];
    if (itemIndex == null) return;

    final target = widget.scrollOffset + itemIndex * widget.itemExtent;
    final maxScroll = widget.scrollController.position.maxScrollExtent;

    widget.scrollController.jumpTo(target.clamp(0.0, maxScroll));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.labels.isEmpty || widget.itemCount < widget.minItemCount) {
      return const SizedBox.shrink();
    }

    final letterIndex = _buildLetterIndex();
    final letters = letterIndex.keys.toList();

    if (letters.length <= 1) return const SizedBox.shrink();

    return Positioned(
      right: 2,
      top: 0,
      bottom: 0,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight * 0.7;
            final letterHeight = (maxHeight / letters.length).clamp(13.0, 18.0);

            return GestureDetector(
              onVerticalDragUpdate: (details) {
                final index = (details.localPosition.dy / letterHeight).floor();
                if (index < 0 || index >= letters.length) {
                  setState(() => _activeLetter = null);
                  return;
                }
                final letter = letters[index];
                if (letter != _activeLetter) {
                  setState(() => _activeLetter = letter);
                  HapticFeedback.selectionClick();
                  _scrollToLetter(letter, letterIndex);
                }
              },
              onVerticalDragEnd: (_) {
                setState(() => _activeLetter = null);
              },
              onTapUp: (details) {
                final index = (details.localPosition.dy / letterHeight).floor();
                if (index >= 0 && index < letters.length) {
                  _scrollToLetter(letters[index], letterIndex);
                  setState(() => _activeLetter = letters[index]);
                  Future.delayed(
                    const Duration(milliseconds: 300),
                    () {
                      if (mounted) setState(() => _activeLetter = null);
                    },
                  );
                }
              },
              child: Container(
                width: alphabetScrollbarWidth,
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: letters.map((letter) {
                    final isActive = letter == _activeLetter;

                    return SizedBox(
                      height: letterHeight,
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? Colors.white : Colors.white38,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
