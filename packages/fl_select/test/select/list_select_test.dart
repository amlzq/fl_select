import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [SelectView] backed by a [ListSelectDelegate] so we can assert how
/// [ListSelect] renders each category's `header`/`footer` entries.
Widget _listHarness(
  Set<SelectEntry> entries, {
  SelectionMode selectionMode = SelectionMode.multiple,
  void Function(Set<SelectEntry>)? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(
        delegate: ListSelectDelegate(
          selectionMode: selectionMode,
          entriesLoader: () async => entries,
        ),
        onChanged: onChanged ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('ListSelect category header/footer', () {
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

    testWidgets('renders header/footer chip bars inside the expanded tile',
        (tester) async {
      await tester.pumpWidget(_listHarness({categoryWithHeaderFooter()}));
      await tester.pumpAndSettle();

      // Category content (list) plus header and footer chip bars, all inside
      // the initially expanded tile.
      expect(find.byType(SelectExpansionTile), findsOneWidget);
      expect(find.byType(SelectListView), findsOneWidget);
      expect(find.byType(SelectWrapView), findsNWidgets(2));
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

    testWidgets('tapping header/footer children applies their selections',
        (tester) async {
      final applied = <Set<SelectEntry>>[];
      await tester.pumpWidget(
        _listHarness(
          {categoryWithHeaderFooter()},
          onChanged: applied.add,
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

    testWidgets('collapsing the tile hides header/footer bars', (tester) async {
      await tester.pumpWidget(_listHarness({categoryWithHeaderFooter()}));
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
