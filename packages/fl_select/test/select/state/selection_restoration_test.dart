import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SelectEntries _entries(String id) => <SelectEntry<dynamic>>{
      SelectTextEntry<dynamic>.name(id: id, name: id.toUpperCase()),
    };

void main() {
  group('Selection restoration', () {
    test(
        'handleApply writes the applied selection back to delegate.selectedData',
        () {
      final delegate = ListSelectDelegate(
        entriesLoader: () async => <SelectEntry<dynamic>>{},
      );
      final controller = PopupSelectController();
      controller.attachSelectDelegates(<SelectDelegate>[delegate]);
      controller.currentIndex = 0;
      // Opening the selector sets `previousSelectDelegate`; `handleApply`
      // then writes the applied selection back onto it.
      controller.previousSelectDelegate = delegate;
      // `handleApply` writes the applied selection back to the active label
      // state, so a label state must exist at index 0.
      controller.labelStateMap[0] = SelectLabelState();

      final applied = _entries('a');
      controller.handleApply(applied, 'Selected');

      // The applied selection must be persisted on the delegate so that a
      // reopened controller (PopupSelectBar / Button / Dialog / bottom
      // sheet) reconstructs with `previousSelected = applied`.
      expect(delegate.selectedEntries, applied);
    });

    testWidgets('PopupSelectBar restores the previous selection when reopened',
        (tester) async {
      final controller = PopupSelectController();
      final delegate = ListSelectDelegate(
        selectionMode: SelectionMode.multiple,
        entriesLoader: () async => <SelectEntry<dynamic>>{
          SelectTextEntry<dynamic>.name(id: 'a', name: 'A'),
          SelectTextEntry<dynamic>.name(id: 'b', name: 'B'),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PopupSelectBar(
              tabs: const [PopupTab(label: 'Filter')],
              selectDelegates: [delegate],
              onApplied: (_, __) {},
              controller: controller,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );

      // Open, select A, then press Apply (the action bar apply triggers
      // `handleApply`, which writes the selection back to `selectedData`).
      await tester.tap(find.widgetWithText(PopupTab, 'Filter'));
      await tester.pumpAndSettle();
      expect(controller.isSelectShowing, isTrue);
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // The applied selection is written back to the delegate.
      expect(delegate.selectedEntries, isNotNull);
      expect(delegate.selectedEntries!.any((e) => e.id == 'a'), isTrue);

      // Reopen: the controller must be rebuilt with `selectedEntries` coming
      // from `delegate.selectedData`, so the previously applied selection is
      // restored rather than lost. The tab label now shows the applied value.
      await tester.tap(find.widgetWithText(PopupTab, 'A'));
      await tester.pumpAndSettle();

      expect(controller.isSelectShowing, isTrue);
      expect(controller.selectController, isNotNull);
      expect(
          controller.selectController!.selectedEntries!.any((e) => e.id == 'a'),
          isTrue);
    });
  });
}
