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
              onSubmit: (_) async {},
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
              onSubmit: (_) async {},
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
              onSubmit: (sheetContext) async {
                submitted = true;
                Navigator.pop(sheetContext);
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

  group('onSubmit context lifetime', () {
    testWidgets(
      'sheet closes via onSubmit context even after the route that opened '
      'it is already gone',
      (tester) async {
        // Reproduces the artist/album action-sheet flow:
        //   1. Action sheet's Edit row runs
        //        Navigator.pop(actionSheetContext)
        //        showEditDialog(actionSheetContext)   // form sheet opens
        //   2. The form sheet captures the now-doomed actionSheetContext.
        //   3. Save tapped, awaits a network round-trip.
        //   4. By the time onSubmit's body runs, actionSheetContext is
        //      defunct, so Navigator.pop on it silently fails.
        //
        // The fix: showFormSheet hands its own (always-mounted) context
        // to onSubmit, so the body uses that for pop/showOverlay.

        await tester.pumpWidget(buildTestApp(
          child: Builder(
            builder: (rootContext) => ElevatedButton(
              onPressed: () {
                Navigator.of(rootContext).push(MaterialPageRoute<void>(
                  builder: (innerContext) => Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(innerContext);
                          showFormSheet(
                            innerContext,
                            title: 'Edit',
                            submitLabel: 'Save',
                            canSubmit: () => true,
                            onSubmit: (sheetContext) async {
                              // Simulate a network round-trip; the inner
                              // route finishes its dismissal animation
                              // during this gap.
                              await Future<void>.delayed(
                                const Duration(milliseconds: 50),
                              );
                              if (!sheetContext.mounted) return;
                              Navigator.pop(sheetContext);
                            },
                            builder: (_, __) => const SizedBox(),
                          );
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                  ),
                ));
              },
              child: const Text('Open'),
            ),
          ),
        ));

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        expect(find.text('Save'), findsOneWidget,
            reason: 'form sheet should be open');

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Save'), findsNothing,
            reason: 'form sheet must close after Save');
      },
    );

    testWidgets('onSubmit receives a mounted context', (tester) async {
      BuildContext? captured;

      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showFormSheet(
              context,
              title: 'Test',
              submitLabel: 'Save',
              canSubmit: () => true,
              onSubmit: (sheetContext) async {
                captured = sheetContext;
                Navigator.pop(sheetContext);
              },
              builder: (_, __) => const SizedBox(),
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      // After pop, the captured context should be unmounted — proving it
      // was the form sheet's own context, not some outer ancestor.
      expect(captured!.mounted, isFalse);
    });
  });
}
