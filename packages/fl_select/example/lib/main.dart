import 'package:example/leyoujia/leyoujia_page.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '../generated/l10n/app_localizations.dart';
import 'bottom_sheet_example.dart';
import 'dialog_example.dart';
import 'playground/playground_page.dart';
import 'popup_select_bar_example.dart';
import 'popup_select_button_example.dart';
import 'select_view_example.dart';
import 'theme_mode.dart';
import 'zillow/zillow_page.dart';

void main() {
  usePathUrlStrategy();
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<ThemeMode> _themeModeController =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  @override
  void dispose() {
    _themeModeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.deepPurple;
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
    return ThemeModeScope(
      controller: _themeModeController,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeModeController,
        builder: (context, themeMode, _) {
          return MaterialApp(
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)?.appName ?? '',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              SelectLocalizationsDelegate(),
            ],
            supportedLocales: const [
              Locale('en'),
              Locale.fromSubtags(languageCode: 'zh'),
              Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
              Locale.fromSubtags(
                languageCode: 'zh',
                scriptCode: 'Hant',
                countryCode: 'TW',
              ),
              Locale.fromSubtags(
                languageCode: 'zh',
                scriptCode: 'Hant',
                countryCode: 'HK',
              ),
            ],
            builder: (context, child) {
              final baseTheme = Theme.of(context);
              final theme = baseTheme.copyWith(
                extensions: <ThemeExtension<dynamic>>[
                  PopupSelectBarTheme(
                    overlayStyle: const SelectOverlayStyle(
                      barrierColor: Colors.black54,
                    ),
                    selectTheme: SelectThemeData(baseTheme),
                  ),
                ],
              );
              return Theme(
                data: theme,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: kIsWeb ? const PlaygroundPage() : const MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flselect Example'),
      ),
      body: Center(
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SelectViewExamplePage()),
                );
              },
              child: const Text('SelectView Example'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PopupSelectButtonExample()),
                );
              },
              child: const Text('PopupSelectButton Example'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PopupSelectBarExample()),
                );
              },
              child: const Text('PopupSelectBar Example'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DialogExample()),
                );
              },
              child: const Text('Dialog Example'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BottomSheetExample()),
                );
              },
              child: const Text('BottomSheet Example'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ZillowPage()),
                );
              },
              child: const Text('Zillow'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LeyoujiaPage()),
                );
              },
              child: const Text('Leyoujia'),
            ),
          ],
        ),
      ),
    );
  }
}
