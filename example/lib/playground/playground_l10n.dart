import 'package:flutter/widgets.dart';

/// Supported languages for the playground. Each maps to a demo data set:
/// English uses the Zillow data, Simplified Chinese uses the Leyoujia data.
enum PlaygroundLanguage {
  english,
  simplifiedChinese,
}

extension PlaygroundLanguageX on PlaygroundLanguage {
  /// The [Locale] injected via [Localizations.override] so the
  /// select's built-in strings (reset / confirm, etc.) follow the language.
  Locale get locale {
    switch (this) {
      case PlaygroundLanguage.english:
        return const Locale('en');
      case PlaygroundLanguage.simplifiedChinese:
        return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    }
  }

  /// Short label shown in the language switcher.
  String get label {
    switch (this) {
      case PlaygroundLanguage.english:
        return 'English';
      case PlaygroundLanguage.simplifiedChinese:
        return '简体中文';
    }
  }
}

/// Self-contained localization for the playground UI (English + Simplified
/// Chinese). Kept independent of the app-wide [AppLocalizations] so the
/// playground can switch its own language without affecting the rest of the app.
class PlaygroundL10n {
  final PlaygroundLanguage language;

  const PlaygroundL10n(this.language);

  bool get _zh => language == PlaygroundLanguage.simplifiedChinese;

  String _t(String en, String zh) => _zh ? zh : en;

  // App bar.
  String get title => 'Playground';
  String get languageTooltip => _t('Language', '语言');

  // Section titles.
  String get entryPoint => _t('Entry Point', '入口');
  String get delegate => _t('Delegate', '代理');
  String get selectionMode => _t('Selection Mode', '选择模式');
  String get tileVariant => _t('Tile Variant', '磁贴样式');
  String get seedColor => _t('Seed Color', '主题色');

  String columns(int value) => _t('Columns ($value)', '列数（$value）');
  String aspectRatio(String value) =>
      _t('Aspect Ratio ($value)', '宽高比（$value）');
  String spacing(int value) => _t('Spacing ($value)', '间距（$value）');

  // Selection mode segments.
  String get single => _t('Single', '单选');
  String get multiple => _t('Multiple', '多选');

  // Tile variant segments.
  String get filled => _t('Filled', '填充');
  String get outlined => _t('Outlined', '描边');

  // Material 3 switch.
  String get material3 => 'Material 3';

  // Brightness segments.
  String get brightness => _t('Brightness', '明暗');
  String get follow => _t('Follow App', '跟随应用');
  String get light => _t('Light', '浅色');
  String get dark => _t('Dark', '深色');

  // Delegate options.
  String get layoutCascading => _t('Cascading', '联动');
  String get layoutGrid => _t('Grid', '网格');
  String get layoutFlatten => _t('Flatten', '平铺');
  String get layoutList => _t('List', '列表');

  // Phone screen titles & labels.
  String get phoneViewTitle => 'SelectView';
  String get phonePopupBarTitle => _t('Popup Bar', '弹出选择栏');
  String get phonePopupButtonTitle => _t('Popup Button', '弹出选择按钮');
  String get phoneDialogTitle => _t('Dialog', '对话框');
  String get phoneBottomSheetTitle => _t('Bottom Sheet', '底部弹层');

  String get tapBarHint => _t('Tap the bar to open the select', '点击顶栏打开选择器');
  String get openSelect => _t('Open Select', '打开选择器');

  // Per-delegate open buttons (Dialog / Bottom Sheet entry points).
  String get openCascadingSelect => _t('Open Cascading Select', '打开联动选择器');
  String get openGridSelect => _t('Open Grid Select', '打开网格选择器');
  String get openFlattenSelect => _t('Open Flatten Select', '打开平铺选择器');
  String get openListSelect => _t('Open List Select', '打开列表选择器');

  // Per-delegate titles for the Dialog / Bottom Sheet selects.
  String get titleCascadingSelect => _t('Cascading Select', '联动选择器');
  String get titleGridSelect => _t('Grid Select', '网格选择器');
  String get titleFlattenSelect => _t('Flatten Select', '平铺选择器');
  String get titleListSelect => _t('List Select', '列表选择器');

  // Callback result panel.
  String get resultPanelTitle => _t('Callback results', '回调结果');
  String get onChangedLabel => 'onChanged';
  String get onAppliedLabel => 'onApplied';
}
