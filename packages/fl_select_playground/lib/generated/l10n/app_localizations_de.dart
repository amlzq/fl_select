// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Select-Beispiel';

  @override
  String get themeMode => 'Design';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get languageTooltip => 'Sprache';

  @override
  String get entryPoint => 'Einstiegspunkt';

  @override
  String get delegateLabel => 'Delegate';

  @override
  String get selectionMode => 'Auswahlmodus';

  @override
  String get tileVariant => 'Kachelvariante';

  @override
  String get seedColor => 'Grundfarbe';

  @override
  String columns(int value) {
    return 'Spalten ($value)';
  }

  @override
  String aspectRatio(String value) {
    return 'Seitenverhältnis ($value)';
  }

  @override
  String spacing(int value) {
    return 'Abstand ($value)';
  }

  @override
  String columnSpacing(int value) {
    return 'Spaltenabstand ($value)';
  }

  @override
  String rowSpacing(int value) {
    return 'Zeilenabstand ($value)';
  }

  @override
  String runSpacing(int value) {
    return 'Umbruchabstand ($value)';
  }

  @override
  String get single => 'Einzeln';

  @override
  String get multiple => 'Mehrfach';

  @override
  String get filled => 'Gefüllt';

  @override
  String get outlined => 'Umrandet';

  @override
  String get elevated => 'Erhaben';

  @override
  String get text => 'Text';

  @override
  String get scrollable => 'Scrollbar';

  @override
  String get searchEnabled => 'Suche';

  @override
  String get direction => 'Richtung';

  @override
  String get directionBelow => 'Nach unten';

  @override
  String get directionAbove => 'Nach oben';

  @override
  String get directionAdaptive => 'Automatisch';

  @override
  String get buttonVariant => 'Schaltflächenvariante';

  @override
  String get brightness => 'Helligkeit';

  @override
  String get follow => 'App folgen';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get layoutList => 'Liste';

  @override
  String get layoutGrid => 'Raster';

  @override
  String get layoutWrap => 'Umbruch';

  @override
  String get layoutCascading => 'Kaskadierend';

  @override
  String get layoutTabNav => 'Tab-Navigation';

  @override
  String get layoutSideNav => 'Seiten-Navigation';

  @override
  String get layoutExpandable => 'Aufklappbar';

  @override
  String get headerOptions => 'Kopfzeilenoptionen';

  @override
  String get leadingOption => 'Vorderes Element';

  @override
  String get trailingOption => 'Hinteres Element';

  @override
  String get centerTitleOption => 'Titel zentrieren';

  @override
  String get phonePopupBarTitle => 'Popup-Leiste';

  @override
  String get phonePopupButtonTitle => 'Popup-Schaltfläche';

  @override
  String get phoneDialogTitle => 'Dialog';

  @override
  String get phoneBottomSheetTitle => 'Bottom-Sheet';

  @override
  String get tapBarHint =>
      'Tippen Sie auf die Leiste, um die Auswahl zu öffnen';

  @override
  String get openSelect => 'Auswahl öffnen';

  @override
  String get listSelect => 'Listenauswahl';

  @override
  String get gridSelect => 'Rasterauswahl';

  @override
  String get wrapSelect => 'Umbruchauswahl';

  @override
  String get cascadingSelect => 'Kaskadierende Auswahl';

  @override
  String get tabNavSelect => 'Tab-Navigationsauswahl';

  @override
  String get sideNavSelect => 'Seiten-Navigationsauswahl';

  @override
  String get expandableSelect => 'Aufklappbare Auswahl';

  @override
  String get resultPanelExpand => 'Ausklappen';

  @override
  String get resultPanelCollapse => 'Einklappen';

  @override
  String get resultPanelTitle => 'Callback-Ergebnisse';

  @override
  String get shareTooltip => 'Link kopieren';

  @override
  String get linkCopied => 'Link wurde in die Zwischenablage kopiert';
}
