import 'package:fl_select/fl_select.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '../generated/l10n/app_localizations.dart';
import 'leyoujia/leyoujia_page.dart';
import 'playground/playground_page.dart';
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
            home: _resolveHomePage(),
          );
        },
      ),
    );
  }
}

/// Resolves the default landing page based on the current platform and locale.
///
/// - Web or desktop → [PlaygroundPage].
/// - Mobile with a Chinese locale → [LeyoujiaPage].
/// - Mobile with any other locale → [ZillowPage].
Widget _resolveHomePage() {
  final bool isDesktop = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);
  if (kIsWeb || isDesktop) {
    return const PlaygroundPage();
  }
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final bool isChinese = locale.languageCode == 'zh';
  return isChinese ? const LeyoujiaPage() : const ZillowPage();
}
