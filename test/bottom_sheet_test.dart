import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [SelectDelegate] whose body is a simple widget, so the bottom sheet
/// wrapper can be exercised without relying on a concrete selector's data
/// handling.
class _SheetTestDelegate extends SelectDelegate {
  _SheetTestDelegate()
      : super(entriesLoader: () async => <SelectEntry<dynamic>>{});

  @override
  Widget buildBody(
    BuildContext context,
    List<SelectEntry> entries,
    Set<SelectEntry>? previousSelected,
  ) =>
      const Text('body');

  @override
  Widget buildSkeleton(BuildContext context) => const Text('skeleton');
}

void main() {
  group('showModalBottomSelect', () {
    testWidgets('shows a bottom sheet and returns null when dismissed',
        (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Placeholder()),
        ),
      );

      final future = showModalBottomSelect(
        context: navigatorKey.currentContext!,
        delegate: _SheetTestDelegate(),
      );

      await tester.pumpAndSettle();

      // The selector panel is rendered inside a modal bottom sheet.
      expect(find.byType(SelectPanel), findsOneWidget);

      // Simulate a barrier/drag dismiss (returns null).
      Navigator.of(navigatorKey.currentContext!, rootNavigator: true).pop(null);

      final SelectEntries? result = await future;
      expect(result, isNull);
    });

    testWidgets('returns the popped selection', (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Placeholder()),
        ),
      );

      final future = showModalBottomSelect(
        context: navigatorKey.currentContext!,
        delegate: _SheetTestDelegate(),
      );

      await tester.pumpAndSettle();

      final selection = <SelectEntry>{};
      Navigator.of(navigatorKey.currentContext!, rootNavigator: true)
          .pop(selection);

      final SelectEntries? result = await future;
      expect(result, selection);
    });
  });
}
