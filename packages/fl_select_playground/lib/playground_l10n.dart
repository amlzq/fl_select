import 'package:flutter/widgets.dart';

import 'generated/l10n/app_localizations.dart';

/// Supported UI languages for the playground, aligned with the locales
/// supported by `fl_select`'s built-in translations (13 locales). The demo
/// data set is language independent (see `entry_repository.dart`); switching
/// the language only affects the playground UI and the select's built-in
/// strings.
enum PlaygroundLanguage {
  english,
  german,
  spanish,
  french,
  indonesian,
  japanese,
  korean,
  portuguese,
  vietnamese,
  simplifiedChinese,
  traditionalChinese,
  traditionalChineseHk,
  traditionalChineseTw,
}

extension PlaygroundLanguageX on PlaygroundLanguage {
  /// The [Locale] injected via [Localizations.override] so the playground UI
  /// and the select's built-in strings (reset / confirm, etc.) follow it.
  Locale get locale {
    switch (this) {
      case PlaygroundLanguage.english:
        return const Locale('en');
      case PlaygroundLanguage.german:
        return const Locale('de');
      case PlaygroundLanguage.spanish:
        return const Locale('es');
      case PlaygroundLanguage.french:
        return const Locale('fr');
      case PlaygroundLanguage.indonesian:
        return const Locale('id');
      case PlaygroundLanguage.japanese:
        return const Locale('ja');
      case PlaygroundLanguage.korean:
        return const Locale('ko');
      case PlaygroundLanguage.portuguese:
        return const Locale('pt');
      case PlaygroundLanguage.vietnamese:
        return const Locale('vi');
      case PlaygroundLanguage.simplifiedChinese:
        return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
      case PlaygroundLanguage.traditionalChinese:
        return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
      case PlaygroundLanguage.traditionalChineseHk:
        return const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'HK',
        );
      case PlaygroundLanguage.traditionalChineseTw:
        return const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        );
    }
  }

  /// Short label (in its own language) shown in the language switcher.
  String get label {
    switch (this) {
      case PlaygroundLanguage.english:
        return 'English';
      case PlaygroundLanguage.german:
        return 'Deutsch';
      case PlaygroundLanguage.spanish:
        return 'Español';
      case PlaygroundLanguage.french:
        return 'Français';
      case PlaygroundLanguage.indonesian:
        return 'Bahasa Indonesia';
      case PlaygroundLanguage.japanese:
        return '日本語';
      case PlaygroundLanguage.korean:
        return '한국어';
      case PlaygroundLanguage.portuguese:
        return 'Português';
      case PlaygroundLanguage.vietnamese:
        return 'Tiếng Việt';
      case PlaygroundLanguage.simplifiedChinese:
        return '简体中文';
      case PlaygroundLanguage.traditionalChinese:
        return '繁體中文';
      case PlaygroundLanguage.traditionalChineseHk:
        return '繁體中文（香港）';
      case PlaygroundLanguage.traditionalChineseTw:
        return '繁體中文（台灣）';
    }
  }
}

/// Localization for the playground UI, delegating to the generated
/// [AppLocalizations] (13 locales, same set as `fl_select`). Obtain it inside
/// the [Localizations.override] scope set up by the playground page so it
/// follows the language chosen in the switcher.
class PlaygroundL10n {
  final AppLocalizations _l10n;

  const PlaygroundL10n(this._l10n);

  // App bar. ("Playground" is a product name; kept untranslated.)
  String get title => 'Playground';
  String get languageTooltip => _l10n.languageTooltip;

  // Section titles.
  String get entryPoint => _l10n.entryPoint;
  String get delegate => _l10n.delegateLabel;
  String get selectionMode => _l10n.selectionMode;
  String get tileVariant => _l10n.tileVariant;
  String get seedColor => _l10n.seedColor;

  String columns(int value) => _l10n.columns(value);
  String aspectRatio(String value) => _l10n.aspectRatio(value);
  String spacing(int value) => _l10n.spacing(value);

  // Selection mode segments.
  String get single => _l10n.single;
  String get multiple => _l10n.multiple;

  // Tile variant segments.
  String get filled => _l10n.filled;
  String get outlined => _l10n.outlined;

  // Material 3 switch.
  String get material3 => 'Material 3';

  // Brightness segments.
  String get brightness => _l10n.brightness;
  String get follow => _l10n.follow;
  String get light => _l10n.light;
  String get dark => _l10n.dark;

  // Delegate options.
  String get layoutList => _l10n.layoutList;
  String get layoutGrid => _l10n.layoutGrid;
  String get layoutWrap => _l10n.layoutWrap;
  String get layoutCascading => _l10n.layoutCascading;
  String get layoutTabNav => _l10n.layoutTabNav;
  String get layoutSideNav => _l10n.layoutSideNav;
  String get layoutExpandable => _l10n.layoutExpandable;

  // Header options (Dialog / Bottom Sheet entry points).
  String get headerOptions => _l10n.headerOptions;
  String get leadingOption => _l10n.leadingOption;
  String get trailingOption => _l10n.trailingOption;
  String get centerTitleOption => _l10n.centerTitleOption;

  // Phone screen titles & labels. ("SelectView" is a widget name.)
  String get phoneViewTitle => 'SelectView';
  String get phonePopupBarTitle => _l10n.phonePopupBarTitle;
  String get phonePopupButtonTitle => _l10n.phonePopupButtonTitle;
  String get phoneDialogTitle => _l10n.phoneDialogTitle;
  String get phoneBottomSheetTitle => _l10n.phoneBottomSheetTitle;

  String get tapBarHint => _l10n.tapBarHint;
  String get openSelect => _l10n.openSelect;

  // Per-delegate open buttons (Dialog / Bottom Sheet entry points).
  String get openListSelect => _l10n.openListSelect;
  String get openGridSelect => _l10n.openGridSelect;
  String get openWrapSelect => _l10n.openWrapSelect;
  String get openCascadingSelect => _l10n.openCascadingSelect;
  String get openTabNavSelect => _l10n.openTabNavSelect;
  String get openSideNavSelect => _l10n.openSideNavSelect;
  String get openExpandableSelect => _l10n.openExpandableSelect;

  // Per-delegate titles for the Dialog / Bottom Sheet selects.
  String get titleListSelect => _l10n.titleListSelect;
  String get titleGridSelect => _l10n.titleGridSelect;
  String get titleWrapSelect => _l10n.titleWrapSelect;
  String get titleCascadingSelect => _l10n.titleCascadingSelect;
  String get titleTabNavSelect => _l10n.titleTabNavSelect;
  String get titleSideNavSelect => _l10n.titleSideNavSelect;
  String get titleExpandableSelect => _l10n.titleExpandableSelect;

  // Callback result panel.
  String get resultPanelTitle => _l10n.resultPanelTitle;
  String get onChangedLabel => 'onChanged';
  String get onAppliedLabel => 'onApplied';
}
