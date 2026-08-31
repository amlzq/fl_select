// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Select サンプル';

  @override
  String get themeMode => 'テーマ';

  @override
  String get themeSystem => 'システムに従う';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get languageTooltip => '言語';

  @override
  String get entryPoint => '入口';

  @override
  String get delegateLabel => 'デリゲート';

  @override
  String get selectionMode => '選択モード';

  @override
  String get tileVariant => 'タイルスタイル';

  @override
  String get seedColor => 'シードカラー';

  @override
  String columns(int value) {
    return '列数（$value）';
  }

  @override
  String aspectRatio(String value) {
    return 'アスペクト比（$value）';
  }

  @override
  String spacing(int value) {
    return '間隔（$value）';
  }

  @override
  String get single => '単一';

  @override
  String get multiple => '複数';

  @override
  String get filled => '塗りつぶし';

  @override
  String get outlined => '枠線';

  @override
  String get brightness => '明暗';

  @override
  String get follow => 'アプリに従う';

  @override
  String get light => '明るい';

  @override
  String get dark => '暗い';

  @override
  String get layoutList => 'リスト';

  @override
  String get layoutGrid => 'グリッド';

  @override
  String get layoutWrap => '折り返し';

  @override
  String get layoutCascading => 'カスケード';

  @override
  String get layoutTabNav => 'タブナビ';

  @override
  String get layoutSideNav => 'サイドナビ';

  @override
  String get layoutExpandable => '展開';

  @override
  String get headerOptions => 'ヘッダーオプション';

  @override
  String get leadingOption => '先頭ウィジェット';

  @override
  String get trailingOption => '末尾ウィジェット';

  @override
  String get centerTitleOption => 'タイトル中央寄せ';

  @override
  String get phonePopupBarTitle => 'ポップアップバー';

  @override
  String get phonePopupButtonTitle => 'ポップアップボタン';

  @override
  String get phoneDialogTitle => 'ダイアログ';

  @override
  String get phoneBottomSheetTitle => 'ボトムシート';

  @override
  String get tapBarHint => 'バーをタップしてセレクターを開く';

  @override
  String get openSelect => 'セレクターを開く';

  @override
  String get openListSelect => 'リストセレクターを開く';

  @override
  String get openGridSelect => 'グリッドセレクターを開く';

  @override
  String get openWrapSelect => '折り返しセレクターを開く';

  @override
  String get openCascadingSelect => 'カスケードセレクターを開く';

  @override
  String get openTabNavSelect => 'タブナビセレクターを開く';

  @override
  String get openSideNavSelect => 'サイドナビセレクターを開く';

  @override
  String get openExpandableSelect => '展開セレクターを開く';

  @override
  String get titleListSelect => 'リストセレクター';

  @override
  String get titleGridSelect => 'グリッドセレクター';

  @override
  String get titleWrapSelect => '折り返しセレクター';

  @override
  String get titleCascadingSelect => 'カスケードセレクター';

  @override
  String get titleTabNavSelect => 'タブナビセレクター';

  @override
  String get titleSideNavSelect => 'サイドナビセレクター';

  @override
  String get titleExpandableSelect => '展開セレクター';

  @override
  String get resultPanelTitle => 'コールバック結果';

  @override
  String get shareTooltip => 'リンクをコピー';

  @override
  String get linkCopied => 'リンクをクリップボードにコピーしました';
}
