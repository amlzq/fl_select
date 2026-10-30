import 'package:fl_select_playground/main.dart';
import 'package:fl_select_playground/playground_l10n.dart';
import 'package:fl_select_playground/url_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'playground',
      packageName: 'playground',
      version: '1.2.3',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    PlaygroundLanguage language = PlaygroundLanguage.english,
  }) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      PlaygroundApp(
        initialState: PlaygroundUrlState(
          params: kDefaultPlaygroundParams,
          language: language,
          themeMode: ThemeMode.system,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the playground page with the version', (tester) async {
    await pumpApp(tester);
    expect(find.text('Playground'), findsOneWidget);
    expect(find.textContaining('1.2.3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in every supported language', (tester) async {
    for (final lang in PlaygroundLanguage.values) {
      await pumpApp(tester, language: lang);
      expect(find.byType(PlaygroundApp), findsOneWidget, reason: '$lang');
      expect(tester.takeException(), isNull, reason: '$lang');
    }
  });

  testWidgets('language menu lists all languages and switches', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();
    for (final lang in PlaygroundLanguage.values) {
      expect(find.text(lang.label), findsOneWidget, reason: lang.label);
    }
    await tester.ensureVisible(find.text('中文（台灣）'));
    await tester.tap(find.text('中文（台灣）'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('語言'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
