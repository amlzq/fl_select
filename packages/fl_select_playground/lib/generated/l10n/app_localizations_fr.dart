// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Exemple Select';

  @override
  String get themeMode => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get languageTooltip => 'Langue';

  @override
  String get entryPoint => 'Point d\'entrée';

  @override
  String get delegateLabel => 'Délégué';

  @override
  String get selectionMode => 'Mode de sélection';

  @override
  String get tileVariant => 'Variante de tuile';

  @override
  String get seedColor => 'Couleur de base';

  @override
  String columns(int value) {
    return 'Colonnes ($value)';
  }

  @override
  String aspectRatio(String value) {
    return 'Rapport d\'aspect ($value)';
  }

  @override
  String spacing(int value) {
    return 'Espacement ($value)';
  }

  @override
  String columnSpacing(int value) {
    return 'Espacement des colonnes ($value)';
  }

  @override
  String rowSpacing(int value) {
    return 'Espacement des lignes ($value)';
  }

  @override
  String runSpacing(int value) {
    return 'Espacement des retours à la ligne ($value)';
  }

  @override
  String get single => 'Unique';

  @override
  String get multiple => 'Multiple';

  @override
  String get filled => 'Rempli';

  @override
  String get outlined => 'Contour';

  @override
  String get elevated => 'En relief';

  @override
  String get text => 'Texte';

  @override
  String get scrollable => 'Défilable';

  @override
  String get searchEnabled => 'Recherche';

  @override
  String get direction => 'Direction';

  @override
  String get directionBelow => 'Vers le bas';

  @override
  String get directionAbove => 'Vers le haut';

  @override
  String get directionAdaptive => 'Adaptatif';

  @override
  String get buttonVariant => 'Variante de bouton';

  @override
  String get brightness => 'Luminosité';

  @override
  String get follow => 'Suivre l\'appli';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get layoutList => 'Liste';

  @override
  String get layoutGrid => 'Grille';

  @override
  String get layoutWrap => 'Flux';

  @override
  String get layoutCascading => 'Cascade';

  @override
  String get layoutTabNav => 'Navigation par onglets';

  @override
  String get layoutSideNav => 'Navigation latérale';

  @override
  String get layoutExpandable => 'Dépliable';

  @override
  String get headerOptions => 'Options d\'en-tête';

  @override
  String get leadingOption => 'Élément initial';

  @override
  String get trailingOption => 'Élément final';

  @override
  String get centerTitleOption => 'Titre centré';

  @override
  String get phonePopupBarTitle => 'Barre popup';

  @override
  String get phonePopupButtonTitle => 'Bouton popup';

  @override
  String get phoneDialogTitle => 'Dialogue';

  @override
  String get phoneBottomSheetTitle => 'Feuille inférieure';

  @override
  String get tapBarHint => 'Touchez la barre pour ouvrir le sélecteur';

  @override
  String get openSelect => 'Ouvrir le sélecteur';

  @override
  String get listSelect => 'Sélecteur de liste';

  @override
  String get gridSelect => 'Sélecteur de grille';

  @override
  String get wrapSelect => 'Sélecteur de flux';

  @override
  String get cascadingSelect => 'Sélecteur en cascade';

  @override
  String get tabNavSelect => 'Sélecteur à onglets';

  @override
  String get sideNavSelect => 'Sélecteur latéral';

  @override
  String get expandableSelect => 'Sélecteur dépliable';

  @override
  String get resultPanelExpand => 'Déplier';

  @override
  String get resultPanelCollapse => 'Replier';

  @override
  String get resultPanelTitle => 'Résultats des callbacks';

  @override
  String get shareTooltip => 'Copier le lien';

  @override
  String get linkCopied => 'Lien copié dans le presse-papiers';
}
