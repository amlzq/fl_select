import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the list-tile flavor rendered per selection mode:
/// a category without an explicit `selectionMode` must inherit the
/// delegate-level mode (multiple -> [SelectCheckboxListTile]), while a
/// category-level `SelectionMode.single` override keeps
/// [SelectRadioListTile]. The same applies to the flat [ListSelectDelegate].

Widget _harness(SelectDelegate delegate) {
  return MaterialApp(
    home: Scaffold(
      body: SelectView(
        delegate: delegate,
        onChanged: (_) {},
      ),
    ),
  );
}

void main() {
  group('ExpandableSelectDelegate list tiles', () {
    testWidgets(
        'category without an explicit selectionMode inherits the delegate '
        'multiple mode and renders checkbox tiles', (tester) async {
      await tester.pumpWidget(
        _harness(
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
    });

    testWidgets(
        'category-level single override renders radio tiles even when the '
        'delegate mode is multiple', (tester) async {
      await tester.pumpWidget(
        _harness(
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
    });
  });

  group('ListSelectDelegate list tiles', () {
    testWidgets('multiple mode renders checkbox tiles', (tester) async {
      await tester.pumpWidget(
        _harness(
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

    testWidgets('single mode renders radio tiles', (tester) async {
      await tester.pumpWidget(
        _harness(
          ListSelectDelegate(
            selectionMode: SelectionMode.single,
            entries: {
              SelectTextEntry<dynamic>.name(id: 'a', name: 'Item A'),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectRadioListTile), findsOneWidget);
      expect(find.byType(SelectCheckboxListTile), findsNothing);
    });
  });
}
