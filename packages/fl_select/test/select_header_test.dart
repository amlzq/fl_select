import 'package:fl_select/src/select_header.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme,
  home: Scaffold(body: Column(children: [child])),
);

void main() {
  const leading = SizedBox(key: Key('leading'), width: 40, height: 40);
  const trailing = SizedBox(key: Key('trailing'), width: 40, height: 40);

  testWidgets('left-aligned title flows after leading on android', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SelectHeader(
          title: Text('Title'),
          leading: leading,
          trailing: trailing,
        ),
        theme: ThemeData(platform: TargetPlatform.android),
      ),
    );
    final title = tester.getTopLeft(find.text('Title'));
    expect(title.dx, greaterThanOrEqualTo(20 + 40 + 12));
    expect(tester.getSize(find.byType(SelectHeader)).height, kToolbarHeight);
    expect(find.byKey(const Key('trailing')), findsOneWidget);
  });

  testWidgets('title is centered on iOS despite asymmetric leading', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SelectHeader(title: Text('Title'), leading: leading),
        theme: ThemeData(platform: TargetPlatform.iOS),
      ),
    );
    final headerCenter = tester.getCenter(find.byType(SelectHeader)).dx;
    expect(tester.getCenter(find.text('Title')).dx, closeTo(headerCenter, 1));
    expect(tester.getTopLeft(find.byKey(const Key('leading'))).dx, 20);
  });

  testWidgets('explicit centerTitle overrides platform and theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SelectHeader(
          title: Text('Title'),
          trailing: trailing,
          centerTitle: true,
        ),
        theme: ThemeData(platform: TargetPlatform.android),
      ),
    );
    final headerCenter = tester.getCenter(find.byType(SelectHeader)).dx;
    expect(tester.getCenter(find.text('Title')).dx, closeTo(headerCenter, 1));
    expect(find.byKey(const Key('trailing')), findsOneWidget);
  });

  testWidgets('AppBarTheme.centerTitle is honored', (tester) async {
    await tester.pumpWidget(
      _host(
        const SelectHeader(title: Text('Title')),
        theme: ThemeData(
          platform: TargetPlatform.iOS,
          appBarTheme: const AppBarThemeData(centerTitle: false),
        ),
      ),
    );
    expect(tester.getTopLeft(find.text('Title')).dx, 20);
  });

  testWidgets('without a title only leading/trailing render at the edges', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SelectHeader(leading: leading, trailing: trailing),
        theme: ThemeData(platform: TargetPlatform.iOS),
      ),
    );
    expect(find.byType(DefaultTextStyle), findsWidgets);
    expect(tester.getTopLeft(find.byKey(const Key('leading'))).dx, 20);
    expect(tester.getTopRight(find.byKey(const Key('trailing'))).dx, 800 - 20);
  });

  testWidgets('AppBarTheme.toolbarHeight sets the header height', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SelectHeader(title: Text('Title')),
        theme: ThemeData(appBarTheme: const AppBarThemeData(toolbarHeight: 72)),
      ),
    );
    expect(tester.getSize(find.byType(SelectHeader)).height, 72);
  });

  for (final platform in [
    TargetPlatform.fuchsia,
    TargetPlatform.linux,
    TargetPlatform.windows,
    TargetPlatform.macOS,
  ]) {
    testWidgets('renders on $platform', (tester) async {
      await tester.pumpWidget(
        _host(
          const SelectHeader(title: Text('Title')),
          theme: ThemeData(platform: platform),
        ),
      );
      expect(find.text('Title'), findsOneWidget);
    });
  }
}
