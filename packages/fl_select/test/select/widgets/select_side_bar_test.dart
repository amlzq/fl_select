import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders a [SelectSideBar] directly so we can assert its scroll-to-center
/// behavior. Twenty 44px-tall tiles overflow the 600px-tall test surface, so
/// the sidebar has real scroll extents.
final List<SelectEntry> _categories = [
  for (var i = 0; i < 20; i++)
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
      body: SelectSideBar(
        entries: _categories,
        selectedCategories: {_categories[focusedIndex]},
        focusedIndex: focusedIndex,
        isScrollable: isScrollable,
        onChanged: onChanged ?? (_, __) {},
      ),
    ),
  );
}

void main() {
  testWidgets('tapping a tile scrolls it to the center when isScrollable',
      (tester) async {
    var tappedIndex = -1;
    await tester.pumpWidget(_harness(
      onChanged: (index, _) => tappedIndex = index,
    ));

    expect(find.byType(SingleChildScrollView), findsOneWidget);

    // Category 9 (center at 418px) starts fully visible below the middle;
    // centering it requires a positive offset, while tiles near the start
    // clamp to 0.
    final rectBefore = tester.getRect(find.text('Category 9'));
    await tester.tap(find.text('Category 9'));
    await tester.pumpAndSettle();

    expect(tappedIndex, 9);
    final rectAfter = tester.getRect(find.text('Category 9'));
    // The sidebar scrolled: the tile moved and is now centered (dy = 300 on
    // the 600px-tall test surface).
    expect(rectAfter.top, lessThan(rectBefore.top));
    expect(rectAfter.center.dy, closeTo(300, 30));
  });

  testWidgets('a focusedIndex change from outside scrolls to the center',
      (tester) async {
    await tester.pumpWidget(_harness(focusedIndex: 0));
    final rectBefore = tester.getRect(find.text('Category 9'));

    // Simulates a programmatic category switch (e.g. SideNavSelectDelegate
    // rebuilding with a new focused category).
    await tester.pumpWidget(_harness(focusedIndex: 9));
    await tester.pumpAndSettle();

    final rectAfter = tester.getRect(find.text('Category 9'));
    expect(rectAfter.top, lessThan(rectBefore.top));
    expect(rectAfter.center.dy, closeTo(300, 30));
  });

  testWidgets('isScrollable=false renders an expanded non-scrollable column',
      (tester) async {
    await tester.pumpWidget(_harness(
      isScrollable: false,
      focusedIndex: 9,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsNothing);
    // All tiles share the height equally.
    final rect = tester.getRect(find.byType(SelectListTile).first);
    expect(rect.height, closeTo(600 / 20, 1));
  });
}
