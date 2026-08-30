import 'package:fl_select/fl_select.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two categories with two chips each: far shorter than the panel cap, so the
/// right column's ListView has maxScrollExtent == 0.
final Set<SelectEntry> _shortCategories = {
  for (var i = 0; i < 2; i++)
    SelectCategoryEntry<dynamic>.children(
      id: 'cate$i',
      name: 'Cate $i',
      children: {
        SelectTextEntry<dynamic>.name(id: 'o${i}_0', name: 'O $i-0'),
        SelectTextEntry<dynamic>.name(id: 'o${i}_1', name: 'O $i-1'),
      },
    ),
};

/// Eight tall sections: the right column scrolls well beyond the viewport.
final Set<SelectEntry> _longCategories = {
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

/// Hosts the select inside an outer scroll view that can actually scroll
/// (trailing 600px spacer), mimicking a page-level [SingleChildScrollView].
Widget _harness(ScrollController outer, Set<SelectEntry> entries,
    {double maxHeightFactor = 0.5}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        controller: outer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            SelectView(
              maxHeightFactor: maxHeightFactor,
              delegate: SideNavSelectDelegate(
                selectionMode: SelectionMode.multiple,
                entries: entries,
              ),
              onChanged: (_) {},
            ),
            const SizedBox(height: 600),
          ],
        ),
      ),
    ),
  );
}

/// The right column's scrollable is the last one in tree order (the sidebar's
/// SingleChildScrollView comes first when it is scrollable).
ScrollableState _innerScrollable(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).last);

Future<void> _wheelDown(WidgetTester tester, Offset position,
    {int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await tester.sendEventToBinding(PointerScrollEvent(
      position: position,
      scrollDelta: const Offset(0, 120),
    ));
    await tester.pump();
  }
}

void main() {
  testWidgets(
      'wheel over a scrollable right column scrolls it, not the outer view',
      (tester) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await tester
        .pumpWidget(_harness(outer, _longCategories, maxHeightFactor: 1));
    await tester.pumpAndSettle();

    await _wheelDown(tester, const Offset(400, 300), times: 5);
    await tester.pumpAndSettle();

    expect(_innerScrollable(tester).position.pixels, greaterThan(0),
        reason: 'the inner column can scroll, so it must win the event');
    expect(outer.offset, 0.0,
        reason: 'the outer view must not move while the inner column scrolls');
  });

  testWidgets(
      'wheel past the right column bottom edge chains to the outer view',
      (tester) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await tester
        .pumpWidget(_harness(outer, _longCategories, maxHeightFactor: 1));
    await tester.pumpAndSettle();

    final position = _innerScrollable(tester).position;
    // Wheel far past the inner bottom edge: the surplus must chain to the
    // outer view.
    await _wheelDown(tester, const Offset(400, 300), times: 200);
    await tester.pumpAndSettle();

    expect(position.pixels, position.maxScrollExtent);
    expect(outer.offset, greaterThan(0.0),
        reason: 'once the inner column cannot scroll, the outer view takes '
            'over');
  });

  testWidgets(
      'tapping a sidebar tile scrolls only the right column, never the outer view',
      (tester) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await tester
        .pumpWidget(_harness(outer, _longCategories, maxHeightFactor: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SelectListTile).at(5));
    await tester.pumpAndSettle();
    // Let the 100ms highlight-guard timer after the animation fire.
    await tester.pump(const Duration(milliseconds: 150));

    expect(_innerScrollable(tester).position.pixels, greaterThan(0),
        reason: 'the tap must still scroll the right column to the section');
    expect(outer.offset, 0.0,
        reason: 'tapping a category must never scroll the page-level view');
  });

  testWidgets(
      'touch drag past the right column bottom edge chains to the outer view',
      (tester) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await tester
        .pumpWidget(_harness(outer, _longCategories, maxHeightFactor: 1));
    await tester.pumpAndSettle();

    final position = _innerScrollable(tester).position;
    final gesture = await tester.startGesture(const Offset(400, 300));
    // The first small step only wins the gesture arena for the column
    // (with DragStartBehavior.start the accepting event itself applies no
    // delta); the long step after it scrolls: the column consumes up to its
    // maxScrollExtent and the leftover must chain to the outer page view.
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -1470));
    await tester.pump();

    expect(position.pixels, position.maxScrollExtent);
    expect(outer.offset, greaterThan(0.0),
        reason: 'once the inner column cannot scroll, the drag must keep '
            'scrolling the outer view');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('dragging back after chaining unwinds the outer view first',
      (tester) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await tester
        .pumpWidget(_harness(outer, _longCategories, maxHeightFactor: 1));
    await tester.pumpAndSettle();

    final position = _innerScrollable(tester).position;
    final gesture = await tester.startGesture(const Offset(400, 300));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -1470));
    await tester.pump();
    final chained = outer.offset;
    expect(chained, greaterThan(60.0),
        reason: 'precondition: the drag chained a usable offset to the outer '
            'view');

    // Drag back down by 60px: that must unwind the chained outer offset
    // before the right column leaves its bottom edge.
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();

    expect(outer.offset, closeTo(chained - 60, 2.0),
        reason: 'the reverse drag unwinds the outer view first');
    expect(position.pixels, position.maxScrollExtent,
        reason: 'the right column must stay pinned at its bottom edge while '
            'the outer view unwinds');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'a fling released at the inner edge hands its momentum to the outer view',
      (tester) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await tester
        .pumpWidget(_harness(outer, _longCategories, maxHeightFactor: 1));
    await tester.pumpAndSettle();

    // Slowly reach the bottom edge: the first small step wins the arena
    // (applying no delta of its own), the second scrolls the column to its
    // end and beyond, chaining the surplus to the outer view. The untimed
    // steps produce no momentum of their own.
    final warmup = await tester.startGesture(const Offset(400, 300));
    await warmup.moveBy(const Offset(0, -30));
    await warmup.moveBy(const Offset(0, -1170));
    await warmup.up();
    await tester.pumpAndSettle();
    final chained = outer.offset;
    expect(chained, greaterThan(0.0),
        reason: 'precondition: the drag chained an offset to the outer view');
    expect(_innerScrollable(tester).position.pixels,
        _innerScrollable(tester).position.maxScrollExtent,
        reason: 'precondition: the column rests at its bottom edge');

    // A fast, short fling on the pinned column: the stroke itself chains to
    // the outer view, and the released momentum must keep scrolling it.
    await tester.fling(
        find.byType(Scrollable).last, const Offset(0, -50), 1000.0);
    await tester.pumpAndSettle();

    expect(outer.offset, greaterThan(chained),
        reason: 'the fling momentum must transfer to the outer view');
  });

  testWidgets(
      'wheel over a right column that cannot scroll chains to the outer view',
      (tester) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await tester.pumpWidget(_harness(outer, _shortCategories));
    await tester.pumpAndSettle();

    expect(outer.position.maxScrollExtent, greaterThan(0),
        reason: 'the outer view must be scrollable for this test to prove '
            'chaining');

    await _wheelDown(tester, const Offset(400, 150), times: 5);
    await tester.pumpAndSettle();

    expect(_innerScrollable(tester).position.pixels, 0.0);
    expect(outer.offset, greaterThan(0.0),
        reason: 'the inner column has nothing to scroll, so the outer view '
            'must scroll instead');
  });
}
