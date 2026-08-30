// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Exemplo de Select';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get languageTooltip => 'Idioma';

  @override
  String get entryPoint => 'Ponto de entrada';

  @override
  String get delegateLabel => 'Delegado';

  @override
  String get selectionMode => 'Modo de seleção';

  @override
  String get tileVariant => 'Variante de peça';

  @override
  String get seedColor => 'Cor base';

  @override
  String columns(int value) {
    return 'Colunas ($value)';
  }

  @override
  String aspectRatio(String value) {
    return 'Proporção de aspecto ($value)';
  }

  @override
  String spacing(int value) {
    return 'Espaçamento ($value)';
  }

  @override
  String get single => 'Único';

  @override
  String get multiple => 'Múltiplo';

  @override
  String get filled => 'Preenchido';

  @override
  String get outlined => 'Contornado';

  @override
  String get brightness => 'Brilho';

  @override
  String get follow => 'Seguir o app';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get layoutList => 'Lista';

  @override
  String get layoutGrid => 'Grade';

  @override
  String get layoutWrap => 'Quebra';

  @override
  String get layoutCascading => 'Cascata';

  @override
  String get layoutTabNav => 'Navegação por abas';

  @override
  String get layoutSideNav => 'Navegação lateral';

  @override
  String get layoutExpandable => 'Expansível';

  @override
  String get headerOptions => 'Opções de cabeçalho';

  @override
  String get leadingOption => 'Componente inicial';

  @override
  String get trailingOption => 'Componente final';

  @override
  String get centerTitleOption => 'Centralizar título';

  @override
  String get phonePopupBarTitle => 'Barra popup';

  @override
  String get phonePopupButtonTitle => 'Botão popup';

  @override
  String get phoneDialogTitle => 'Diálogo';

  @override
  String get phoneBottomSheetTitle => 'Painel inferior';

  @override
  String get tapBarHint => 'Toque na barra para abrir o seletor';

  @override
  String get openSelect => 'Abrir seletor';

  @override
  String get openListSelect => 'Abrir seletor de lista';

  @override
  String get openGridSelect => 'Abrir seletor de grade';

  @override
  String get openWrapSelect => 'Abrir seletor de quebra';

  @override
  String get openCascadingSelect => 'Abrir seletor em cascata';

  @override
  String get openTabNavSelect => 'Abrir seletor de navegação por abas';

  @override
  String get openSideNavSelect => 'Abrir seletor de navegação lateral';

  @override
  String get openExpandableSelect => 'Abrir seletor expansível';

  @override
  String get titleListSelect => 'Seletor de lista';

  @override
  String get titleGridSelect => 'Seletor de grade';

  @override
  String get titleWrapSelect => 'Seletor de quebra';

  @override
  String get titleCascadingSelect => 'Seletor em cascata';

  @override
  String get titleTabNavSelect => 'Seletor de navegação por abas';

  @override
  String get titleSideNavSelect => 'Seletor de navegação lateral';

  @override
  String get titleExpandableSelect => 'Seletor expansível';

  @override
  String get resultPanelTitle => 'Resultados de callbacks';
}
