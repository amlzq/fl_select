import 'package:flutter/material.dart';

import 'select_localizations.dart';

/// The [LocalizationsDelegate] for [SelectLocalizations].
///
/// Add a const instance to your app's `localizationsDelegates` to enable the
/// built-in translations for the select widgets. It ships translations for
/// `de`, `en`, `es`, `fr`, `id`, `ja`, `ko`, `pt`, `vi`, and `zh`
/// (Hans/Hant), localizing the "Apply" / "Reset" / "Multiple" labels
/// automatically.
class SelectLocalizationsDelegate
    extends LocalizationsDelegate<SelectLocalizations> {
  const SelectLocalizationsDelegate();

  static const supportedLanguageCodes = <String>{
    'de',
    'en',
    'es',
    'fr',
    'id',
    'ja',
    'ko',
    'pt',
    'vi',
    'zh',
  };

  static const supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('vi'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale.fromSubtags(
        languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
    Locale.fromSubtags(
        languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
  ];

  @override
  bool isSupported(Locale locale) {
    // As long as the primary language code is supported,
    // it will automatically perform granular matching internally based on scriptCode and countryCode.
    return supportedLanguageCodes.contains(locale.languageCode);
  }

  @override
  Future<SelectLocalizations> load(Locale locale) async {
    return SelectLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<SelectLocalizations> old) {
    return false;
  }
}
