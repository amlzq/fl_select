import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('demo renders the agent payload and writes selections back', (
    tester,
  ) async {
    // The demo is a ListView; a tall surface keeps all three sections built.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FlSelectGenuiDemo());
    await tester.pumpAndSettle();

    // The write-back panel is the demo's only SelectableText.
    String writeBack() =>
        tester.widget<SelectableText>(find.byType(SelectableText)).data!;

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(writeBack(), contains('nothing selected yet'));

    await tester.tap(find.text('Wi-Fi'));
    await tester.pumpAndSettle();

    expect(writeBack(), allOf(contains('"amenities"'), contains('wifi')));
  });
}
