import 'package:app/ui/widgets/app_bar.dart' as koel;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBar', () {
    testWidgets('renders heading text and cover image', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              koel.AppBar(
                headingText: 'Test Album',
                coverImage: const Icon(Icons.album),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('Test Album'), findsOneWidget);
      expect(find.byIcon(Icons.album), findsOneWidget);
    });

    testWidgets('renders actions', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              koel.AppBar(
                headingText: 'With Actions',
                coverImage: const SizedBox.shrink(),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ));

      expect(find.byIcon(Icons.sort), findsOneWidget);
    });

    testWidgets('renders without background image', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              koel.AppBar(
                headingText: 'No Background',
                coverImage: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('No Background'), findsOneWidget);
      expect(
        find.byKey(const Key('appBarBackgroundMask')),
        findsNothing,
      );
    });

    testWidgets('renders with background image and ShaderMask',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              koel.AppBar(
                headingText: 'With Background',
                coverImage: const SizedBox.shrink(),
                backgroundImage: Container(color: Colors.blue),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('With Background'), findsOneWidget);
      expect(
        find.byKey(const Key('appBarBackgroundMask')),
        findsOneWidget,
      );
    });

    testWidgets('collapsed bar background is transparent when expanded',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              koel.AppBar(
                headingText: 'Expanded',
                coverImage: const SizedBox.shrink(),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ListTile(title: Text('Item $i')),
                  childCount: 50,
                ),
              ),
            ],
          ),
        ),
      ));

      final opacity = tester.widget<Opacity>(
        find.byKey(const Key('appBarCollapsedBackground')),
      );
      expect(opacity.opacity, 0.0);
    });

    testWidgets('collapsed bar background becomes opaque when scrolled',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              koel.AppBar(
                headingText: 'Scrollable',
                coverImage: const SizedBox.shrink(),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ListTile(title: Text('Item $i')),
                  childCount: 50,
                ),
              ),
            ],
          ),
        ),
      ));

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -500),
        1000,
      );
      await tester.pumpAndSettle();

      final opacity = tester.widget<Opacity>(
        find.byKey(const Key('appBarCollapsedBackground')),
      );
      expect(opacity.opacity, 1.0);
    });
  });
}
