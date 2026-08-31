import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controls_panel.dart';
import 'entry_repository.dart';
import 'generated/l10n/app_localizations.dart';
import 'phone_frame.dart' show PhoneFrame, kPhoneContentSize;
import 'playground_l10n.dart';
import 'playground_params.dart';
import 'select_builder.dart';
import 'theme_mode.dart';

/// Route name of the base phone screen inside the scoped [Navigator]. Used to
/// keep it from being popped by system back.
const String _kPhoneBaseRouteName = 'playground-phone-base';

/// Interactive demo: a parameter panel on one side and a simulated phone on
/// the other. Changing any parameter rebuilds the phone's select immediately.
///
/// The demo state (params / language / theme mode) is owned by the parent
/// ([PlaygroundApp]), which mirrors it into the browser URL — so any
/// configuration can be reproduced by sharing a copied link.
class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({
    super.key,
    required this.params,
    required this.language,
    required this.onParamsChanged,
    required this.onLanguageChanged,
    required this.buildShareUri,
  });

  final PlaygroundParams params;

  final PlaygroundLanguage language;

  final ValueChanged<PlaygroundParams> onParamsChanged;

  final ValueChanged<PlaygroundLanguage> onLanguageChanged;

  /// Builds (and flushes to the address bar) the URL that reproduces the
  /// current configuration; invoked by the copy-link app bar button.
  final Uri Function() buildShareUri;

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  // The demo data set is language independent; switching the playground
  // language only affects the select's built-in strings.
  final EntryRepository _repo = EntryRepository();

  /// Cache of reusable delegates. See [buildDelegate] for why reusing the same
  /// instance across rebuilds is required (selection restoration).
  final Map<String, SelectDelegate> _delegateCache = <String, SelectDelegate>{};

  /// Keeps the most recent delegate per selection-identity so [buildDelegate]
  /// can carry the applied selection over when the column count / aspect ratio
  /// / spacing changes (those recreate the delegate).
  final Map<String, SelectDelegate> _selectionCache =
      <String, SelectDelegate>{};

  PlaygroundDataSource get _dataSource =>
      PlaygroundDataSource.fromRepository(_repo);

  @override
  Widget build(BuildContext context) {
    // Inject the chosen language into the whole playground subtree (control
    // panel + phone) so both the playground UI and the select's built-in
    // strings (reset / confirm, etc.) follow it. Delegates inherit from the
    // surrounding app; only the locale is overridden.
    return Localizations.override(
      context: context,
      locale: widget.language.locale,
      child: Builder(
        builder: (context) {
          final l10n = PlaygroundL10n(AppLocalizations.of(context)!);
          return _buildScaffold(context, l10n);
        },
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, PlaygroundL10n l10n) {
    final params = widget.params;

    // When the brightness parameter is null, follow the app's resolved
    // brightness (the ThemeMode chosen by the top-right button, including
    // `system`); otherwise use the explicitly selected one. Read from the
    // outer context *before* the preview's own Theme override below.
    final effectiveBrightness =
        params.brightness ?? Theme.of(context).brightness;

    final paramTheme = ThemeData(
      useMaterial3: params.useMaterial3,
      colorScheme: ColorScheme.fromSeed(
        seedColor: params.seedColor,
        brightness: effectiveBrightness,
      ),
    );
    final delegate = buildDelegate(
      params,
      _dataSource,
      delegateCache: _delegateCache,
      selectionCache: _selectionCache,
    );

    // Add the playground theme *above* the scoped [Navigator] so that routes
    // pushed by [showSelect] / [showModalBottomSelect] /
    // [PopupSelectBar] / [PopupSelectButton] (which all use the
    // scoped navigator via `useRootNavigator: false`) also inherit this theme.
    // If the [Theme] is placed *inside* the navigator's base page, only the
    // base screen gets it while the route overlay (which lives outside the
    // page stack) falls back to the host app's light theme — making the
    // select popup ignore the dark/light toggle.
    final paramThemeWithExtensions = paramTheme.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        PopupSelectBarTheme(selectTheme: SelectThemeData(paramTheme)),
        PopupSelectButtonTheme(selectTheme: SelectThemeData(paramTheme)),
      ],
    );

    // Scope the dropdown overlay, dialog and bottom sheet to the phone: a
    // dedicated [Navigator] provides a local overlay, and a phone-sized
    // [MediaQuery] makes the select position/clamp itself within the phone
    // screen instead of the whole window.
    final phoneScreen = Theme(
      data: paramThemeWithExtensions,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: kPhoneContentSize,
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
        ),
        child: Navigator(
          // Use `pages` (not `onGenerateRoute`): `onGenerateRoute` is only
          // invoked once, so the captured initial route would never reflect
          // later parameter/theme changes and switching the entry point would
          // appear to do nothing. With `pages` the base screen stays in sync
          // with the latest `themedScreen`, while `showDialog` /
          // `showModalBottomSheet` still push their routes on top.
          onDidRemovePage: (page) {
            // The base phone screen must never be removed. Pushed dialogs /
            // bottom sheets are route-backed (not page-backed), so this
            // callback is only ever invoked for the base page, which we
            // intentionally keep.
            if (page.name == _kPhoneBaseRouteName) return;
          },
          pages: <Page<void>>[
            MaterialPage<void>(
              // Keep a constant key so switching the playground theme does NOT
              // tear down and rebuild the base route: a changing key would
              // dispose the SelectView / PopupSelectBar subtrees, drop
              // their controllers and re-fetch select data (showing a skeleton
              // flash) — a visible hitch. Instead the theme is applied *inside*
              // this page via the [Theme] below, whose dependents rebuild in
              // place (elements kept, no data reload). The entry-point switch is
              // still handled by the keyed [EntryPointScreen] inside
              // [buildPhoneScreen], so this constant key only concerns the base.
              key: const ValueKey(_kPhoneBaseRouteName),
              name: _kPhoneBaseRouteName,
              child: Theme(
                data: paramThemeWithExtensions,
                child: buildPhoneScreen(
                  params,
                  delegate,
                  l10n,
                  data: _dataSource,
                  delegateCache: _delegateCache,
                  selectionCache: _selectionCache,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.title),
        actions: <Widget>[
          _ShareLinkButton(
            tooltip: l10n.shareTooltip,
            copiedMessage: l10n.linkCopied,
            onCopy: widget.buildShareUri,
          ),
          const SizedBox(width: 8),
          _LanguageSwitch(
            language: widget.language,
            tooltip: l10n.languageTooltip,
            onChanged: widget.onLanguageChanged,
          ),
          const SizedBox(width: 8),
          const ThemeModeButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 820) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: 340,
                  child: ControlsPanel(
                    params: params,
                    l10n: l10n,
                    onChanged: widget.onParamsChanged,
                  ),
                ),
                Expanded(
                  // Scale the native 390x844 phone down (or up) to fit the
                  // available area while preserving aspect ratio.
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: PhoneFrame(
                      screen: phoneScreen,
                      brightness: effectiveBrightness,
                    ),
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ControlsPanel(
                  params: params,
                  l10n: l10n,
                  onChanged: widget.onParamsChanged,
                ),
                FittedBox(
                  fit: BoxFit.contain,
                  child: PhoneFrame(
                    screen: phoneScreen,
                    brightness: effectiveBrightness,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Top-right copy-link button: puts the URL that reproduces the current
/// configuration on the clipboard and confirms with a snackbar.
class _ShareLinkButton extends StatelessWidget {
  final String tooltip;

  final String copiedMessage;

  final Uri Function() onCopy;

  const _ShareLinkButton({
    required this.tooltip,
    required this.copiedMessage,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: const Icon(Icons.link),
      onPressed: () {
        final url = onCopy().toString();
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(copiedMessage)));
      },
    );
  }
}

/// Top-right language switcher for the playground.
class _LanguageSwitch extends StatelessWidget {
  final PlaygroundLanguage language;
  final String tooltip;
  final ValueChanged<PlaygroundLanguage> onChanged;

  const _LanguageSwitch({
    required this.language,
    required this.tooltip,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PlaygroundLanguage>(
      icon: const Icon(Icons.translate),
      tooltip: tooltip,
      initialValue: language,
      onSelected: onChanged,
      itemBuilder: (context) => <PopupMenuEntry<PlaygroundLanguage>>[
        for (final lang in PlaygroundLanguage.values)
          CheckedPopupMenuItem<PlaygroundLanguage>(
            value: lang,
            checked: lang == language,
            child: Text(lang.label),
          ),
      ],
    );
  }
}
