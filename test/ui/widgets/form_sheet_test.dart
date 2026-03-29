import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestApp({required Widget child}) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('Form sheet buttons visibility', () {
    testWidgets('buttons are visible with few fields', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showFormSheet(
              context,
              title: 'Test Form',
              submitLabel: 'Submit',
              onSubmit: () async {},
              builder: (context, setState) => Column(
                children: [
                  TextField(decoration: InputDecoration(hintText: 'Field 1')),
                ],
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Buttons must exist
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);

      // Buttons must be within the visible screen bounds
      final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
      final cancelRect = tester.getRect(find.text('Cancel'));
      final submitRect = tester.getRect(find.text('Submit'));

      expect(cancelRect.bottom, lessThanOrEqualTo(screenSize.height),
          reason: 'Cancel button must be within visible screen');
      expect(submitRect.bottom, lessThanOrEqualTo(screenSize.height),
          reason: 'Submit button must be within visible screen');
    });

    testWidgets('buttons are visible with many fields', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showFormSheet(
              context,
              title: 'Test Form',
              submitLabel: 'Save',
              onSubmit: () async {},
              builder: (context, setState) => Column(
                children: [
                  TextField(decoration: InputDecoration(hintText: 'Field 1')),
                  const SizedBox(height: 8),
                  TextField(decoration: InputDecoration(hintText: 'Field 2')),
                  const SizedBox(height: 8),
                  TextField(decoration: InputDecoration(hintText: 'Field 3')),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(hintText: 'Field 4'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CupertinoSwitch(value: false, onChanged: (_) {}),
                      const SizedBox(width: 8),
                      const Text('A toggle option'),
                    ],
                  ),
                ],
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
      final cancelRect = tester.getRect(find.text('Cancel'));
      final saveRect = tester.getRect(find.text('Save'));

      expect(cancelRect.bottom, lessThanOrEqualTo(screenSize.height),
          reason: 'Cancel button must be within visible screen');
      expect(saveRect.bottom, lessThanOrEqualTo(screenSize.height),
          reason: 'Save button must be within visible screen');
    });

    testWidgets('buttons are tappable', (tester) async {
      var submitted = false;

      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showFormSheet(
              context,
              title: 'Test Form',
              submitLabel: 'Go',
              canSubmit: () => true,
              onSubmit: () async {
                submitted = true;
                Navigator.pop(context);
              },
              builder: (context, setState) =>
                  TextField(decoration: InputDecoration(hintText: 'Name')),
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(submitted, isTrue);
    });
  });
}
