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
  String get realEstate => 'Real Estate';

  @override
  String get leyoujia => 'Leyoujia';

  @override
  String get buy => 'Buy';

  @override
  String get sell => 'For sale';

  @override
  String get rent => 'Rent';

  @override
  String get onMap => 'On Map';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get clear => 'Clear all';

  @override
  String get done => 'Done';

  @override
  String get zillow => 'Zillow';

  @override
  String get region => 'Region';

  @override
  String get neighborhood => 'Neighborhood';

  @override
  String get price => 'Price';

  @override
  String get floorPlan => 'Layout';

  @override
  String get rooms => 'Rooms';

  @override
  String get more => 'More';

  @override
  String get selectUpdated => 'Selection updated';

  @override
  String get view => 'View';

  @override
  String selectResult(Object result) {
    return 'Result: $result';
  }

  @override
  String get resultParseFailed => 'Failed to parse result';

  @override
  String get viewing => 'Loading...';

  @override
  String loadError(Object error) {
    return 'Error: $error';
  }

  @override
  String get any => 'Any';

  @override
  String get custom => 'Custom';

  @override
  String get minHint => 'Min';

  @override
  String get maxHint => 'Max';

  @override
  String get noMin => 'No min';

  @override
  String get noMax => 'No max';

  @override
  String get customArea => 'Custom area';

  @override
  String get userCityName => 'Shenzhen';

  @override
  String viewhomes(Object count) {
    return 'View $count homes';
  }

  @override
  String get nohomes => 'No homes';

  @override
  String get noMore => 'No more';

  @override
  String get loading => 'Loading...';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';
}
