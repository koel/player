import 'package:app/ui/widgets/alphabet_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlphabetScrollbar', () {
    late ScrollController scrollController;

    setUp(() {
      scrollController = ScrollController();
    });

    tearDown(() {
      scrollController.dispose();
    });

    Widget buildTestWidget({
      required List<String> labels,
      double itemExtent = 72.0,
      int minItemCount = 0,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: Stack(
              children: [
                ListView.builder(
                  controller: scrollController,
                  itemCount: labels.length,
                  itemExtent: itemExtent,
                  itemBuilder: (_, i) => ListTile(title: Text(labels[i])),
                ),
                AlphabetScrollbar(
                  labels: labels,
                  scrollController: scrollController,
                  itemCount: labels.length,
                  itemExtent: itemExtent,
                  minItemCount: minItemCount,
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('renders letters for items', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        labels: ['Apple', 'Banana', 'Cherry'],
      ));

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('deduplicates letters', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        labels: ['Apple', 'Avocado', 'Banana'],
      ));

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('hides when only one letter', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        labels: ['Apple', 'Avocado', 'Apricot'],
      ));

      expect(find.text('A'), findsNothing);
    });

    testWidgets('hides when labels are empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(labels: []));

      expect(find.byType(AlphabetScrollbar), findsOneWidget);
      expect(find.text('A'), findsNothing);
    });

    testWidgets('uppercases letters', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        labels: ['apple', 'banana'],
      ));

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('groups non-alpha characters under #', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        labels: ['1999', '[Bonus]', 'Apple'],
      ));

      expect(find.text('#'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('hides when item count is below minItemCount', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        labels: ['Apple', 'Banana', 'Cherry'],
        minItemCount: 100,
      ));

      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsNothing);
    });
  });

  group('AlphabetScrollbar.shouldShow', () {
    test('returns true when sorting by name with enough items', () {
      expect(
        AlphabetScrollbar.shouldShow(
          itemCount: 150,
          sortField: 'name',
          nameSortField: 'name',
        ),
        isTrue,
      );
    });

    test('returns false when sorting by a different field', () {
      expect(
        AlphabetScrollbar.shouldShow(
          itemCount: 150,
          sortField: 'year',
          nameSortField: 'name',
        ),
        isFalse,
      );
    });

    test('returns false when item count is below threshold', () {
      expect(
        AlphabetScrollbar.shouldShow(
          itemCount: 50,
          sortField: 'name',
          nameSortField: 'name',
        ),
        isFalse,
      );
    });

    test('returns true at exactly the threshold', () {
      expect(
        AlphabetScrollbar.shouldShow(
          itemCount: 100,
          sortField: 'title',
          nameSortField: 'title',
        ),
        isTrue,
      );
    });

    test('respects custom minItemCount', () {
      expect(
        AlphabetScrollbar.shouldShow(
          itemCount: 30,
          sortField: 'name',
          nameSortField: 'name',
          minItemCount: 20,
        ),
        isTrue,
      );
    });
  });
}
