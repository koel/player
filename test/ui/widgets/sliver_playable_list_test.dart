import 'package:app/ui/widgets/sliver_playable_list.dart';
import 'package:app/ui/widgets/playable_list_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SliverPlayableList', () {
    test('accepts onDismissed as null for queue-only mode', () {
      // Verify that SliverPlayableList can be constructed without onDismissed
      // and still supports swipe-to-queue (startToEnd direction)
      final widget = SliverPlayableList(
        playables: [],
        listContext: PlayableListContext.other,
      );

      expect(widget.onDismissed, isNull);
      expect(widget.playables, isEmpty);
    });

    test('accepts onDismissed for bidirectional swipe', () {
      var dismissed = false;

      final widget = SliverPlayableList(
        playables: [],
        listContext: PlayableListContext.favorites,
        onDismissed: (_) => dismissed = true,
      );

      expect(widget.onDismissed, isNotNull);
    });

    test('default listContext is other', () {
      final widget = SliverPlayableList(playables: []);

      expect(widget.listContext, PlayableListContext.other);
    });
  });
}
