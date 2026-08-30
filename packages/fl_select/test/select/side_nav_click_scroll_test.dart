import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproduces the SideNavSelect click-to-scroll linkage: tapping a sidebar
/// tile must scroll the right column to that category's section in one
/// continuous animation. Eight tall sections (30 chips each) keep sections
/// 1-7 far below the 600px-tall test viewport.
final Set<SelectEntry> _navCategories = {
  for (var i = 0; i < 8; i++)
    SelectCategoryEntry<dynamic>.children(
      id: 'cate$i',
      name: 'Cate $i',
      children: {
        for (var j = 0; j < 30; j++)
          SelectTextEntry<dynamic>.name(id: 'o${i}_$j', name: 'O $i-$j'),
      },
    ),
};

Widget _harness() {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(
        // Full-height panel so the sidebar (8 tiles ~ 352px) is not clipped
        // by the default maxHeightFactor (0.5) cap.
        maxHeightFactor: 1,
        delegate: SideNavSelectDelegate(
          selectionMode: SelectionMode.single,
          entries: _navCategories,
        ),
        onChanged: (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('tapping a sidebar tile scrolls the right column to the section',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Before the tap, the right column has already built every section (the
    // ListView prefetches 10000px ahead), so both the sidebar copy and the
    // far-below-the-fold section header exist. skipOffstage is required
    // because finders skip children outside the viewport's paint extent,
    // even though they are inflated in the cache extent.
    expect(find.text('Cate 5', skipOffstage: false), findsNWidgets(2));

    // The sidebar tile (a SelectListTile), not the section header.
    await tester.tap(find.byType(SelectListTile).at(5));
    await tester.pumpAndSettle();
    // Let the 100ms highlight-guard timer after the final animation fire.
    await tester.pump(const Duration(milliseconds: 150));

    // The section box (including its 18px top padding) rests at the top of
    // the viewport, so the title sits 18px below the top edge.
    expect(find.text('Cate 5'), findsNWidgets(2));
    // Tree order: the sidebar copy comes first, the section header last.
    final header = tester.getRect(find.text('Cate 5').last);
    expect(header.top, closeTo(18.0, 1.0));
  });

  testWidgets(
      'tapping a nearby sidebar tile still scrolls (within cache extent)',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Section 1 sits just below the fold; with the infinite cache extent it
    // is always inflated and the linkage works the same as for far sections.
    await tester.tap(find.byType(SelectListTile).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Cate 1'), findsNWidgets(2));
    final header = tester.getRect(find.text('Cate 1').last);
    expect(header.top, closeTo(18.0, 1.0));
  });

  testWidgets('scrolling up from the bottom never overshoots and bounces back',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // The right column's scrollable is the last one in tree order (the
    // sidebar's SingleChildScrollView comes first).
    final scrollable = find.byType(Scrollable).last;
    double offset() =>
        tester.state<ScrollableState>(scrollable).position.pixels;

    // Start at the bottom like a real user would (cate 7), then tap cate 1.
    await tester.tap(find.byType(SelectListTile).at(7));
    await tester.pumpAndSettle();
    final bottom = offset();
    expect(bottom, greaterThan(0));

    await tester.tap(find.byType(SelectListTile).at(1));

    // Sample every frame. The tap drives a single continuous ease-in-out
    // animation, which is monotonic: it must never dip below the final
    // resting offset and bounce back up (the overshoot bug the old
    // estimate-then-correct jump used to cause).
    final offsets = <double>[];
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      offsets.add(offset());
    }
    expect(offsets.last, lessThan(bottom));
    for (var i = 1; i < offsets.length; i++) {
      expect(offsets[i], lessThanOrEqualTo(offsets[i - 1] + 0.5));
    }
  });
}
