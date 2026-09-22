import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/select_panel.dart';
import 'package:fl_select/src/select/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [SelectView] backed by an [ExpandableSelectDelegate] so we can
/// assert how [ExpandableSelect] renders each category's `header`/`footer`
/// entries.
Widget _expandableHarness(
  Set<SelectEntry> entries, {
  SelectionMode selectionMode = SelectionMode.multiple,
  void Function(Set<SelectEntry>)? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(
        delegate: ExpandableSelectDelegate(
          selectionMode: selectionMode,
          entriesLoader: () async => entries,
        ),
        onChanged: onChanged ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('ExpandableSelect scroll chaining', () {
    /// Six expandable categories with twelve items each: far taller than the
    /// panel cap, so the body's scroll view scrolls well beyond the viewport.
    Set<SelectEntry> longCategories() => {
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
    Set<SelectEntry> shortCategories() => {
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
    Widget scrollHarness(ScrollController outer, Set<SelectEntry> entries) {
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
    Finder bodyScrollableFinder() => find
        .ancestor(
          of: find.byType(SelectExpansionTile).first,
          matching: find.byType(Scrollable),
        )
        .first;

    /// Drags up in small steps until the body rests at its bottom edge, then
    /// lets the caller continue the gesture (the returned gesture is still
    /// down). Small steps keep the drag recognizer fed with move events.
    Future<TestGesture> dragToBottom(
      WidgetTester tester,
      Offset position,
      ScrollPosition inner,
    ) async {
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

    testWidgets(
      'touch drag past the body bottom edge chains to the outer view',
      (tester) async {
        final outer = ScrollController();
        addTearDown(outer.dispose);
        await tester.pumpWidget(scrollHarness(outer, longCategories()));
        await tester.pumpAndSettle();

        final inner = tester
            .state<ScrollableState>(bodyScrollableFinder())
            .position;
        final gesture = await dragToBottom(
          tester,
          const Offset(400, 300),
          inner,
        );
        expect(
          inner.pixels,
          inner.maxScrollExtent,
          reason: 'precondition: the drag reached the body bottom edge',
        );

        // The reported defect: once the body rests at its edge, further
        // dragging must keep scrolling the page-level view instead of sticking.
        final before = outer.offset;
        await gesture.moveBy(const Offset(0, -150));
        await tester.pump();

        expect(
          inner.pixels,
          inner.maxScrollExtent,
          reason: 'the body must stay pinned at its bottom edge',
        );
        expect(
          outer.offset,
          greaterThan(before),
          reason: 'the leftover drag must keep scrolling the outer view',
        );
        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('dragging back scrolls the body first (inner-first chaining)', (
      tester,
    ) async {
      final outer = ScrollController();
      addTearDown(outer.dispose);
      await tester.pumpWidget(scrollHarness(outer, longCategories()));
      await tester.pumpAndSettle();

      final inner = tester
          .state<ScrollableState>(bodyScrollableFinder())
          .position;
      final gesture = await dragToBottom(tester, const Offset(400, 300), inner);
      // Chain a bit more so the outer view carries a chained offset.
      await gesture.moveBy(const Offset(0, -200));
      await tester.pump();
      final chained = outer.offset;
      expect(
        chained,
        greaterThan(60.0),
        reason:
            'precondition: the drag chained a usable offset to the '
            'outer view',
      );

      // Drag back down by 60px: the body consumes the drag itself first —
      // inner-first, like NestedScrollView and browsers — while the outer
      // view keeps its chained offset.
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();

      expect(
        outer.offset,
        chained,
        reason:
            'the reverse drag must not move the outer view while the '
            'body still has room to scroll',
      );
      expect(
        inner.pixels,
        closeTo(inner.maxScrollExtent - 60, 2.0),
        reason: 'the body scrolls itself first when dragging back',
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'a fling released at the body bottom edge hands its momentum to the '
      'outer view',
      (tester) async {
        final outer = ScrollController();
        addTearDown(outer.dispose);
        await tester.pumpWidget(scrollHarness(outer, longCategories()));
        await tester.pumpAndSettle();

        final inner = tester
            .state<ScrollableState>(bodyScrollableFinder())
            .position;
        final warmup = await dragToBottom(
          tester,
          const Offset(400, 300),
          inner,
        );
        await warmup.up();
        await tester.pumpAndSettle();
        final chained = outer.offset;
        expect(
          chained,
          greaterThan(0.0),
          reason: 'precondition: the drag chained an offset to the outer view',
        );
        expect(
          inner.pixels,
          inner.maxScrollExtent,
          reason: 'precondition: the body rests at its bottom edge',
        );

        // A fast, short fling on the pinned body: the stroke itself chains to
        // the outer view, and the released momentum must keep scrolling it.
        await tester.fling(
          bodyScrollableFinder(),
          const Offset(0, -50),
          1000.0,
        );
        await tester.pumpAndSettle();

        expect(
          outer.offset,
          greaterThan(chained),
          reason: 'the fling momentum must transfer to the outer view',
        );
      },
    );

    testWidgets(
      'touch drag on a body that cannot scroll scrolls the outer view',
      (tester) async {
        final outer = ScrollController();
        addTearDown(outer.dispose);
        await tester.pumpWidget(scrollHarness(outer, shortCategories()));
        await tester.pumpAndSettle();

        final inner = tester
            .state<ScrollableState>(bodyScrollableFinder())
            .position;
        final gesture = await tester.startGesture(const Offset(400, 300));
        await gesture.moveBy(const Offset(0, -30));
        await gesture.moveBy(const Offset(0, -200));
        await tester.pump();

        expect(inner.pixels, 0.0, reason: 'the body has nothing to scroll');
        expect(
          outer.offset,
          greaterThan(0.0),
          reason: 'the outer view must scroll directly',
        );
        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });

  // Regression coverage for the list-tile flavor rendered per selection mode:
  // a category without an explicit `selectionMode` must inherit the
  // delegate-level mode (multiple -> [SelectCheckboxListTile]), while a
  // category-level `SelectionMode.single` override keeps
  // [SelectRadioListTile]. The same applies to the flat [ListSelectDelegate].
  group('ExpandableSelect list tile modes', () {
    Widget listTileHarness(SelectDelegate delegate) {
      return MaterialApp(
        home: Scaffold(
          body: SelectView(delegate: delegate, onChanged: (_) {}),
        ),
      );
    }

    testWidgets(
      'category without an explicit selectionMode inherits the delegate '
      'multiple mode and renders checkbox tiles',
      (tester) async {
        await tester.pumpWidget(
          listTileHarness(
            ExpandableSelectDelegate(
              defaultLayout: const SelectListLayout(),
              selectionMode: SelectionMode.multiple,
              entries: {
                SelectCategoryEntry<dynamic>.children(
                  id: 'inherit',
                  name: 'Inherit',
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

        expect(find.byType(SelectCheckboxListTile), findsNWidgets(2));
        expect(find.byType(SelectRadioListTile), findsNothing);
      },
    );

    testWidgets(
      'category-level single override renders radio tiles even when the '
      'delegate mode is multiple',
      (tester) async {
        await tester.pumpWidget(
          listTileHarness(
            ExpandableSelectDelegate(
              defaultLayout: const SelectListLayout(),
              selectionMode: SelectionMode.multiple,
              entries: {
                SelectCategoryEntry<dynamic>.children(
                  id: 'single',
                  name: 'Single',
                  selectionMode: SelectionMode.single,
                  children: {
                    SelectTextEntry<dynamic>.name(id: 'a', name: 'Item A'),
                  },
                ),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SelectRadioListTile), findsOneWidget);
        expect(find.byType(SelectCheckboxListTile), findsNothing);
      },
    );

    testWidgets('ListSelectDelegate multiple mode renders checkbox tiles', (
      tester,
    ) async {
      await tester.pumpWidget(
        listTileHarness(
          ListSelectDelegate(
            selectionMode: SelectionMode.multiple,
            entries: {
              SelectTextEntry<dynamic>.name(id: 'a', name: 'Item A'),
              SelectTextEntry<dynamic>.name(id: 'b', name: 'Item B'),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectCheckboxListTile), findsNWidgets(2));
      expect(find.byType(SelectRadioListTile), findsNothing);
    });

    testWidgets('ListSelectDelegate single mode renders radio tiles', (
      tester,
    ) async {
      await tester.pumpWidget(
        listTileHarness(
          ListSelectDelegate(
            selectionMode: SelectionMode.single,
            entries: {SelectTextEntry<dynamic>.name(id: 'a', name: 'Item A')},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectRadioListTile), findsOneWidget);
      expect(find.byType(SelectCheckboxListTile), findsNothing);
    });
  });

  // Builds a [SelectView] backed by an [ExpandableSelectDelegate] with several
  // categories, each owning its own custom range entry. All custom entries
  // share the id `custom` and the whole level-1 selection set is handed to
  // every category view, so this exercises the per-category scoping that
  // prevents a value committed in one category from leaking into another
  // category's input.
  group('ExpandableSelect custom range isolation', () {
    Widget customRangeHarness() {
      return MaterialApp(
        home: Scaffold(
          body: SelectView(
            delegate: ExpandableSelectDelegate(
              selectionMode: SelectionMode.single,
              entriesLoader: () async => {
                SelectCategoryEntry.children(
                  id: 'cate1',
                  name: 'Cate 1',
                  children: {
                    SelectRangeEntry.custom(),
                    SelectTextEntry.name(id: 'a', name: 'A'),
                  },
                ),
                SelectCategoryEntry.children(
                  id: 'cate3',
                  name: 'Cate 3',
                  children: {
                    SelectTextEntry.name(id: 'a', name: 'A'),
                    SelectRangeEntry.custom(),
                  },
                ),
                SelectCategoryEntry.children(
                  id: 'cate4',
                  name: 'Cate 4',
                  children: {
                    SelectRangeEntry(
                      id: 'a',
                      name: r'$0-$2000000',
                      min: 0,
                      max: 2000000,
                      divisions: 80,
                    ),
                    SelectRangeEntry.custom(),
                  },
                ),
              },
            ),
            onChanged: (_) {},
          ),
        ),
      );
    }

    testWidgets(
      'committing cate1 custom range does not pollute other categories',
      (tester) async {
        await tester.pumpWidget(customRangeHarness());
        await tester.pumpAndSettle();

        // All three categories are rendered as expanded tiles in ExpandableSelect.
        expect(find.text('Cate 1'), findsOneWidget);
        expect(find.text('Cate 3'), findsOneWidget);
        expect(find.text('Cate 4'), findsOneWidget);
        // Three custom input fields (one per category).
        expect(find.byType(SelectFieldTile), findsNWidgets(3));

        // cate1's custom is at the header, so its tile is the first
        // [SelectFieldTile]. Commit a value into cate1's fields.
        final cate1Tile = find.byType(SelectFieldTile).first;
        await tester.enterText(
          find
              .descendant(of: cate1Tile, matching: find.byType(TextField))
              .first,
          '100',
        );
        await tester.enterText(
          find
              .descendant(of: cate1Tile, matching: find.byType(TextField))
              .at(1),
          '200',
        );
        // Unfocus so _onFocusChanged commits.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        // cate1's own min value must be preserved after committing both fields
        // (typing min first then max must not clear the min field).
        final cate1Fields = tester
            .widgetList<TextField>(
              find.descendant(of: cate1Tile, matching: find.byType(TextField)),
            )
            .map((t) => t.controller?.text)
            .toList();
        expect(cate1Fields[0], '100');
        expect(cate1Fields[1], '200');

        // cate3 and cate4's fields (the other tiles) must NOT be polluted with
        // cate1's committed values.
        final otherFields = tester
            .widgetList<TextField>(find.byType(TextField))
            .map((t) => t.controller?.text)
            .toList();
        expect(otherFields[2], isEmpty);
        expect(otherFields[3], isEmpty);
        expect(otherFields[4], isEmpty);
        expect(otherFields[5], isEmpty);
      },
    );

    testWidgets('typing max does not swap during editing; swap only on commit', (
      tester,
    ) async {
      await tester.pumpWidget(customRangeHarness());
      await tester.pumpAndSettle();

      final cate1Tile = find.byType(SelectFieldTile).first;
      List<String?> cate1Fields() => tester
          .widgetList<TextField>(
            find.descendant(of: cate1Tile, matching: find.byType(TextField)),
          )
          .map((t) => t.controller?.text)
          .toList();

      // Type min = 222.
      await tester.enterText(
        find.descendant(of: cate1Tile, matching: find.byType(TextField)).first,
        '222',
      );
      await tester.pump();
      expect(cate1Fields()[0], '222');

      // Type a single digit into the max field. This must NOT immediately swap
      // the fields (previously it flipped min to '1' and max to '222').
      await tester.enterText(
        find.descendant(of: cate1Tile, matching: find.byType(TextField)).at(1),
        '1',
      );
      await tester.pump();
      expect(cate1Fields()[0], '222');
      expect(cate1Fields()[1], '1');

      // Finish typing max = 111.
      await tester.enterText(
        find.descendant(of: cate1Tile, matching: find.byType(TextField)).at(1),
        '111',
      );
      await tester.pump();
      expect(cate1Fields()[0], '222');
      expect(cate1Fields()[1], '111');

      // On commit (unfocus), the inverted range is normalized to min 111 / max 222.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(cate1Fields()[0], '111');
      expect(cate1Fields()[1], '222');
    });
  });

  // Regression test for cross-category clearing with single-valued layouts.
  //
  // When `delegate.selectionMode` is single, committing a custom range in a
  // [SelectRangeLayout] category and then selecting a leaf in another category
  // must deselect the custom entry and reset the range view (slider back to
  // the full bounds, input fields cleared). This exercises the snapshot
  // semantics of the per-level selected-entries set handed to leaf views: the
  // old/new `didUpdateWidget` diff must observe the deselection transition
  // instead of aliasing one live mutated set.
  group('ExpandableSelect cross-category custom range reset', () {
    Widget crossCategoryHarness(List<SelectEntries> changes) {
      return MaterialApp(
        home: Scaffold(
          body: SelectView(
            delegate: ExpandableSelectDelegate(
              entries: {
                SelectCategoryEntry.children(
                  id: 'cate2',
                  name: 'Cate 2',
                  children: {
                    SelectTextEntry.name(id: 'a', name: 'Tiger'),
                    SelectTextEntry.name(id: 'b', name: 'Lion'),
                  },
                  selectionMode: SelectionMode.multiple,
                  layout: const SelectWrapLayout(),
                ),
                SelectCategoryEntry.children(
                  id: 'cate5',
                  name: 'Cate 5',
                  children: {
                    SelectRangeEntry(
                      id: 'a',
                      name: r'$0-$2000000',
                      min: 0,
                      max: 2000000,
                      divisions: 80,
                    ),
                    SelectRangeEntry.custom(),
                  },
                  layout: const SelectRangeLayout(),
                ),
                SelectCategoryEntry.children(
                  id: 'cate6',
                  name: 'Cate 6',
                  children: {
                    SelectTextEntry.name(id: 'a', name: '1'),
                    SelectTextEntry.name(id: 'b', name: '2'),
                  },
                  layout: const SelectCounterLayout(),
                ),
              },
            ),
            onChanged: changes.add,
          ),
        ),
      );
    }

    testWidgets('selecting in another category resets a committed custom range '
        '(delegate single mode)', (tester) async {
      final changes = <SelectEntries>[];
      await tester.pumpWidget(crossCategoryHarness(changes));
      await tester.pumpAndSettle();

      // Only cate5 renders a field tile / range slider.
      final fieldTile = find.byType(SelectFieldTile);
      expect(fieldTile, findsOneWidget);
      expect(find.byType(SelectRangeSlider), findsOneWidget);

      // Commit a custom range in cate5: type 500000 / 1000000 and unfocus.
      await tester.enterText(
        find.descendant(of: fieldTile, matching: find.byType(TextField)).first,
        '500000',
      );
      await tester.enterText(
        find.descendant(of: fieldTile, matching: find.byType(TextField)).at(1),
        '1000000',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // The custom entry is now selected and the slider reflects the commit.
      final slider = tester.widget<SelectRangeSlider>(
        find.byType(SelectRangeSlider),
      );
      expect(slider.values, const RangeValues(500000, 1000000));

      // Tap a chip in cate2 (a multiple category) — cross-category clearing.
      await tester.tap(find.text('Tiger'));
      await tester.pumpAndSettle();

      // The custom range is deselected: the slider is back to the full bounds
      // and the input fields are cleared.
      final sliderAfter = tester.widget<SelectRangeSlider>(
        find.byType(SelectRangeSlider),
      );
      expect(sliderAfter.values, const RangeValues(0, 2000000));
      final fields = tester
          .widgetList<TextField>(
            find.descendant(of: fieldTile, matching: find.byType(TextField)),
          )
          .map((t) => t.controller?.text)
          .toList();
      expect(fields[0], isEmpty);
      expect(fields[1], isEmpty);

      // The emitted selection no longer carries cate5's custom entry.
      final last = changes.last;
      final emittedCustom = last.whereType<SelectRangeEntry>().where(
        (e) => e.isCustom && e.min != null,
      );
      expect(emittedCustom, isEmpty);
    });
  });

  group('ExpandableSelect tile badge', () {
    Set<SelectEntry<dynamic>> badgeCategoryEntries() => {
      SelectCategoryEntry<dynamic>.children(
        id: 'cate1',
        name: 'Cate 1',
        children: {
          SelectTextEntry<dynamic>.name(id: 'a1', name: 'A 1'),
          SelectTextEntry<dynamic>.name(id: 'a2', name: 'A 2'),
        },
      ),
      SelectCategoryEntry<dynamic>.children(
        id: 'cate2',
        name: 'Cate 2',
        children: {SelectTextEntry<dynamic>.name(id: 'b1', name: 'B 1')},
      ),
    };

    /// Same as [badgeCategoryEntries], but the first category starts with an
    /// "Any" placeholder child, which must never badge its tile on its own.
    Set<SelectEntry<dynamic>> badgeCategoryEntriesWithAny() => {
      SelectCategoryEntry<dynamic>.children(
        id: 'cate1',
        name: 'Cate 1',
        children: {
          SelectTextEntry<dynamic>.any(parentId: 'cate1', name: 'Any'),
          SelectTextEntry<dynamic>.name(id: 'a1', name: 'A 1'),
        },
      ),
      SelectCategoryEntry<dynamic>.children(
        id: 'cate2',
        name: 'Cate 2',
        children: {SelectTextEntry<dynamic>.name(id: 'b1', name: 'B 1')},
      ),
    };

    Widget badgeHarness(
      SelectController controller, {
      Set<SelectEntry<dynamic>>? entries,
    }) => MaterialApp(
      home: Scaffold(
        // SelectPanel without a SelectActionBarVisibility scope keeps the
        // action bar visible (SelectView hides it for inline usage).
        body: SelectPanel(
          delegate: ExpandableSelectDelegate(
            selectionMode: SelectionMode.multiple,
            entries: entries ?? badgeCategoryEntries(),
          ),
          controller: controller,
        ),
      ),
    );

    testWidgets('a tile is badged while its category holds a real selection', (
      tester,
    ) async {
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(badgeHarness(controller));
      await tester.pumpAndSettle();

      // Nothing is selected yet, so no tile carries a badge.
      expect(find.byType(SelectBadge), findsNothing);

      await tester.tap(find.text('A 1'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectBadge), findsOneWidget);

      await tester.tap(find.text('B 1'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectBadge), findsNWidgets(2));
    });

    testWidgets('a collapsed tile keeps its badge', (tester) async {
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(badgeHarness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A 1'));
      await tester.pumpAndSettle();

      // Collapsing hides the children...
      await tester.tap(find.text('Cate 1'));
      await tester.pumpAndSettle();
      expect(find.text('A 1'), findsNothing);

      // ...but the badge keeps the pending selection visible.
      expect(find.byType(SelectBadge), findsOneWidget);

      // Expanding again restores the children and drops nothing.
      await tester.tap(find.text('Cate 1'));
      await tester.pumpAndSettle();
      expect(find.text('A 1'), findsOneWidget);
      expect(find.byType(SelectBadge), findsOneWidget);
    });

    testWidgets('selecting only the "Any" entry does not badge its tile', (
      tester,
    ) async {
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(
        badgeHarness(controller, entries: badgeCategoryEntriesWithAny()),
      );
      await tester.pumpAndSettle();

      // "Any" is selected by default (initializeAnyIfEmpty)...
      expect(find.text('Any'), findsOneWidget);
      // ...but a placeholder selection alone must not produce a badge.
      expect(find.byType(SelectBadge), findsNothing);

      // A real child selection does.
      await tester.tap(find.text('A 1'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectBadge), findsOneWidget);
    });

    testWidgets('Reset clears every badge', (tester) async {
      final controller = SelectController(
        selectionMode: SelectionMode.multiple,
      );
      await tester.pumpWidget(badgeHarness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B 1'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectBadge), findsNWidgets(2));

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(controller.selectedEntriesAtLevel(1), isEmpty);
      expect(find.byType(SelectBadge), findsNothing);
    });
  });

  // Regression coverage for the action bar visibility on
  // [ExpandableSelectDelegate]: visibility must follow
  // [SelectController.hasMultipleMode] — the delegate-level mode OR any
  // category opting into multiple — consistent with the grid / wrap /
  // tab-nav / side-nav / cascading layouts. Previously a delegate-level
  // single with a multiple category hid the bar while taps still deferred
  // to "Apply", leaving the multi-selection impossible to apply.
  group('ExpandableSelect action bar visibility', () {
    Widget actionBarHarness(
      SelectDelegate delegate, {
      SelectCallback? onApplyTap,
    }) => MaterialApp(
      home: Scaffold(
        // SelectPanel without a SelectActionBarVisibility scope keeps the
        // action bar visible (SelectView hides it for inline usage).
        body: SelectPanel(delegate: delegate, onApplyTap: onApplyTap),
      ),
    );

    testWidgets(
      'a category opting into multiple shows the action bar even when the '
      'delegate mode is single',
      (tester) async {
        await tester.pumpWidget(
          actionBarHarness(
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
      },
    );

    testWidgets('pure single selection hides the action bar', (tester) async {
      await tester.pumpWidget(
        actionBarHarness(
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
      'tap',
      (tester) async {
        var applied = 0;
        await tester.pumpWidget(
          actionBarHarness(
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
      },
    );
  });

  group('ExpandableSelect category header/footer', () {
    SelectCategoryEntry<dynamic> categoryWithHeaderFooter() =>
        SelectCategoryEntry<dynamic>(
          id: 'c1',
          name: 'C1',
          header: SelectTextEntry<dynamic>(
            parentId: 'c1',
            id: 'header',
            name: 'Header',
            children: {
              SelectTextEntry<dynamic>(
                parentId: 'header',
                id: 'h1',
                name: 'H1',
                immediate: true,
              ),
              SelectTextEntry<dynamic>(
                parentId: 'header',
                id: 'h2',
                name: 'H2',
                immediate: true,
              ),
            },
          ),
          children: {
            SelectTextEntry<dynamic>(parentId: 'c1', id: 'any', name: 'Any'),
            SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
          },
          footer: SelectTextEntry<dynamic>(
            parentId: 'c1',
            id: 'footer',
            name: 'Footer',
            children: {
              SelectTextEntry<dynamic>(
                parentId: 'footer',
                id: 'f1',
                name: 'F1',
                immediate: true,
              ),
            },
          ),
        );

    testWidgets('renders header/footer chip bars inside the expanded tile', (
      tester,
    ) async {
      await tester.pumpWidget(_expandableHarness({categoryWithHeaderFooter()}));
      await tester.pumpAndSettle();

      // Category content (list) plus header and footer chip bars, all inside
      // the initially expanded tile.
      expect(find.byType(SelectExpansionTile), findsOneWidget);
      expect(find.byType(SelectListView), findsOneWidget);
      expect(find.byType(SelectChipBar), findsNWidgets(2));
      expect(find.byType(SelectWrapView), findsNothing);
      expect(find.text('H1'), findsOneWidget);
      expect(find.text('H2'), findsOneWidget);
      expect(find.text('F1'), findsOneWidget);

      // Vertical order: tile title -> header chips -> content -> footer chips.
      expect(
        tester.getTopLeft(find.text('C1')).dy,
        lessThan(tester.getTopLeft(find.text('H1')).dy),
      );
      expect(
        tester.getTopLeft(find.text('H1')).dy,
        lessThan(tester.getTopLeft(find.text('One')).dy),
      );
      expect(
        tester.getTopLeft(find.text('One')).dy,
        lessThan(tester.getTopLeft(find.text('F1')).dy),
      );
    });

    testWidgets('tapping header/footer children applies their selections', (
      tester,
    ) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        _expandableHarness({
          categoryWithHeaderFooter(),
        }, onChanged: applied.add),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('H1'));
      await tester.pumpAndSettle();
      expect(applied, hasLength(1));
      final root1 = applied.last.cast<SelectCategoryEntry<dynamic>>().single;
      expect(root1.header?.children?.map((e) => e.id), contains('h1'));

      await tester.tap(find.text('F1'));
      await tester.pumpAndSettle();
      expect(applied, hasLength(2));
      final root2 = applied.last.cast<SelectCategoryEntry<dynamic>>().single;
      expect(root2.header?.children?.map((e) => e.id), contains('h1'));
      expect(root2.footer?.children?.map((e) => e.id), contains('f1'));
    });

    testWidgets('collapsing the tile hides header/footer bars', (tester) async {
      await tester.pumpWidget(_expandableHarness({categoryWithHeaderFooter()}));
      await tester.pumpAndSettle();

      expect(find.text('H1'), findsOneWidget);

      // Tap the tile title to collapse; header/footer bars hide together with
      // the category content.
      await tester.tap(find.text('C1'));
      await tester.pumpAndSettle();

      expect(find.text('H1'), findsNothing);
      expect(find.text('One'), findsNothing);
      expect(find.text('F1'), findsNothing);
    });
  });
}
