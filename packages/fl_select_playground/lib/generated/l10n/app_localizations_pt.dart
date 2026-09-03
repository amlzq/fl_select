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
  String columnSpacing(int value) {
    return 'Espaço entre colunas ($value)';
  }

  @override
  String rowSpacing(int value) {
    return 'Espaço entre linhas ($value)';
  }

  @override
  String runSpacing(int value) {
    return 'Espaço entre quebras ($value)';
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
  String get elevated => 'Elevado';

  @override
  String get text => 'Texto';

  @override
  String get scrollable => 'Rolável';

  @override
  String get searchEnabled => 'Pesquisa';

  @override
  String get direction => 'Direção';

  @override
  String get directionBelow => 'Abaixo';

  @override
  String get directionAbove => 'Acima';

  @override
  String get directionAdaptive => 'Adaptável';

  @override
  String get buttonVariant => 'Variante do botão';

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
  String get listSelect => 'Seletor de lista';

  @override
  String get gridSelect => 'Seletor de grade';

  @override
  String get wrapSelect => 'Seletor de quebra';

  @override
  String get cascadingSelect => 'Seletor em cascata';

  @override
  String get tabNavSelect => 'Seletor de navegação por abas';

  @override
  String get sideNavSelect => 'Seletor de navegação lateral';

  @override
  String get expandableSelect => 'Seletor expansível';

  @override
  String get resultPanelExpand => 'Expandir';

  @override
  String get resultPanelCollapse => 'Recolher';

  @override
  String get resultPanelTitle => 'Resultados de callbacks';

  @override
  String get shareTooltip => 'Copiar link';

  @override
  String get linkCopied => 'Link copiado para a área de transferência';
}
