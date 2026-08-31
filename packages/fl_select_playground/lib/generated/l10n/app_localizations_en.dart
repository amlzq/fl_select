// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Select Example';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageTooltip => 'Language';

  @override
  String get entryPoint => 'Entry Point';

  @override
  String get delegateLabel => 'Delegate';

  @override
  String get selectionMode => 'Selection Mode';

  @override
  String get tileVariant => 'Tile Variant';

  @override
  String get seedColor => 'Seed Color';

  @override
  String columns(int value) {
    return 'Columns ($value)';
  }

  @override
  String aspectRatio(String value) {
    return 'Aspect Ratio ($value)';
  }

  @override
  String spacing(int value) {
    return 'Spacing ($value)';
  }

  @override
  String get single => 'Single';

  @override
  String get multiple => 'Multiple';

  @override
  String get filled => 'Filled';

  @override
  String get outlined => 'Outlined';

  @override
  String get brightness => 'Brightness';

  @override
  String get follow => 'Follow App';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get layoutList => 'List';

  @override
  String get layoutGrid => 'Grid';

  @override
  String get layoutWrap => 'Wrap';

  @override
  String get layoutCascading => 'Cascading';

  @override
  String get layoutTabNav => 'Tab Nav';

  @override
  String get layoutSideNav => 'Side Nav';

  @override
  String get layoutExpandable => 'Expandable';

  @override
  String get headerOptions => 'Header Options';

  @override
  String get leadingOption => 'Leading';

  @override
  String get trailingOption => 'Trailing';

  @override
  String get centerTitleOption => 'Center Title';

  @override
  String get phonePopupBarTitle => 'Popup Bar';

  @override
  String get phonePopupButtonTitle => 'Popup Button';

  @override
  String get phoneDialogTitle => 'Dialog';

  @override
  String get phoneBottomSheetTitle => 'Bottom Sheet';

  @override
  String get tapBarHint => 'Tap the bar to open the select';

  @override
  String get openSelect => 'Open Select';

  @override
  String get openListSelect => 'Open List Select';

  @override
  String get openGridSelect => 'Open Grid Select';

  @override
  String get openWrapSelect => 'Open Wrap Select';

  @override
  String get openCascadingSelect => 'Open Cascading Select';

  @override
  String get openTabNavSelect => 'Open Tab Nav Select';

  @override
  String get openSideNavSelect => 'Open Side Nav Select';

  @override
  String get openExpandableSelect => 'Open Expandable Select';

  @override
  String get titleListSelect => 'List Select';

  @override
  String get titleGridSelect => 'Grid Select';

  @override
  String get titleWrapSelect => 'Wrap Select';

  @override
  String get titleCascadingSelect => 'Cascading Select';

  @override
  String get titleTabNavSelect => 'Tab Nav Select';

  @override
  String get titleSideNavSelect => 'Side Nav Select';

  @override
  String get titleExpandableSelect => 'Expandable Select';

  @override
  String get resultPanelTitle => 'Callback results';

  @override
  String get shareTooltip => 'Copy link';

  @override
  String get linkCopied => 'Link copied to clipboard';
}
