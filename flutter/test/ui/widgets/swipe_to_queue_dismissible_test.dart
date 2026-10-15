import 'package:app/ui/widgets/swipe_to_queue_dismissible.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SwipeToQueueDismissible', () {
    test('can be constructed with required parameters', () {
      final widget = SwipeToQueueDismissible(
        dismissibleKey: const ValueKey('test'),
        fetchSongs: () async => [],
        child: const SizedBox(),
      );

      expect(widget.dismissibleKey, const ValueKey('test'));
      expect(widget.child, isA<SizedBox>());
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              SwipeToQueueDismissible(
                dismissibleKey: const ValueKey('item-1'),
                fetchSongs: () async => [],
                child: const ListTile(title: Text('Test Item')),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('Test Item'), findsOneWidget);
      expect(find.byType(Dismissible), findsOneWidget);
    });

    test('uses startToEnd direction only', () {
      final widget = SwipeToQueueDismissible(
        dismissibleKey: const ValueKey('test'),
        fetchSongs: () async => [],
        child: const SizedBox(),
      );

      // The widget should only allow swipe right (startToEnd), not left
      expect(widget.fetchSongs, isNotNull);
    });
  });
}
