import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Six expandable categories with twelve items each: far taller than the
/// panel cap, so the body's scroll view scrolls well beyond the viewport.
final Set<SelectEntry> _longCategories = {
  for (var i = 0; i < 6; i++)
    SelectCategoryEntry<dynamic>.children(
      id: 'cate$i',
      name: 'Cate $i',
      children: {
        for (var j = 0; j < 12; j++)
          SelectTextEntry<dynamic>.name(id: 'o${i}_$j', name: 'O $i-$j'),
      },
    ),
};

/// Two categories with two items each: far shorter than the panel cap, so
/// the body's scroll view has maxScrollExtent == 0.
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

/// Hosts the select inside an outer scroll view that can actually scroll
/// (trailing 600px spacer), mimicking a page-level [SingleChildScrollView].
Widget _harness(ScrollController outer, Set<SelectEntry> entries) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        controller: outer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            SelectView(
              maxHeightFactor: 1,
              delegate: ExpandableSelectDelegate(
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

/// The body's own scroll view: the nearest [Scrollable] ancestor of the
/// first expansion tile (the per-category list views are descendants of the
/// tile, never scroll inside the unbounded expansion body, and thus never
/// claim this finder).
Finder _bodyScrollableFinder() => find
    .ancestor(
      of: find.byType(SelectExpansionTile).first,
      matching: find.byType(Scrollable),
    )
    .first;

/// Drags up in small steps until the body rests at its bottom edge, then
/// lets the caller continue the gesture (the returned gesture is still
/// down). Small steps keep the drag recognizer fed with move events.
Future<TestGesture> _dragToBottom(WidgetTester tester, Offset position,
    ScrollPosition inner) async {
  final gesture = await tester.startGesture(position);
  await gesture.moveBy(const Offset(0, -30));
  await tester.pump();
  for (var i = 0; i < 40; i++) {
    if (inner.pixels >= inner.maxScrollExtent) break;
    await gesture.moveBy(const Offset(0, -200));
    await tester.pump();
  }
  return gesture;
}

void main() {
  testWidgets(
      'touch drag past the body bottom edge chains to the outer view',
      (tester) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await tester.pumpWidget(_harness(outer, _longCategories));
    await tester.pumpAndSettle();

    final inner =
        tester.state<ScrollableState>(_bodyScrollableFinder()).position;
    final gesture = await _dragToBottom(
        tester, const Offset(400, 300), inner);
    expect(inner.pixels, inner.maxScrollExtent,
        reason: 'precondition: the drag reached the body bottom edge');

    // The reported defect: once the body rests at its edge, further
    // dragging must keep scrolling the page-level view instead of sticking.
    final before = outer.offset;
    await gesture.moveBy(const Offset(0, -150));
    await tester.pump();

    expect(inner.pixels, inner.maxScrollExtent,
        reason: 'the body must stay pinned at its bottom edge');
    expect(outer.offset, greaterThan(before),
        reason: 'the leftover drag must keep scrolling the outer view');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('dragging back after chaining unwinds the outer view first',
      (tester) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await tester.pumpWidget(_harness(outer, _longCategories));
    await tester.pumpAndSettle();

    final inner =
        tester.state<ScrollableState>(_bodyScrollableFinder()).position;
    final gesture = await _dragToBottom(
        tester, const Offset(400, 300), inner);
    // Chain a bit more so the outer view carries a chained offset.
    await gesture.moveBy(const Offset(0, -200));
    await tester.pump();
    final chained = outer.offset;
    expect(chained, greaterThan(60.0),
        reason: 'precondition: the drag chained a usable offset to the '
            'outer view');

    // Drag back down by 60px: that must unwind the chained outer offset
    // before the body leaves its bottom edge.
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();

    expect(outer.offset, closeTo(chained - 60, 2.0),
        reason: 'the reverse drag unwinds the outer view first');
    expect(inner.pixels, inner.maxScrollExtent,
        reason: 'the body must stay pinned at its bottom edge while the '
            'outer view unwinds');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'a fling released at the body bottom edge hands its momentum to the '
      'outer view', (tester) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await tester.pumpWidget(_harness(outer, _longCategories));
    await tester.pumpAndSettle();

    final inner =
        tester.state<ScrollableState>(_bodyScrollableFinder()).position;
    final warmup = await _dragToBottom(
        tester, const Offset(400, 300), inner);
    await warmup.up();
    await tester.pumpAndSettle();
    final chained = outer.offset;
    expect(chained, greaterThan(0.0),
        reason: 'precondition: the drag chained an offset to the outer view');
    expect(inner.pixels, inner.maxScrollExtent,
        reason: 'precondition: the body rests at its bottom edge');

    // A fast, short fling on the pinned body: the stroke itself chains to
    // the outer view, and the released momentum must keep scrolling it.
    await tester.fling(
        _bodyScrollableFinder(), const Offset(0, -50), 1000.0);
    await tester.pumpAndSettle();

    expect(outer.offset, greaterThan(chained),
        reason: 'the fling momentum must transfer to the outer view');
  });

  testWidgets(
      'touch drag on a body that cannot scroll scrolls the outer view',
      (tester) async {
    final outer = ScrollController();
    addTearDown(outer.dispose);
    await tester.pumpWidget(_harness(outer, _shortCategories));
    await tester.pumpAndSettle();

    final inner =
        tester.state<ScrollableState>(_bodyScrollableFinder()).position;
    final gesture = await tester.startGesture(const Offset(400, 300));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -200));
    await tester.pump();

    expect(inner.pixels, 0.0,
        reason: 'the body has nothing to scroll');
    expect(outer.offset, greaterThan(0.0),
        reason: 'the outer view must scroll directly');
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
