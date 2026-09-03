import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
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
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'HK',
      scriptCode: 'Hant',
    ),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'TW',
      scriptCode: 'Hant',
    ),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Select Example'**
  String get appName;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTooltip;

  /// No description provided for @entryPoint.
  ///
  /// In en, this message translates to:
  /// **'Entry Point'**
  String get entryPoint;

  /// No description provided for @delegateLabel.
  ///
  /// In en, this message translates to:
  /// **'Delegate'**
  String get delegateLabel;

  /// No description provided for @selectionMode.
  ///
  /// In en, this message translates to:
  /// **'Selection Mode'**
  String get selectionMode;

  /// No description provided for @tileVariant.
  ///
  /// In en, this message translates to:
  /// **'Tile Variant'**
  String get tileVariant;

  /// No description provided for @seedColor.
  ///
  /// In en, this message translates to:
  /// **'Seed Color'**
  String get seedColor;

  /// No description provided for @columns.
  ///
  /// In en, this message translates to:
  /// **'Columns ({value})'**
  String columns(int value);

  /// No description provided for @aspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Aspect Ratio ({value})'**
  String aspectRatio(String value);

  /// No description provided for @spacing.
  ///
  /// In en, this message translates to:
  /// **'Spacing ({value})'**
  String spacing(int value);

  /// No description provided for @columnSpacing.
  ///
  /// In en, this message translates to:
  /// **'Column Spacing ({value})'**
  String columnSpacing(int value);

  /// No description provided for @rowSpacing.
  ///
  /// In en, this message translates to:
  /// **'Row Spacing ({value})'**
  String rowSpacing(int value);

  /// No description provided for @runSpacing.
  ///
  /// In en, this message translates to:
  /// **'Run Spacing ({value})'**
  String runSpacing(int value);

  /// No description provided for @single.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get single;

  /// No description provided for @multiple.
  ///
  /// In en, this message translates to:
  /// **'Multiple'**
  String get multiple;

  /// No description provided for @filled.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get filled;

  /// No description provided for @outlined.
  ///
  /// In en, this message translates to:
  /// **'Outlined'**
  String get outlined;

  /// No description provided for @elevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated'**
  String get elevated;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @scrollable.
  ///
  /// In en, this message translates to:
  /// **'Scrollable'**
  String get scrollable;

  /// No description provided for @searchEnabled.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchEnabled;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get direction;

  /// No description provided for @directionBelow.
  ///
  /// In en, this message translates to:
  /// **'Below'**
  String get directionBelow;

  /// No description provided for @directionAbove.
  ///
  /// In en, this message translates to:
  /// **'Above'**
  String get directionAbove;

  /// No description provided for @directionAdaptive.
  ///
  /// In en, this message translates to:
  /// **'Adaptive'**
  String get directionAdaptive;

  /// No description provided for @buttonVariant.
  ///
  /// In en, this message translates to:
  /// **'Button Variant'**
  String get buttonVariant;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow App'**
  String get follow;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @layoutList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get layoutList;

  /// No description provided for @layoutGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get layoutGrid;

  /// No description provided for @layoutWrap.
  ///
  /// In en, this message translates to:
  /// **'Wrap'**
  String get layoutWrap;

  /// No description provided for @layoutCascading.
  ///
  /// In en, this message translates to:
  /// **'Cascading'**
  String get layoutCascading;

  /// No description provided for @layoutTabNav.
  ///
  /// In en, this message translates to:
  /// **'Tab Nav'**
  String get layoutTabNav;

  /// No description provided for @layoutSideNav.
  ///
  /// In en, this message translates to:
  /// **'Side Nav'**
  String get layoutSideNav;

  /// No description provided for @layoutExpandable.
  ///
  /// In en, this message translates to:
  /// **'Expandable'**
  String get layoutExpandable;

  /// No description provided for @headerOptions.
  ///
  /// In en, this message translates to:
  /// **'Header Options'**
  String get headerOptions;

  /// No description provided for @leadingOption.
  ///
  /// In en, this message translates to:
  /// **'Leading'**
  String get leadingOption;

  /// No description provided for @trailingOption.
  ///
  /// In en, this message translates to:
  /// **'Trailing'**
  String get trailingOption;

  /// No description provided for @centerTitleOption.
  ///
  /// In en, this message translates to:
  /// **'Center Title'**
  String get centerTitleOption;

  /// No description provided for @phonePopupBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Popup Bar'**
  String get phonePopupBarTitle;

  /// No description provided for @phonePopupButtonTitle.
  ///
  /// In en, this message translates to:
  /// **'Popup Button'**
  String get phonePopupButtonTitle;

  /// No description provided for @phoneDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Dialog'**
  String get phoneDialogTitle;

  /// No description provided for @phoneBottomSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Bottom Sheet'**
  String get phoneBottomSheetTitle;

  /// No description provided for @tapBarHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the bar to open the select'**
  String get tapBarHint;

  /// No description provided for @openSelect.
  ///
  /// In en, this message translates to:
  /// **'Open Select'**
  String get openSelect;

  /// No description provided for @listSelect.
  ///
  /// In en, this message translates to:
  /// **'List Select'**
  String get listSelect;

  /// No description provided for @gridSelect.
  ///
  /// In en, this message translates to:
  /// **'Grid Select'**
  String get gridSelect;

  /// No description provided for @wrapSelect.
  ///
  /// In en, this message translates to:
  /// **'Wrap Select'**
  String get wrapSelect;

  /// No description provided for @cascadingSelect.
  ///
  /// In en, this message translates to:
  /// **'Cascading Select'**
  String get cascadingSelect;

  /// No description provided for @tabNavSelect.
  ///
  /// In en, this message translates to:
  /// **'Tab Nav Select'**
  String get tabNavSelect;

  /// No description provided for @sideNavSelect.
  ///
  /// In en, this message translates to:
  /// **'Side Nav Select'**
  String get sideNavSelect;

  /// No description provided for @expandableSelect.
  ///
  /// In en, this message translates to:
  /// **'Expandable Select'**
  String get expandableSelect;

  /// No description provided for @resultPanelExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get resultPanelExpand;

  /// No description provided for @resultPanelCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get resultPanelCollapse;

  /// No description provided for @resultPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Callback results'**
  String get resultPanelTitle;

  /// No description provided for @shareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get shareTooltip;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
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
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script+country codes are specified.
  switch (locale.toString()) {
    case 'zh_Hant_HK':
      return AppLocalizationsZhHantHk();
    case 'zh_Hant_TW':
      return AppLocalizationsZhHantTw();
  }

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
