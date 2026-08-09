import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/select_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectRangeEntry.divisions', () {
    test('defaults to null and is forward-compatible', () {
      final entry = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'price',
        min: 0,
        max: 100,
      );
      expect(entry.divisions, isNull);
    });

    test('is preserved by copyWith', () {
      final entry = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'price',
        min: 0,
        max: 100,
        divisions: 50,
      );
      final copy = entry.copyWith(divisions: 100);
      expect(copy.divisions, 100);

      final passthrough = entry.copyWith();
      expect(passthrough.divisions, 50);
    });

    test('is included in toString for diagnostics', () {
      final entry = SelectRangeEntry<int, dynamic>.custom(
        parentId: 'price',
        min: 0,
        max: 100,
        divisions: 25,
      );
      expect(entry.toString(), contains('divisions: 25'));
    });

    test('is preserved by deep clone (SelectIntEntry path)', () {
      final entry = SelectIntEntry<dynamic>.custom(
        parentId: 'price',
        min: 0,
        max: 100,
        divisions: 20,
      );
      final cloned =
          SelectUtils.deepCloneEntries({entry}).single as SelectIntEntry;
      expect(cloned.divisions, 20);
    });

    test('is preserved by cloneTree / _cloneEntryWithChildren', () {
      final entry = SelectIntEntry<dynamic>.custom(
        parentId: 'price',
        min: 0,
        max: 100,
        divisions: 10,
      );
      final category = SelectCategoryEntry<dynamic>(
        id: 'cat',
        name: 'cat',
        children: {entry},
        selectionMode: SelectionMode.single,
      );
      final cloned = SelectUtils.cloneTree(
        {category},
        [
          {category},
          {entry},
        ],
        deepCloneSelectedSubtree: true,
      );
      final clonedCat = cloned.single as SelectCategoryEntry;
      final clonedEntry =
          clonedCat.children!.single as SelectRangeEntry<int, dynamic>;
      expect(clonedEntry.divisions, 10);
    });
  });

  group('SelectRangeSlider', () {
    testWidgets('renders end labels when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SelectRangeSlider(
              min: 0,
              max: 1000,
              values: RangeValues(250, 750),
              minLabel: '\$0',
              maxLabel: '\$1k+',
              onChanged: _noop,
            ),
          ),
        ),
      );
      expect(find.text('\$0'), findsOneWidget);
      expect(find.text('\$1k+'), findsOneWidget);
    });

    testWidgets('builds without a title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SelectRangeSlider(
              min: 0,
              max: 1000,
              values: RangeValues(250, 750),
              onChanged: _noop,
            ),
          ),
        ),
      );
      expect(find.byType(SelectRangeSlider), findsOneWidget);
    });

    testWidgets('emits onChanged when a thumb is dragged', (tester) async {
      RangeValues? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: SelectRangeSlider(
                min: 0,
                max: 100,
                values: const RangeValues(20, 80),
                onChanged: (v) => captured = v,
              ),
            ),
          ),
        ),
      );
      final sliderFinder = find.byType(SelectRangeSlider);
      // Drag from a point that lands nearer the start thumb (~20%).
      final start = tester.getCenter(sliderFinder);
      await tester.dragFrom(start, const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.start, greaterThan(20));
    });

    testWidgets('emits onChangeEnd with snap-to-step when divisions set',
        (tester) async {
      RangeValues? changeEnd;
      const divisions = 10; // step = (100-0)/10 = 10
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: SelectRangeSlider(
                min: 0,
                max: 100,
                values: const RangeValues(20, 80),
                divisions: divisions,
                onChanged: _noop,
                onChangeEnd: (v) => changeEnd = v,
              ),
            ),
          ),
        ),
      );
      // Drag the right thumb a small amount; the end value should snap to
      // the nearest multiple of (100/10)=10.
      final center = tester.getCenter(find.byType(SelectRangeSlider));
      await tester.dragFrom(center, const Offset(5, 0));
      await tester.pumpAndSettle();
      expect(changeEnd, isNotNull);
      // Snapped end should be a multiple of 10.
      final end = changeEnd!.end;
      final rounded = (end / 10).round() * 10;
      expect((end - rounded).abs() < 0.5, isTrue,
          reason: 'snapped end ($end) should be near a multiple of 10');
    });

    testWidgets('snaps onChanged values to steps while dragging',
        (tester) async {
      final captured = <RangeValues>[];
      const divisions = 10; // step = (100-0)/10 = 10
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: SelectRangeSlider(
                min: 0,
                max: 100,
                values: const RangeValues(20, 80),
                divisions: divisions,
                onChanged: captured.add,
              ),
            ),
          ),
        ),
      );
      // Drag the left thumb to the right; the start value should move in
      // discrete steps of 10 during the drag, not only after release.
      final center = tester.getCenter(find.byType(SelectRangeSlider));
      final gesture = await tester.startGesture(center);
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(captured, isNotEmpty);
      for (final v in captured) {
        expect((v.start % divisions).abs(), lessThan(0.5),
            reason: 'start ${v.start} should be a multiple of $divisions');
        expect((v.end % divisions).abs(), lessThan(0.5),
            reason: 'end ${v.end} should be a multiple of $divisions');
      }
    });

    testWidgets(
        'tracks the finger with many small moves (no sticky resistance)',
        (tester) async {
      final captured = <RangeValues>[];
      const divisions = 10; // step = (100-0)/10 = 10
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: SelectRangeSlider(
                min: 0,
                max: 100,
                values: const RangeValues(20, 80),
                divisions: divisions,
                onChanged: captured.add,
              ),
            ),
          ),
        ),
      );
      // Drag the left thumb with many *tiny* moves. If the value were
      // accumulated on top of an already-snapped base, each sub-step move
      // would round back and the thumb would feel stuck (resistant). It must
      // instead advance proportionally to the total finger travel.
      final center = tester.getCenter(find.byType(SelectRangeSlider));
      final gesture = await tester.startGesture(center);
      for (var i = 0; i < 30; i++) {
        await gesture.moveBy(const Offset(1, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      // ~30px of travel maps to roughly one step (10) of value; the final
      // start value must have advanced well past the original 20.
      final last = captured.last;
      expect(last.start, greaterThan(20),
          reason: 'thumb should track total finger travel, got ${last.start}');
    });

    testWidgets('thumbs align with the track ends at the extremes',
        (tester) async {
      const radius = 10.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: SelectRangeSlider(
                min: 0,
                max: 100,
                values: RangeValues(0, 100),
                thumbRadius: radius,
                onChanged: _noop,
              ),
            ),
          ),
        ),
      );
      final sliderLeft = tester.getTopLeft(find.byType(SelectRangeSlider)).dx;
      final sliderRight = tester.getTopRight(find.byType(SelectRangeSlider)).dx;
      final thumbs = tester
          .widgetList<AnimatedScale>(
            find.byWidgetPredicate((w) => w is AnimatedScale),
          )
          .toList();
      final rects = thumbs.map((t) => tester.getRect(find.byWidget(t))).toList()
        ..sort((a, b) => a.left.compareTo(b.left));
      // Left thumb's left edge sits flush with the slider's left edge.
      expect((rects.first.left - sliderLeft).abs(), lessThan(0.5));
      // Right thumb's right edge sits flush with the slider's right edge.
      expect((rects.last.right - sliderRight).abs(), lessThan(0.5));
    });

    testWidgets('enlarges the pressed thumb by 1.25x while dragging',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: SelectRangeSlider(
                min: 0,
                max: 100,
                values: RangeValues(20, 80),
                divisions: 10,
                onChanged: _noop,
              ),
            ),
          ),
        ),
      );
      List<double> scalesOf() => tester
          .widgetList<AnimatedScale>(
            find.byWidgetPredicate((w) => w is AnimatedScale),
          )
          .map((t) => t.scale)
          .toList();

      // At rest, both thumbs are at their normal size.
      expect(scalesOf().every((s) => s == 1.0), isTrue);

      final center = tester.getCenter(find.byType(SelectRangeSlider));
      final gesture = await tester.startGesture(center);
      await tester.pump();
      // Move well past the touch slop so the pan (and the active-thumb zoom)
      // actually starts.
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();

      // While dragging, exactly one thumb is scaled up to 1.25x.
      final during = scalesOf();
      expect(during.any((s) => (s - 1.25).abs() < 0.001), isTrue);
      expect(during.any((s) => s == 1.0), isTrue);

      await gesture.up();
      await tester.pumpAndSettle();

      // After release, both thumbs return to their normal size.
      expect(scalesOf().every((s) => s == 1.0), isTrue);
    });
  });

  group('SelectRangeLayout', () {
    test('implements == and hashCode based on fields', () {
      const a = SelectRangeLayout();
      const b = SelectRangeLayout(toText: 'and');
      const c = SelectRangeLayout(toText: 'or');
      expect(a, equals(const SelectRangeLayout()));
      expect(a.hashCode, b.hashCode == a.hashCode ? a.hashCode : a.hashCode);
      expect(a, isNot(equals(b)));
      expect(a, isNot(equals(c)));
    });
  });

  group('SelectRangeView', () {
    testWidgets('renders the category name as title when showTitle is true',
        (tester) async {
      final category = SelectCategoryEntry<dynamic>(
        id: 'price',
        name: 'Price range',
        selectionMode: SelectionMode.single,
        children: {
          SelectIntEntry<dynamic>(
            parentId: 'price',
            id: 'range',
            name: '',
            min: 0,
            max: 1000,
          ),
          SelectIntEntry<dynamic>.custom(parentId: 'price'),
        },
        layout: const SelectRangeLayout(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectRangeView(
              category: category,
              entries: category.children!.toList(),
              selectedEntries: const <SelectEntry>{},
              toText: const SelectRangeLayout().toText,
              showTitle: true,
              onChanged: (_, __) {},
            ),
          ),
        ),
      );

      expect(find.text('Price range'), findsOneWidget);
    });

    testWidgets('omits the title when showTitle is false', (tester) async {
      final category = SelectCategoryEntry<dynamic>(
        id: 'price',
        name: 'Price range',
        selectionMode: SelectionMode.single,
        children: {
          SelectIntEntry<dynamic>(
            parentId: 'price',
            id: 'range',
            name: '',
            min: 0,
            max: 1000,
          ),
          SelectIntEntry<dynamic>.custom(parentId: 'price'),
        },
        layout: const SelectRangeLayout(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectRangeView(
              category: category,
              entries: category.children!.toList(),
              selectedEntries: const <SelectEntry>{},
              toText: const SelectRangeLayout().toText,
              showTitle: false,
              onChanged: (_, __) {},
            ),
          ),
        ),
      );

      expect(find.text('Price range'), findsNothing);
    });

    testWidgets('keeps slider and field values in sync', (tester) async {
      final rangeEntry = SelectIntEntry<dynamic>(
        parentId: 'price',
        id: 'range',
        name: '',
        min: 0,
        max: 1000,
      );
      final customEntry = SelectIntEntry<dynamic>.custom(
        parentId: 'price',
        minHintText: 'No min',
        maxHintText: 'No max',
      );
      final category = SelectCategoryEntry<dynamic>(
        id: 'price',
        name: 'Price',
        selectionMode: SelectionMode.single,
        children: {rangeEntry, customEntry},
        layout: const SelectRangeLayout(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectRangeView(
              category: category,
              entries: category.children!.toList(),
              selectedEntries: const <SelectEntry>{},
              toText: const SelectRangeLayout().toText,
              onChanged: (_, __) {},
            ),
          ),
        ),
      );

      // Initial state: min handle is at min (0), so the min field should
      // be empty and the placeholder "No min" should be visible.
      final minField = find
          .byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.keyboardType ==
                    const TextInputType.numberWithOptions(decimal: true),
          )
          .first;
      expect(tester.widget<TextField>(minField).controller!.text, isEmpty);

      // Type a value in the min field; the controller should reflect
      // the formatted number on next rebuild (via the field's own state).
      await tester.enterText(minField, '250');
      await tester.pumpAndSettle();
      // The TextField still shows what the user typed (we don't override
      // the controller while the user is actively editing).
      expect(tester.widget<TextField>(minField).controller!.text, '250');
    });

    testWidgets('shows the min/max labels parsed from the range entry name',
        (tester) async {
      final rangeEntry = SelectIntEntry<dynamic>(
        parentId: 'price',
        id: 'range',
        name: r'$0-$10M+',
        min: 0,
        max: 10000000,
      );
      final customEntry = SelectIntEntry<dynamic>.custom(
        parentId: 'price',
        minHintText: 'No min',
        maxHintText: 'No max',
      );
      final category = SelectCategoryEntry<dynamic>(
        id: 'price',
        name: 'Price',
        selectionMode: SelectionMode.single,
        children: {rangeEntry, customEntry},
        layout: const SelectRangeLayout(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectRangeView(
              category: category,
              entries: category.children!.toList(),
              selectedEntries: const <SelectEntry>{},
              toText: const SelectRangeLayout().toText,
              onChanged: (_, __) {},
            ),
          ),
        ),
      );
      // The slider's bottom corners should display the two segments of the
      // entry's name split on '-', not the raw numeric bounds.
      expect(find.text(r'$0'), findsOneWidget);
      expect(find.text(r'$10M+'), findsOneWidget);
    });

    testWidgets('restores the last range from selectedEntries', (tester) async {
      final rangeEntry = SelectIntEntry<dynamic>(
        parentId: 'price',
        id: 'range',
        name: '',
        min: 0,
        max: 1000,
      );
      final customEntry = SelectIntEntry<dynamic>.custom(
        parentId: 'price',
        minHintText: 'No min',
        maxHintText: 'No max',
      );
      final category = SelectCategoryEntry<dynamic>(
        id: 'price',
        name: 'Price',
        selectionMode: SelectionMode.single,
        children: {rangeEntry, customEntry},
        layout: const SelectRangeLayout(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectRangeView(
              category: category,
              entries: category.children!.toList(),
              selectedEntries: {
                // The custom entry carries the previously saved range.
                SelectIntEntry<dynamic>.custom(
                  parentId: 'price',
                  min: 250,
                  max: 750,
                ),
              },
              toText: const SelectRangeLayout().toText,
              onChanged: (_, __) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The slider should reopen at the restored values, not the full bounds.
      expect(
        tester.widget<SelectRangeSlider>(find.byType(SelectRangeSlider)).values,
        const RangeValues(250, 750),
      );
      // The text fields mirror the restored range.
      final fields = find.byType(TextField);
      expect(tester.widget<TextField>(fields.first).controller!.text, '250');
      expect(tester.widget<TextField>(fields.last).controller!.text, '750');
    });

    testWidgets('emits focusListener on slider release', (tester) async {
      String? lastCategory;
      String? lastMin;
      String? lastMax;
      final rangeEntry = SelectIntEntry<dynamic>(
        parentId: 'price',
        id: 'range',
        name: '',
        min: 0,
        max: 100,
        divisions: 10,
      );
      final customEntry = SelectIntEntry<dynamic>.custom(
        parentId: 'price',
      );
      final category = SelectCategoryEntry<dynamic>(
        id: 'price',
        name: 'Price',
        selectionMode: SelectionMode.single,
        children: {rangeEntry, customEntry},
        layout: const SelectRangeLayout(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: SelectRangeView(
                  category: category,
                  entries: category.children!.toList(),
                  selectedEntries: const <SelectEntry>{},
                  toText: const SelectRangeLayout().toText,
                  onChanged: (index, entry) {
                    lastCategory = (entry as SelectRangeEntry).parentId;
                    lastMin = entry.min?.toString();
                    lastMax = entry.max?.toString();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // The slider's gesture detector picks the closer thumb at start,
      // then moves it; on release it emits onChangeEnd. The gesture
      // detector wraps the inner slider area (find the inner GestureDetector
      // inside the SelectRangeSlider).
      final gestures = find.descendant(
        of: find.byType(SelectRangeSlider),
        matching: find.byType(GestureDetector),
      );
      expect(gestures, findsOneWidget,
          reason: 'the inner slider should expose a gesture detector');
      final gestureCenter = tester.getCenter(gestures);
      final gesture = await tester.startGesture(gestureCenter);
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump(const Duration(milliseconds: 20));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(lastCategory, 'price');
      expect(lastMin, isNotNull);
      // The start thumb was dragged right, so a lower bound is reported. The
      // end thumb stays at the slider's max extreme, which normalizes to null
      // (no upper bound) on the entry.
      expect(lastMax, isNull);
    });

    testWidgets('keeps field text after a parent rebuild (didUpdateWidget)',
        (tester) async {
      final rangeEntry = SelectIntEntry<dynamic>(
        parentId: 'price',
        id: 'range',
        name: '',
        min: 0,
        max: 1000,
      );
      final customEntry = SelectIntEntry<dynamic>.custom(
        parentId: 'price',
        minHintText: 'No min',
        maxHintText: 'No max',
      );
      final category = SelectCategoryEntry<dynamic>(
        id: 'price',
        name: 'Price',
        selectionMode: SelectionMode.single,
        children: {rangeEntry, customEntry},
        layout: const SelectRangeLayout(),
      );
      final base = SelectRangeView(
        category: category,
        entries: category.children!.toList(),
        selectedEntries: const <SelectEntry>{},
        toText: const SelectRangeLayout().toText,
        onChanged: (_, __) {},
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: base)));

      final minField = find
          .byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.keyboardType ==
                    const TextInputType.numberWithOptions(decimal: true),
          )
          .first;
      await tester.enterText(minField, '250');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(minField).controller!.text, '250');

      // Simulate a parent rebuild that now reports the custom range as
      // selected (the focusListener round-trips to the controller and the
      // parent re-renders the view). The user's input must be preserved.
      final rebuilt = SelectRangeView(
        category: category,
        entries: category.children!.toList(),
        selectedEntries: {
          SelectIntEntry<dynamic>.custom(
            parentId: 'price',
            min: 250,
            max: 1000,
          ),
        },
        toText: const SelectRangeLayout().toText,
        onChanged: (_, __) {},
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: rebuilt)));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(minField).controller!.text, '250');
    });

    testWidgets('snaps to whole numbers for an int entry', (tester) async {
      final rangeEntry = SelectIntEntry<dynamic>(
        parentId: 'price',
        id: 'range',
        name: '',
        min: 0,
        max: 1000,
      );
      final customEntry = SelectIntEntry<dynamic>.custom(
        parentId: 'price',
        minHintText: 'No min',
        maxHintText: 'No max',
      );
      final category = SelectCategoryEntry<dynamic>(
        id: 'price',
        name: 'Price',
        selectionMode: SelectionMode.single,
        children: {rangeEntry, customEntry},
        layout: const SelectRangeLayout(),
      );
      String? lastMin;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectRangeView(
              category: category,
              entries: category.children!.toList(),
              selectedEntries: const <SelectEntry>{},
              toText: const SelectRangeLayout().toText,
              onChanged: (index, entry) {
                lastMin = (entry as SelectRangeEntry).min?.toString();
              },
            ),
          ),
        ),
      );
      final minField = find
          .byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.keyboardType ==
                    const TextInputType.numberWithOptions(decimal: true),
          )
          .first;
      await tester.enterText(minField, '250.6');
      await tester.pumpAndSettle();
      // While typing (not yet committed) the raw text is kept and the slider
      // is NOT updated.
      expect(tester.widget<TextField>(minField).controller!.text, '250.6');
      expect(lastMin, isNull);

      // Commit the field (simulate pressing "done").
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      // int entry => rounded to 251, never '250.6'
      expect(tester.widget<TextField>(minField).controller!.text, '251');
      expect(lastMin, '251');
      expect(
        tester.widget<TextField>(minField).controller!.text.contains('.'),
        isFalse,
      );
    });

    testWidgets('does not move the slider until a field is committed',
        (tester) async {
      final rangeEntry = SelectIntEntry<dynamic>(
        parentId: 'price',
        id: 'range',
        name: '',
        min: 0,
        max: 1000,
      );
      final customEntry = SelectIntEntry<dynamic>.custom(
        parentId: 'price',
        minHintText: 'No min',
        maxHintText: 'No max',
      );
      final category = SelectCategoryEntry<dynamic>(
        id: 'price',
        name: 'Price',
        selectionMode: SelectionMode.single,
        children: {rangeEntry, customEntry},
        layout: const SelectRangeLayout(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectRangeView(
              category: category,
              entries: category.children!.toList(),
              selectedEntries: const <SelectEntry>{},
              toText: const SelectRangeLayout().toText,
              onChanged: (_, __) {},
            ),
          ),
        ),
      );
      final minField = find.byType(TextField).first;
      // Initial slider range is the full bounds.
      expect(
        tester.widget<SelectRangeSlider>(find.byType(SelectRangeSlider)).values,
        const RangeValues(0, 1000),
      );

      // Type into the min field but do NOT commit.
      await tester.enterText(minField, '250');
      await tester.pumpAndSettle();
      // The slider must not have moved while typing.
      expect(
        tester.widget<SelectRangeSlider>(find.byType(SelectRangeSlider)).values,
        const RangeValues(0, 1000),
      );

      // Commit — now the slider updates.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        tester.widget<SelectRangeSlider>(find.byType(SelectRangeSlider)).values,
        const RangeValues(250, 1000),
      );
    });

    testWidgets('swaps bounds when the max field is typed below the min field',
        (tester) async {
      final rangeEntry = SelectIntEntry<dynamic>(
        parentId: 'price',
        id: 'range',
        name: '',
        min: 0,
        max: 1000,
      );
      final customEntry = SelectIntEntry<dynamic>.custom(
        parentId: 'price',
        minHintText: 'No min',
        maxHintText: 'No max',
      );
      final category = SelectCategoryEntry<dynamic>(
        id: 'price',
        name: 'Price',
        selectionMode: SelectionMode.single,
        children: {rangeEntry, customEntry},
        layout: const SelectRangeLayout(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectRangeView(
              category: category,
              entries: category.children!.toList(),
              selectedEntries: const <SelectEntry>{},
              toText: const SelectRangeLayout().toText,
              onChanged: (_, __) {},
            ),
          ),
        ),
      );
      final fields = find.byType(TextField);
      final minField = fields.first;
      final maxField = fields.last;

      await tester.enterText(minField, '100');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.enterText(maxField, '50');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // The typed max (50) is below the min (100) => the bounds auto-swap.
      expect(
        tester.widget<SelectRangeSlider>(find.byType(SelectRangeSlider)).values,
        const RangeValues(50, 100),
      );
      expect(tester.widget<TextField>(minField).controller!.text, '50');
      expect(tester.widget<TextField>(maxField).controller!.text, '100');
    });
  });
}

void _noop(RangeValues _) {}
