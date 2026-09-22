import 'package:fl_select/fl_select.dart';
import 'package:fl_select/src/select/widgets/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [SelectView] backed by a [SideNavSelectDelegate] so we can assert
/// how [SideNavSelect] consumes each [SelectCategoryEntry.layout].
Widget _sideNavHarness(Set<SelectEntry> entries) {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(
        delegate: SideNavSelectDelegate(entriesLoader: () async => entries),
        onChanged: (_) {},
      ),
    ),
  );
}

SelectCategoryEntry<dynamic> _category(
  String id,
  String name,
  SelectLayout? layout, {
  Set<SelectEntry> children = const {},
}) {
  return SelectCategoryEntry<dynamic>(
    id: id,
    name: name,
    layout: layout,
    children: children,
  );
}

void main() {
  group('SideNavSelect scroll chaining', () {
    /// Two categories with two chips each: far shorter than the panel cap, so
    /// the right column's ListView has maxScrollExtent == 0.
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

    /// Eight tall sections: the right column scrolls well beyond the viewport.
    Set<SelectEntry> longCategories() => {
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
    Widget scrollChainingHarness(
      ScrollController outer,
      Set<SelectEntry> entries, {
      double maxHeightFactor = 0.5,
    }) {
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

    /// The right column's scrollable is the last one in tree order (the
    /// sidebar's SingleChildScrollView comes first when it is scrollable).
    ScrollableState innerScrollable(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable).last);

    Future<void> wheelDown(
      WidgetTester tester,
      Offset position, {
      int times = 1,
    }) async {
      for (var i = 0; i < times; i++) {
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: position,
            scrollDelta: const Offset(0, 120),
          ),
        );
        await tester.pump();
      }
    }

    testWidgets(
      'wheel over a scrollable right column scrolls it, not the outer view',
      (tester) async {
        final outer = ScrollController();
        addTearDown(outer.dispose);
        await tester.pumpWidget(
          scrollChainingHarness(outer, longCategories(), maxHeightFactor: 1),
        );
        await tester.pumpAndSettle();

        await wheelDown(tester, const Offset(400, 300), times: 5);
        await tester.pumpAndSettle();

        expect(
          innerScrollable(tester).position.pixels,
          greaterThan(0),
          reason: 'the inner column can scroll, so it must win the event',
        );
        expect(
          outer.offset,
          0.0,
          reason: 'the outer view must not move while the inner column scrolls',
        );
      },
    );

    testWidgets(
      'wheel past the right column bottom edge chains to the outer view',
      (tester) async {
        final outer = ScrollController();
        addTearDown(outer.dispose);
        await tester.pumpWidget(
          scrollChainingHarness(outer, longCategories(), maxHeightFactor: 1),
        );
        await tester.pumpAndSettle();

        final position = innerScrollable(tester).position;
        // Wheel far past the inner bottom edge: the surplus must chain to the
        // outer view.
        await wheelDown(tester, const Offset(400, 300), times: 200);
        await tester.pumpAndSettle();

        expect(position.pixels, position.maxScrollExtent);
        expect(
          outer.offset,
          greaterThan(0.0),
          reason:
              'once the inner column cannot scroll, the outer view takes '
              'over',
        );
      },
    );

    testWidgets(
      'tapping a sidebar tile scrolls only the right column, never the outer view',
      (tester) async {
        final outer = ScrollController();
        addTearDown(outer.dispose);
        await tester.pumpWidget(
          scrollChainingHarness(outer, longCategories(), maxHeightFactor: 1),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(SelectListTile).at(5));
        await tester.pumpAndSettle();
        // Let the 100ms highlight-guard timer after the animation fire.
        await tester.pump(const Duration(milliseconds: 150));

        expect(
          innerScrollable(tester).position.pixels,
          greaterThan(0),
          reason: 'the tap must still scroll the right column to the section',
        );
        expect(
          outer.offset,
          0.0,
          reason: 'tapping a category must never scroll the page-level view',
        );
      },
    );

    testWidgets(
      'touch drag past the right column bottom edge chains to the outer view',
      (tester) async {
        final outer = ScrollController();
        addTearDown(outer.dispose);
        await tester.pumpWidget(
          scrollChainingHarness(outer, longCategories(), maxHeightFactor: 1),
        );
        await tester.pumpAndSettle();

        final position = innerScrollable(tester).position;
        final gesture = await tester.startGesture(const Offset(400, 300));
        // The first small step only wins the gesture arena for the column
        // (with DragStartBehavior.start the accepting event itself applies no
        // delta); the long step after it scrolls: the column consumes up to its
        // maxScrollExtent and the leftover must chain to the outer page view.
        await gesture.moveBy(const Offset(0, -30));
        await gesture.moveBy(const Offset(0, -1470));
        await tester.pump();

        expect(position.pixels, position.maxScrollExtent);
        expect(
          outer.offset,
          greaterThan(0.0),
          reason:
              'once the inner column cannot scroll, the drag must keep '
              'scrolling the outer view',
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
      await tester.pumpWidget(
        scrollChainingHarness(outer, longCategories(), maxHeightFactor: 1),
      );
      await tester.pumpAndSettle();

      final position = innerScrollable(tester).position;
      final gesture = await tester.startGesture(const Offset(400, 300));
      await gesture.moveBy(const Offset(0, -30));
      await gesture.moveBy(const Offset(0, -1470));
      await tester.pump();
      final chained = outer.offset;
      expect(
        chained,
        greaterThan(60.0),
        reason:
            'precondition: the drag chained a usable offset to the outer '
            'view',
      );

      // Drag back down by 60px: the right column consumes the drag itself
      // first — inner-first, like NestedScrollView and browsers — while the
      // outer view keeps its chained offset.
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();

      expect(
        outer.offset,
        chained,
        reason:
            'the reverse drag must not move the outer view while the '
            'column still has room to scroll',
      );
      expect(
        position.pixels,
        closeTo(position.maxScrollExtent - 60, 2.0),
        reason: 'the right column scrolls itself first when dragging back',
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'a fling released at the inner edge hands its momentum to the outer view',
      (tester) async {
        final outer = ScrollController();
        addTearDown(outer.dispose);
        await tester.pumpWidget(
          scrollChainingHarness(outer, longCategories(), maxHeightFactor: 1),
        );
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
        expect(
          chained,
          greaterThan(0.0),
          reason: 'precondition: the drag chained an offset to the outer view',
        );
        expect(
          innerScrollable(tester).position.pixels,
          innerScrollable(tester).position.maxScrollExtent,
          reason: 'precondition: the column rests at its bottom edge',
        );

        // A fast, short fling on the pinned column: the stroke itself chains to
        // the outer view, and the released momentum must keep scrolling it.
        await tester.fling(
          find.byType(Scrollable).last,
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
      'wheel over a right column that cannot scroll chains to the outer view',
      (tester) async {
        final outer = ScrollController();
        addTearDown(outer.dispose);
        await tester.pumpWidget(
          scrollChainingHarness(outer, shortCategories()),
        );
        await tester.pumpAndSettle();

        expect(
          outer.position.maxScrollExtent,
          greaterThan(0),
          reason:
              'the outer view must be scrollable for this test to prove '
              'chaining',
        );

        await wheelDown(tester, const Offset(400, 150), times: 5);
        await tester.pumpAndSettle();

        expect(innerScrollable(tester).position.pixels, 0.0);
        expect(
          outer.offset,
          greaterThan(0.0),
          reason:
              'the inner column has nothing to scroll, so the outer view '
              'must scroll instead',
        );
      },
    );
  });

  /// Reproduces the SideNavSelect click-to-scroll linkage: tapping a sidebar
  /// tile must scroll the right column to that category's section in one
  /// continuous animation. Eight tall sections (30 chips each) keep sections
  /// 1-7 far below the 600px-tall test viewport.
  group('SideNavSelect click-to-scroll', () {
    Set<SelectEntry> navCategories() => {
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

    Widget clickScrollHarness() {
      return MaterialApp(
        home: Scaffold(
          body: SelectView(
            // Full-height panel so the sidebar (8 tiles ~ 352px) is not clipped
            // by the default maxHeightFactor (0.5) cap.
            maxHeightFactor: 1,
            delegate: SideNavSelectDelegate(
              selectionMode: SelectionMode.single,
              entries: navCategories(),
            ),
            onChanged: (_) {},
          ),
        ),
      );
    }

    testWidgets(
      'tapping a sidebar tile scrolls the right column to the section',
      (tester) async {
        await tester.pumpWidget(clickScrollHarness());
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
      },
    );

    testWidgets(
      'tapping a nearby sidebar tile still scrolls (within cache extent)',
      (tester) async {
        await tester.pumpWidget(clickScrollHarness());
        await tester.pumpAndSettle();

        // Section 1 sits just below the fold; with the infinite cache extent it
        // is always inflated and the linkage works the same as for far sections.
        await tester.tap(find.byType(SelectListTile).at(1));
        await tester.pumpAndSettle();

        expect(find.text('Cate 1'), findsNWidgets(2));
        final header = tester.getRect(find.text('Cate 1').last);
        expect(header.top, closeTo(18.0, 1.0));
      },
    );

    testWidgets(
      'scrolling up from the bottom never overshoots and bounces back',
      (tester) async {
        await tester.pumpWidget(clickScrollHarness());
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
      },
    );
  });

  group('SideNavSelect consumes category.layout', () {
    testWidgets('defaults to a wrap when no layout is set', (tester) async {
      await tester.pumpWidget(
        _sideNavHarness({
          _category(
            'c1',
            'C1',
            null,
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-2', name: 'Two'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectWrapView), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('renders SelectListView for SelectListLayout', (tester) async {
      await tester.pumpWidget(
        _sideNavHarness({
          _category(
            'c1',
            'C1',
            const SelectListLayout(),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-2', name: 'Two'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectListView), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('renders SelectGridView for SelectGridLayout', (tester) async {
      await tester.pumpWidget(
        _sideNavHarness({
          _category(
            'c1',
            'C1',
            const SelectGridLayout(crossAxisCount: 3),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-2', name: 'Two'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectGridView), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('renders SelectWrapView for SelectWrapLayout', (tester) async {
      await tester.pumpWidget(
        _sideNavHarness({
          _category(
            'c1',
            'C1',
            const SelectWrapLayout(),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-2', name: 'Two'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectWrapView), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('renders SelectRangeView for SelectRangeLayout', (
      tester,
    ) async {
      await tester.pumpWidget(
        _sideNavHarness({
          _category(
            'c1',
            'C1',
            const SelectRangeLayout(),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectRangeView), findsOneWidget);
    });

    testWidgets('renders SelectCounter for SelectCounterLayout', (
      tester,
    ) async {
      await tester.pumpWidget(
        _sideNavHarness({
          _category(
            'c1',
            'C1',
            const SelectCounterLayout(),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-2', name: 'Two'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectCounter), findsOneWidget);
    });

    testWidgets('renders each category with its own layout', (tester) async {
      await tester.pumpWidget(
        _sideNavHarness({
          _category(
            'c1',
            'C1',
            const SelectListLayout(),
            children: {
              SelectTextEntry<dynamic>(parentId: 'c1', id: 'c1-1', name: 'One'),
            },
          ),
          _category(
            'c2',
            'C2',
            const SelectWrapLayout(),
            children: {
              SelectTextEntry<dynamic>(
                parentId: 'c2',
                id: 'c2-1',
                name: 'ChipA',
              ),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectListView), findsOneWidget);
      expect(find.byType(SelectWrapView), findsOneWidget);
    });
  });

  group('SideNavSelect category header/footer', () {
    SelectCategoryEntry<dynamic> categoryWithHeaderFooter() =>
        SelectCategoryEntry<dynamic>(
          id: 'c1',
          name: 'C1',
          layout: const SelectListLayout(),
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

    testWidgets('renders header/footer chip bars around the category content', (
      tester,
    ) async {
      await tester.pumpWidget(_sideNavHarness({categoryWithHeaderFooter()}));
      await tester.pumpAndSettle();

      // Category content (list) plus header and footer chip bars.
      expect(find.byType(SelectListView), findsOneWidget);
      expect(find.byType(SelectChipBar), findsNWidgets(2));
      expect(find.byType(SelectWrapView), findsNothing);
      expect(find.text('H1'), findsOneWidget);
      expect(find.text('H2'), findsOneWidget);
      expect(find.text('F1'), findsOneWidget);

      // Vertical order: header chips -> category content -> footer chips.
      expect(
        tester.getTopLeft(find.text('H1')).dy,
        lessThan(tester.getTopLeft(find.text('One')).dy),
      );
      expect(
        tester.getTopLeft(find.text('One')).dy,
        lessThan(tester.getTopLeft(find.text('F1')).dy),
      );
    });

    testWidgets('renders the category title once above the header chips', (
      tester,
    ) async {
      await tester.pumpWidget(_sideNavHarness({categoryWithHeaderFooter()}));
      await tester.pumpAndSettle();

      // 'C1' appears twice: once in the side bar and once as the category
      // title rendered by the side-nav body itself.
      expect(find.text('C1'), findsNWidgets(2));

      // The inner list view renders no title of its own (showTitle: false).
      expect(
        find.descendant(
          of: find.byType(SelectListView),
          matching: find.text('C1'),
        ),
        findsNothing,
      );

      // Vertical order: category title -> header chips -> content -> footer.
      expect(
        tester.getTopLeft(find.text('C1').last).dy,
        lessThan(tester.getTopLeft(find.text('H1')).dy),
      );
      expect(
        tester.getTopLeft(find.text('H1')).dy,
        lessThan(tester.getTopLeft(find.text('One')).dy),
      );
    });

    testWidgets('tapping header/footer children applies their selections', (
      tester,
    ) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: SideNavSelectDelegate(
                selectionMode: SelectionMode.multiple,
                entriesLoader: () async => {categoryWithHeaderFooter()},
              ),
              onChanged: applied.add,
            ),
          ),
        ),
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
  });
}
