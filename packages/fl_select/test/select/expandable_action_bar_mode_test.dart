import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the action bar visibility on
/// [ExpandableSelectDelegate]: visibility must follow
/// [SelectController.hasMultipleMode] — the delegate-level mode OR any
/// category opting into multiple — consistent with the grid / wrap /
/// tab-nav / side-nav / cascading layouts. Previously a delegate-level
/// single with a multiple category hid the bar while taps still deferred
/// to "Apply", leaving the multi-selection impossible to apply.

Widget _harness(SelectDelegate delegate, {SelectCallback? onApplyTap}) =>
    MaterialApp(
      home: Scaffold(
        // SelectPanel without a SelectActionBarVisibility scope keeps the
        // action bar visible (SelectView hides it for inline usage).
        body: SelectPanel(
          delegate: delegate,
          onApplyTap: onApplyTap,
        ),
      ),
    );

void main() {
  testWidgets(
      'a category opting into multiple shows the action bar even when the '
      'delegate mode is single', (tester) async {
    await tester.pumpWidget(
      _harness(
        ExpandableSelectDelegate(
          selectionMode: SelectionMode.single,
          entries: {
            SelectCategoryEntry<dynamic>.children(
              id: 'cat',
              name: 'Category',
              selectionMode: SelectionMode.multiple,
              children: {
                SelectTextEntry<dynamic>.name(id: 'a', name: 'Item A'),
                SelectTextEntry<dynamic>.name(id: 'b', name: 'Item B'),
              },
            ),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SelectActionBar), findsOneWidget);
  });

  testWidgets('pure single selection hides the action bar', (tester) async {
    await tester.pumpWidget(
      _harness(
        ExpandableSelectDelegate(
          selectionMode: SelectionMode.single,
          entries: {
            SelectCategoryEntry<dynamic>.children(
              id: 'cat',
              name: 'Category',
              children: {
                SelectTextEntry<dynamic>.name(id: 'a', name: 'Item A'),
              },
            ),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SelectActionBar), findsNothing);
  });

  testWidgets(
      'mixed mode defers applying to the action bar instead of applying on '
      'tap', (tester) async {
    var applied = 0;
    await tester.pumpWidget(
      _harness(
        ExpandableSelectDelegate(
          selectionMode: SelectionMode.single,
          entries: {
            SelectCategoryEntry<dynamic>.children(
              id: 'cat',
              name: 'Category',
              selectionMode: SelectionMode.multiple,
              children: {
                SelectTextEntry<dynamic>.name(id: 'a', name: 'Item A'),
              },
            ),
          },
        ),
        onApplyTap: (_) => applied++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Item A'));
    await tester.pumpAndSettle();
    expect(applied, 0);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(applied, 1);
  });
}
