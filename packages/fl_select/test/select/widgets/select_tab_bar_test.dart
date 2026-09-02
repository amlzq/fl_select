import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders a [SelectTabBar] directly so we can assert its scroll-to-center
/// behavior. Sixteen categories overflow the 800px-wide test surface, so the
/// bar has real scroll extents.
final List<SelectEntry> _categories = [
  for (var i = 0; i < 16; i++)
    SelectCategoryEntry<dynamic>.children(
      id: 'cate$i',
      name: 'Category $i',
      children: {
        SelectTextEntry<dynamic>.name(id: 'a$i', name: 'A $i'),
      },
    ),
];

Widget _harness({
  int focusedIndex = 0,
  bool isScrollable = true,
  void Function(int index, SelectEntry entry)? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectTabBar(
        entries: _categories,
        selectedCategories: <SelectEntry>{},
        focusedIndex: focusedIndex,
        isScrollable: isScrollable,
        onChanged: onChanged ?? (_, __) {},
      ),
    ),
  );
}

void main() {
  testWidgets('tapping a tab scrolls it to the center when isScrollable',
      (tester) async {
    var tappedIndex = -1;
    await tester.pumpWidget(_harness(
      onChanged: (index, _) => tappedIndex = index,
    ));

    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // Category 4 starts fully visible right of the center; centering it
    // requires a positive offset, while tabs near the start clamp to 0.
    // (The test font is monospaced Ahem, so each ~10-char label is ~149px.)
    final rectBefore = tester.getRect(find.text('Category 4'));
    await tester.tap(find.text('Category 4'));
    await tester.pumpAndSettle();

    expect(tappedIndex, 4);
    final rectAfter = tester.getRect(find.text('Category 4'));
    // The bar scrolled: the tab moved and is now centered (dx = 400 on the
    // 800px-wide test surface).
    expect(rectAfter.left, lessThan(rectBefore.left));
    expect(rectAfter.center.dx, closeTo(400, 30));
  });

  testWidgets('a focusedIndex change from outside scrolls to the center',
      (tester) async {
    await tester.pumpWidget(_harness(focusedIndex: 0));
    final rectBefore = tester.getRect(find.text('Category 4'));

    // Simulates a programmatic category switch (e.g. TabNavSelectDelegate
    // rebuilding with a new focused category).
    await tester.pumpWidget(_harness(focusedIndex: 4));
    await tester.pumpAndSettle();

    final rectAfter = tester.getRect(find.text('Category 4'));
    expect(rectAfter.left, lessThan(rectBefore.left));
    expect(rectAfter.center.dx, closeTo(400, 30));
  });

  testWidgets('isScrollable=false renders an expanded non-scrollable row',
      (tester) async {
    await tester.pumpWidget(_harness(
      isScrollable: false,
      focusedIndex: 4,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsNothing);
    // All tabs share the width equally (minus each tab's 9px inner
    // horizontal padding around the label).
    final rect = tester.getRect(find.text('Category 4'));
    expect(rect.width, closeTo(800 / 16 - 9, 1));
  });

  testWidgets('selectedCategories badges that tab at its top-right corner',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SelectTabBar(
          entries: _categories,
          // Category 2 is badged while Category 0 stays the active tab.
          selectedCategories: {_categories[2]},
          focusedIndex: 0,
          isScrollable: true,
          onChanged: (_, __) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Only the badged category renders a badge...
    expect(find.byType(SelectBadge), findsOneWidget);

    // ...and it hangs off the top-right corner of that tab's label, not of
    // the active one.
    final badge = tester.getRect(find.byType(SelectBadge));
    final label = tester.getRect(find.text('Category 2'));
    expect(badge.right, greaterThan(label.right));
    expect(badge.center.dy, lessThan(label.center.dy));
  });
}
