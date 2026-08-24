import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectCounterLayout', () {
    test('implements == and hashCode', () {
      const a = SelectCounterLayout();
      const b = SelectCounterLayout();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      // Different layout subclasses must not be equal.
      expect(a, isNot(equals(const SelectListLayout())));
      expect(a, isNot(equals(const SelectChipLayout())));
    });
  });

  group('SelectCounter', () {
    /// Builds a bedrooms-style category with an "Any" entry pinned to the left
    /// followed by value entries (1, 1+, 2, 2+, 3).
    SelectCategoryEntry<dynamic> buildCategory() {
      return SelectCategoryEntry<dynamic>(
        id: 'bedrooms',
        name: 'Bedrooms',
        selectionMode: SelectionMode.single,
        layout: const SelectCounterLayout(),
        children: {
          SelectTextEntry<dynamic>.any(parentId: 'bedrooms', name: 'Any'),
          SelectTextEntry<dynamic>(parentId: 'bedrooms', id: 'b1', name: '1'),
          SelectTextEntry<dynamic>(parentId: 'bedrooms', id: 'b1p', name: '1+'),
          SelectTextEntry<dynamic>(parentId: 'bedrooms', id: 'b2', name: '2'),
          SelectTextEntry<dynamic>(parentId: 'bedrooms', id: 'b2p', name: '2+'),
          SelectTextEntry<dynamic>(parentId: 'bedrooms', id: 'b3', name: '3'),
        },
      );
    }

    Future<void> pumpCounter(
      WidgetTester tester, {
      SelectCategoryEntry<dynamic>? category,
      List<SelectEntry>? entries,
      Set<SelectEntry>? selectedEntries,
      OnChanged<SelectTextEntry>? onChanged,
      bool showTitle = true,
    }) async {
      final cat = category ?? buildCategory();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCounter(
              category: cat,
              entries: entries ?? cat.children!.toList(),
              selectedEntries: selectedEntries,
              onChanged: onChanged ?? (_, __) {},
              showTitle: showTitle,
            ),
          ),
        ),
      );
    }

    IconButton buttonWith(WidgetTester tester, IconData icon) =>
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon));

    testWidgets('renders the category name as a title when showTitle is true',
        (tester) async {
      await pumpCounter(tester);
      expect(find.text('Bedrooms'), findsOneWidget);
    });

    testWidgets('omits the title when showTitle is false', (tester) async {
      await pumpCounter(tester, showTitle: false);
      expect(find.text('Bedrooms'), findsNothing);
    });

    testWidgets('omits the title when category is null', (tester) async {
      final entries = buildCategory().children!.toList();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCounter(
              entries: entries,
              onChanged: (_, __) {},
            ),
          ),
        ),
      );
      expect(find.text('Bedrooms'), findsNothing);
    });

    testWidgets('shows the "Any" value and disables "-" at the left extreme',
        (tester) async {
      await pumpCounter(tester);
      // The Any entry is pinned to the left-most position.
      expect(find.text('Any'), findsOneWidget);
      // At the left extreme the decrement button is disabled.
      expect(buttonWith(tester, Icons.remove).onPressed, isNull);
      // The increment button is still enabled.
      expect(buttonWith(tester, Icons.add).onPressed, isNotNull);
    });

    testWidgets('increments and calls onChanged with the next entry',
        (tester) async {
      final indices = <int>[];
      final entries = <SelectTextEntry>[];
      await pumpCounter(tester, onChanged: (i, e) {
        indices.add(i);
        entries.add(e);
      });

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(indices, [1]);
      expect(entries.single.name, '1');
      expect(find.text('1'), findsOneWidget);
      // Moving off the left extreme re-enables "-".
      expect(buttonWith(tester, Icons.remove).onPressed, isNotNull);
    });

    testWidgets('decrements and calls onChanged with the previous entry',
        (tester) async {
      final indices = <int>[];
      final entries = <SelectTextEntry>[];
      // Start from a selected "2" so the "-" button is active.
      final two = SelectTextEntry<dynamic>(
        parentId: 'bedrooms',
        id: 'b2',
        name: '2',
      );
      await pumpCounter(
        tester,
        selectedEntries: {two},
        onChanged: (i, e) {
          indices.add(i);
          entries.add(e);
        },
      );
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(indices, [2]);
      expect(entries.single.name, '1+');
      expect(find.text('1+'), findsOneWidget);
    });

    testWidgets('disables "+" at the right extreme', (tester) async {
      await pumpCounter(tester);
      // Step through to the last value (index 5 -> "3").
      final add = find.byIcon(Icons.add);
      for (var i = 0; i < 5; i++) {
        await tester.tap(add);
        await tester.pump();
      }
      expect(find.text('3'), findsOneWidget);
      // At the right extreme the increment button is disabled.
      expect(buttonWith(tester, Icons.add).onPressed, isNull);
      // The decrement button is still enabled.
      expect(buttonWith(tester, Icons.remove).onPressed, isNotNull);
    });

    testWidgets('restores the position from selectedEntries on first build',
        (tester) async {
      final twoPlus = SelectTextEntry<dynamic>(
        parentId: 'bedrooms',
        id: 'b2p',
        name: '2+',
      );
      await pumpCounter(tester, selectedEntries: {twoPlus});
      expect(find.text('2+'), findsOneWidget);
    });

    testWidgets('pins the "Any" entry to the left regardless of list order',
        (tester) async {
      // The Any entry appears last in the passed list but must be rendered
      // at the left-most (zero) position.
      final cat = buildCategory();
      final any = SelectTextEntry<dynamic>.any(
        parentId: 'bedrooms',
        name: 'Any',
      );
      final first = SelectTextEntry<dynamic>(
        parentId: 'bedrooms',
        id: 'b1',
        name: '1',
      );
      await pumpCounter(
        tester,
        category: cat,
        entries: [first, any],
      );
      // The Any entry is shown as the current value and "-" is disabled.
      expect(find.text('Any'), findsOneWidget);
      expect(buttonWith(tester, Icons.remove).onPressed, isNull);
    });

    testWidgets('handles empty entries without crashing', (tester) async {
      await pumpCounter(tester, entries: const <SelectEntry>[]);
      // No value text is rendered and no buttons appear.
      expect(find.byType(IconButton), findsNothing);
      expect(find.text('Any'), findsNothing);
    });

    testWidgets('reflects a new selection after a parent rebuild',
        (tester) async {
      final cat = buildCategory();
      final onePlus = SelectTextEntry<dynamic>(
        parentId: 'bedrooms',
        id: 'b1p',
        name: '1+',
      );
      final base = SelectCounter(
        category: cat,
        entries: cat.children!.toList(),
        selectedEntries: const <SelectEntry>{},
        onChanged: (_, __) {},
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: base)));
      expect(find.text('Any'), findsOneWidget);

      // Rebuild with a new selection; the spin box must jump to that value.
      final rebuilt = SelectCounter(
        category: cat,
        entries: cat.children!.toList(),
        selectedEntries: {onePlus},
        onChanged: (_, __) {},
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: rebuilt)));
      expect(find.text('1+'), findsOneWidget);
    });
  });
}
