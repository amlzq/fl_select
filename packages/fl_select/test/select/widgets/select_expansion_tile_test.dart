import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({required bool showBadge}) => MaterialApp(
      home: Scaffold(
        body: SelectExpansionTile(
          title: 'Cate 1',
          showBadge: showBadge,
          child: const SizedBox(height: 40),
        ),
      ),
    );

void main() {
  testWidgets('showBadge=false renders no badge', (tester) async {
    await tester.pumpWidget(_harness(showBadge: false));
    await tester.pumpAndSettle();

    expect(find.byType(SelectBadge), findsNothing);
  });

  testWidgets('showBadge=true badges the title at its top-right corner',
      (tester) async {
    await tester.pumpWidget(_harness(showBadge: true));
    await tester.pumpAndSettle();

    expect(find.byType(SelectBadge), findsOneWidget);

    // The dot hangs off the top-right corner of the title text: right of its
    // right edge and above its vertical center.
    final badge = tester.getRect(find.byType(SelectBadge));
    final title = tester.getRect(find.text('Cate 1'));
    expect(badge.center.dx, greaterThan(title.right));
    expect(badge.center.dy, lessThan(title.center.dy));
  });

  testWidgets('the badge does not change the title layout', (tester) async {
    await tester.pumpWidget(_harness(showBadge: false));
    await tester.pumpAndSettle();
    final withoutBadge = tester.getRect(find.text('Cate 1'));

    await tester.pumpWidget(_harness(showBadge: true));
    await tester.pumpAndSettle();
    final withBadge = tester.getRect(find.text('Cate 1'));

    expect(withBadge, equals(withoutBadge));
  });
}
