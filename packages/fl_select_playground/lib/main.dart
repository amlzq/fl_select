import 'dart:async';

import 'package:fl_select/fl_select.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'generated/l10n/app_localizations.dart';
import 'playground_l10n.dart';
import 'playground_page.dart';
import 'playground_params.dart';
import 'theme_mode.dart';
import 'url_state.dart';

void main() {
  usePathUrlStrategy();

  // Restore the playground state (demo params + language + theme mode) from
  // the URL so a shared link reproduces the exact configuration.
  final initialState = PlaygroundUrlCodec.decode(
    Uri.base.queryParameters,
    fallback: const PlaygroundUrlState(
      params: kDefaultPlaygroundParams,
      language: PlaygroundLanguage.english,
      themeMode: ThemeMode.system,
    ),
  );

  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  runApp(PlaygroundApp(initialState: initialState));
}

class PlaygroundApp extends StatefulWidget {
  const PlaygroundApp({super.key, required this.initialState});

  /// State decoded from the URL at startup; used as the initial
  /// configuration.
  final PlaygroundUrlState initialState;

  @override
  State<PlaygroundApp> createState() => _PlaygroundAppState();
}

/// Owns the whole playground state (params, language, theme mode) so every
/// mutation funnels through one place that also mirrors the state into the
/// browser address bar — making the URL copyable and shareable.
class _PlaygroundAppState extends State<PlaygroundApp> {
  late final ValueNotifier<ThemeMode> _themeModeController =
      ValueNotifier<ThemeMode>(widget.initialState.themeMode);

  late PlaygroundLanguage _language = widget.initialState.language;

  late PlaygroundParams _params = widget.initialState.params;

  /// Debounces address-bar updates so dragging a slider (which fires many
  /// mutations per second) does not spam the browser history.
  Timer? _urlSyncDebounce;

  @override
  void initState() {
    super.initState();
    _themeModeController.addListener(_scheduleUrlSync);
  }

  @override
  void dispose() {
    _urlSyncDebounce?.cancel();
    _themeModeController.removeListener(_scheduleUrlSync);
    _themeModeController.dispose();
    super.dispose();
  }

  PlaygroundUrlState get _currentState => PlaygroundUrlState(
        params: _params,
        language: _language,
        themeMode: _themeModeController.value,
      );

  void _setParams(PlaygroundParams params) {
    setState(() => _params = params);
    _scheduleUrlSync();
  }

  void _setLanguage(PlaygroundLanguage language) {
    setState(() => _language = language);
    _scheduleUrlSync();
  }

  void _scheduleUrlSync() {
    _urlSyncDebounce?.cancel();
    _urlSyncDebounce = Timer(const Duration(milliseconds: 300), _syncUrl);
  }

  /// Mirrors the current state into the address bar via
  /// [SystemNavigator.routeInformationUpdated]. `replace: true` rewrites the
  /// current history entry instead of pushing a new one, so parameter
  /// tweaking never pollutes the back stack. Web only; on other platforms
  /// the URL concept does not apply.
  Future<void> _syncUrl() async {
    if (!kIsWeb) return;
    await SystemNavigator.routeInformationUpdated(
      uri: PlaygroundUrlCodec.buildUri(
        Uri.base,
        PlaygroundUrlCodec.toQuery(_currentState),
      ),
      replace: true,
    );
  }

  /// Builds the shareable URL for the current state and flushes any pending
  /// debounced sync so the address bar matches what is copied.
  Uri _buildShareUri() {
    _urlSyncDebounce?.cancel();
    unawaited(_syncUrl());
    return PlaygroundUrlCodec.buildUri(
      Uri.base,
      PlaygroundUrlCodec.toQuery(_currentState),
    );
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
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              SelectLocalizationsDelegate(),
              AppLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('de'),
              Locale('en'),
              Locale('es'),
              Locale('fr'),
              Locale('id'),
              Locale('ja'),
              Locale('ko'),
              Locale('pt'),
              Locale('vi'),
              Locale.fromSubtags(languageCode: 'zh'),
              Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
              Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
              Locale.fromSubtags(
                languageCode: 'zh',
                scriptCode: 'Hant',
                countryCode: 'HK',
              ),
              Locale.fromSubtags(
                languageCode: 'zh',
                scriptCode: 'Hant',
                countryCode: 'TW',
              ),
            ],
            home: PlaygroundPage(
              params: _params,
              language: _language,
              onParamsChanged: _setParams,
              onLanguageChanged: _setLanguage,
              buildShareUri: _buildShareUri,
            ),
          );
        },
      ),
    );
  }
}
