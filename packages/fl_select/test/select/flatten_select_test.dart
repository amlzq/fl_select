import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [SelectView] backed by a [FlattenSelectDelegate] so we can assert
/// how [FlattenSelect] consumes each [SelectCategoryEntry.layout].
Widget _flattenHarness(Set<SelectEntry> entries) {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(
        delegate: FlattenSelectDelegate(
          entriesLoader: () async => entries,
        ),
        onChanged: (_) {},
      ),
    ),
  );
}

SelectCategoryEntry<dynamic> _category(
  String id,
  String name,
  SelectLayout layout, {
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
  group('FlattenSelect flat structure', () {
    Widget harness(Set<SelectEntry> entries) {
      return MaterialApp(
        home: Scaffold(
          body: SelectView(
            delegate: FlattenSelectDelegate(
              entriesLoader: () async => entries,
            ),
            onChanged: (_) {},
          ),
        ),
      );
    }

    testWidgets('renders a SelectChipBar without a sidebar', (tester) async {
      await tester.pumpWidget(
        harness({
          SelectTextEntry<dynamic>.name(id: 'a1', name: 'A 1'),
          SelectTextEntry<dynamic>.name(id: 'a2', name: 'A 2'),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectChipBar), findsOneWidget);
      expect(find.byType(SelectSideBar), findsNothing);
      expect(find.text('A 1'), findsOneWidget);
      expect(find.text('A 2'), findsOneWidget);
    });

    testWidgets('tapping a flat chip reports a selection', (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: FlattenSelectDelegate(
                selectionMode: SelectionMode.single,
                entriesLoader: () async => {
                  SelectTextEntry<dynamic>.name(id: 'a1', name: 'A 1'),
                  SelectTextEntry<dynamic>.name(id: 'a2', name: 'A 2'),
                },
              ),
              onChanged: applied.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A 2'));
      await tester.pumpAndSettle();

      expect(applied, hasLength(1));
      expect(applied.single.map((e) => e.id), contains('a2'));
    });
  });

  group('FlattenSelect consumes category.layout', () {
    testWidgets('defaults to a grid when no layout is set', (tester) async {
      await tester.pumpWidget(
        _flattenHarness({
          _category(
            'c1',
            'C1',
            const SelectGridLayout(crossAxisCount: 2),
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

    testWidgets('renders SelectListView for SelectListLayout', (tester) async {
      await tester.pumpWidget(
        _flattenHarness({
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
        _flattenHarness({
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

    testWidgets('renders SelectChipBar for SelectWrapLayout', (tester) async {
      await tester.pumpWidget(
        _flattenHarness({
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

      expect(find.byType(SelectChipBar), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('renders SelectRangeView for SelectRangeLayout',
        (tester) async {
      await tester.pumpWidget(
        _flattenHarness({
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

    testWidgets('renders SelectCounter for SelectCounterLayout',
        (tester) async {
      await tester.pumpWidget(
        _flattenHarness({
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
        _flattenHarness({
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
                  parentId: 'c2', id: 'c2-1', name: 'ChipA'),
            },
          ),
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectListView), findsOneWidget);
      expect(find.byType(SelectChipBar), findsOneWidget);
    });
  });

  group('FlattenSelect category header/footer', () {
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
                  parentId: 'header', id: 'h1', name: 'H1', immediate: true),
              SelectTextEntry<dynamic>(
                  parentId: 'header', id: 'h2', name: 'H2', immediate: true),
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
                  parentId: 'footer', id: 'f1', name: 'F1', immediate: true),
            },
          ),
        );

    testWidgets('renders header/footer chip bars around the category content',
        (tester) async {
      await tester.pumpWidget(_flattenHarness({categoryWithHeaderFooter()}));
      await tester.pumpAndSettle();

      // Category content (list) plus header and footer chip bars.
      expect(find.byType(SelectListView), findsOneWidget);
      expect(find.byType(SelectChipBar), findsNWidgets(2));
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

    testWidgets('renders the category title once above the header chips',
        (tester) async {
      await tester.pumpWidget(_flattenHarness({categoryWithHeaderFooter()}));
      await tester.pumpAndSettle();

      // 'C1' appears twice: once in the side bar and once as the category
      // title rendered by the flatten view itself.
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

    testWidgets('tapping header/footer children applies their selections',
        (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectView(
              delegate: FlattenSelectDelegate(
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
