import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PopupSelectButton', () {
    testWidgets('toggles overlay and rotates the icon on tap', (tester) async {
      var showed = false;
      var hidden = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PopupSelectButton(
              label: 'Filter',
              selectDelegate: ListSelectDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{
                  SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                },
              ),
              onApplied: (_) {},
              onSelectShowed: () => showed = true,
              onSelectHidden: () => hidden = true,
            ),
          ),
        ),
      );

      expect(showed, isFalse);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      expect(showed, isTrue);
      // The trailing icon rotates 180° (visually) while the overlay is open.
      final rotationFinder = find.descendant(
        of: find.byType(PopupSelectButton),
        matching: find.byType(RotationTransition),
      );
      final rotation = tester.widget<RotationTransition>(rotationFinder);
      expect(rotation.turns.value, closeTo(0.5, 0.001));
      expect(find.text('A'), findsOneWidget);

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      expect(hidden, isTrue);
      final rotationClosed = tester.widget<RotationTransition>(rotationFinder);
      expect(rotationClosed.turns.value, closeTo(0.0, 0.001));
    });

    testWidgets('applies selection and updates the trigger label',
        (tester) async {
      SelectEntries? applied;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PopupSelectButton(
              label: 'Sort',
              selectDelegate: ListSelectDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{
                  SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                  SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
                },
              ),
              onApplied: (selected) => applied = selected,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(find.text('Sort'), findsNothing);
      expect(find.text('A'), findsOneWidget);

      expect(applied, isNotNull);
      expect(applied!.any((e) => e.id == 'a'), isTrue);
    });

    testWidgets('labelLoader overrides the trigger label after apply',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PopupSelectButton(
              label: 'Sort',
              labelLoader: (selected) => '${selected.length} selected',
              selectDelegate: ListSelectDelegate(
                entriesLoader: () async => <SelectEntry<dynamic>>{
                  SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
                  SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
                },
              ),
              onApplied: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(find.text('Sort'), findsNothing);
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('renders outlined and elevated variants', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: [
                PopupSelectButton.elevated(
                  label: 'Elevated',
                  selectDelegate: ListSelectDelegate(
                    entriesLoader: () async => <SelectEntry<dynamic>>{},
                  ),
                  onApplied: (_) {},
                ),
                PopupSelectButton.outlined(
                  label: 'Outlined',
                  selectDelegate: ListSelectDelegate(
                    entriesLoader: () async => <SelectEntry<dynamic>>{},
                  ),
                  onApplied: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Elevated'), findsOneWidget);
      expect(find.text('Outlined'), findsOneWidget);
    });
  });
}
