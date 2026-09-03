// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Ejemplo de Select';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get languageTooltip => 'Idioma';

  @override
  String get entryPoint => 'Punto de entrada';

  @override
  String get delegateLabel => 'Delegado';

  @override
  String get selectionMode => 'Modo de selección';

  @override
  String get tileVariant => 'Variante de mosaico';

  @override
  String get seedColor => 'Color base';

  @override
  String columns(int value) {
    return 'Columnas ($value)';
  }

  @override
  String aspectRatio(String value) {
    return 'Relación de aspecto ($value)';
  }

  @override
  String spacing(int value) {
    return 'Espaciado ($value)';
  }

  @override
  String columnSpacing(int value) {
    return 'Espacio entre columnas ($value)';
  }

  @override
  String rowSpacing(int value) {
    return 'Espacio entre filas ($value)';
  }

  @override
  String runSpacing(int value) {
    return 'Espacio entre líneas ($value)';
  }

  @override
  String get single => 'Único';

  @override
  String get multiple => 'Múltiple';

  @override
  String get filled => 'Relleno';

  @override
  String get outlined => 'Contorneado';

  @override
  String get elevated => 'Elevado';

  @override
  String get text => 'Texto';

  @override
  String get scrollable => 'Desplazable';

  @override
  String get searchEnabled => 'Búsqueda';

  @override
  String get direction => 'Dirección';

  @override
  String get directionBelow => 'Abajo';

  @override
  String get directionAbove => 'Arriba';

  @override
  String get directionAdaptive => 'Adaptativo';

  @override
  String get buttonVariant => 'Variante de botón';

  @override
  String get brightness => 'Brillo';

  @override
  String get follow => 'Según la app';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get layoutList => 'Lista';

  @override
  String get layoutGrid => 'Cuadrícula';

  @override
  String get layoutWrap => 'Ajuste';

  @override
  String get layoutCascading => 'Cascada';

  @override
  String get layoutTabNav => 'Navegación por pestañas';

  @override
  String get layoutSideNav => 'Navegación lateral';

  @override
  String get layoutExpandable => 'Desplegable';

  @override
  String get headerOptions => 'Opciones de encabezado';

  @override
  String get leadingOption => 'Elemento inicial';

  @override
  String get trailingOption => 'Elemento final';

  @override
  String get centerTitleOption => 'Centrar título';

  @override
  String get phonePopupBarTitle => 'Barra emergente';

  @override
  String get phonePopupButtonTitle => 'Botón emergente';

  @override
  String get phoneDialogTitle => 'Diálogo';

  @override
  String get phoneBottomSheetTitle => 'Hoja inferior';

  @override
  String get tapBarHint => 'Toca la barra para abrir el selector';

  @override
  String get openSelect => 'Abrir selector';

  @override
  String get listSelect => 'Selector de lista';

  @override
  String get gridSelect => 'Selector de cuadrícula';

  @override
  String get wrapSelect => 'Selector de ajuste';

  @override
  String get cascadingSelect => 'Selector en cascada';

  @override
  String get tabNavSelect => 'Selector de navegación por pestañas';

  @override
  String get sideNavSelect => 'Selector de navegación lateral';

  @override
  String get expandableSelect => 'Selector desplegable';

  @override
  String get resultPanelExpand => 'Expandir';

  @override
  String get resultPanelCollapse => 'Contraer';

  @override
  String get resultPanelTitle => 'Resultados de callbacks';

  @override
  String get shareTooltip => 'Copiar enlace';

  @override
  String get linkCopied => 'Enlace copiado al portapapeles';
}
