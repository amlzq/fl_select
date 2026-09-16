import 'package:flutter/material.dart';

/// Localized business strings for the `fl_select` package.
///
/// Resolves the best-matching language pack for a given [Locale] and exposes
/// the UI labels (e.g. "Apply" / "Reset" / "Multiple") used by the select
/// widgets. Obtain the instance for the current [BuildContext] via
/// [SelectLocalizations.of].
class SelectLocalizations {
  final Locale locale;

  SelectLocalizations(this.locale);

  static SelectLocalizations? of(BuildContext context) {
    return Localizations.of<SelectLocalizations>(context, SelectLocalizations);
  }

  // Dynamically compute the best-matching language pack for the current context.
  Map<String, String> get _currentValues {
    final keys = [
      // 1. Highest priority: Full match (e.g., zh_Hans_CN or zh_Hant_TW)
      if (locale.scriptCode != null && locale.countryCode != null)
        '${locale.languageCode}_${locale.scriptCode}_${locale.countryCode}',

      // 2. Second highest priority: Language + Script (e.g., zh_Hans or zh_Hant)
      if (locale.scriptCode != null)
        '${locale.languageCode}_${locale.scriptCode}',

      // 3. Medium priority: Language + Region (e.g., zh_CN or zh_TW)
      if (locale.countryCode != null)
        '${locale.languageCode}_${locale.countryCode}',

      // 4. Low priority: Language only (e.g., zh or en)
      locale.languageCode,
    ];

    // Iterate through the priority list to find the first matching language pack.
    for (final key in keys) {
      if (_localizedValues.containsKey(key)) {
        return _localizedValues[key]!;
      }
    }

    // 5. Final fallback: Default to English if no match is found.
    return _localizedValues['en']!;
  }

  // Business strings are retrieved directly from the computed _currentValues.
  String get reset => _currentValues['reset'] ?? 'Reset';
  String get apply => _currentValues['apply'] ?? 'Apply';
  String get multiple => _currentValues['multiple'] ?? 'Multiple';
  String get search => _currentValues['search'] ?? 'Search';
  String get noResults => _currentValues['noResults'] ?? 'No results';
  String get decrease => _currentValues['decrease'] ?? 'Decrease';
  String get increase => _currentValues['increase'] ?? 'Increase';
  String error(Object error) => '${_currentValues['error'] ?? 'Error'}: $error';

  // Accessibility strings
  String get panelOpened =>
      _currentValues['panelOpened'] ?? 'Select panel opened';
  String get panelClosed =>
      _currentValues['panelClosed'] ?? 'Select panel closed';
  String get cleared => _currentValues['cleared'] ?? 'Cleared';
  String applied(int count) =>
      '${_currentValues['applied'] ?? 'Applied'}, $count selected';
  String get clearSearch => _currentValues['clearSearch'] ?? 'Clear search';

  // Extended language resource dictionary
  static const Map<String, Map<String, String>> _localizedValues = {
    'de': {
      'reset': 'Zurücksetzen',
      'apply': 'Anwenden',
      'multiple': 'Mehrfach',
      'search': 'Suchen',
      'noResults': 'Keine Ergebnisse',
      'error': 'Fehler',
      'decrease': 'Verringern',
      'increase': 'Erhöhen',
      'panelOpened': 'Auswahlbereich geöffnet',
      'panelClosed': 'Auswahlbereich geschlossen',
      'cleared': 'Gelöscht',
      'applied': 'Angewendet',
      'clearSearch': 'Suche löschen',
    },
    'en': {
      'reset': 'Reset',
      'apply': 'Apply',
      'multiple': 'Multiple',
      'search': 'Search',
      'noResults': 'No results',
      'error': 'Error',
      'decrease': 'Decrease',
      'increase': 'Increase',
      'panelOpened': 'Select panel opened',
      'panelClosed': 'Select panel closed',
      'cleared': 'Cleared',
      'applied': 'Applied',
      'clearSearch': 'Clear search',
    },
    'es': {
      'reset': 'Restablecer',
      'apply': 'Aplicar',
      'multiple': 'Multiple',
      'search': 'Buscar',
      'noResults': 'Sin resultados',
      'error': 'Error',
      'decrease': 'Reducir',
      'increase': 'Aumentar',
      'panelOpened': 'Panel de selección abierto',
      'panelClosed': 'Panel de selección cerrado',
      'cleared': 'Borrado',
      'applied': 'Aplicado',
      'clearSearch': 'Borrar búsqueda',
    },
    'fr': {
      'reset': 'Réinitialiser',
      'apply': 'Appliquer',
      'multiple': 'Multiple',
      'search': 'Rechercher',
      'noResults': 'Aucun résultat',
      'error': 'Erreur',
      'decrease': 'Diminuer',
      'increase': 'Augmenter',
      'panelOpened': 'Panneau de sélection ouvert',
      'panelClosed': 'Panneau de sélection fermé',
      'cleared': 'Effacé',
      'applied': 'Appliqué',
      'clearSearch': 'Effacer la recherche',
    },
    'id': {
      'reset': 'Atur Ulang',
      'apply': 'Terapkan',
      'multiple': 'Multi',
      'search': 'Cari',
      'noResults': 'Tidak ada hasil',
      'error': 'Kesalahan',
      'decrease': 'Kurangi',
      'increase': 'Tambah',
      'panelOpened': 'Panel seleksi dibuka',
      'panelClosed': 'Panel seleksi ditutup',
      'cleared': 'Dihapus',
      'applied': 'Diterapkan',
      'clearSearch': 'Hapus pencarian',
    },
    'ja': {
      'reset': 'リセット',
      'apply': '適用',
      'multiple': '複数',
      'search': '検索',
      'noResults': '結果なし',
      'error': 'エラー',
      'decrease': '減らす',
      'increase': '増やす',
      'panelOpened': '選択パネルが開きました',
      'panelClosed': '選択パネルが閉じました',
      'cleared': 'クリアされました',
      'applied': '適用されました',
      'clearSearch': '検索をクリア',
    },
    'ko': {
      'reset': '초기화',
      'apply': '적용',
      'multiple': '다중',
      'search': '검색',
      'noResults': '결과 없음',
      'error': '오류',
      'decrease': '감소',
      'increase': '증가',
      'panelOpened': '선택 패널이 열렸습니다',
      'panelClosed': '선택 패널이 닫혔습니다',
      'cleared': '지워졌습니다',
      'applied': '적용되었습니다',
      'clearSearch': '검색 지우기',
    },
    'pt': {
      'reset': 'Redefinir',
      'apply': 'Aplicar',
      'multiple': 'Múltipla',
      'search': 'Pesquisar',
      'noResults': 'Sem resultados',
      'error': 'Erro',
      'decrease': 'Diminuir',
      'increase': 'Aumentar',
      'panelOpened': 'Painel de seleção aberto',
      'panelClosed': 'Painel de seleção fechado',
      'cleared': 'Limpo',
      'applied': 'Aplicado',
      'clearSearch': 'Limpar pesquisa',
    },
    'vi': {
      'reset': 'Đặt lại',
      'apply': 'Áp dụng',
      'multiple': 'Nhiều lựa chọn',
      'search': 'Tìm kiếm',
      'noResults': 'Không có kết quả',
      'error': 'Lỗi',
      'decrease': 'Giảm',
      'increase': 'Tăng',
      'panelOpened': 'Bảng chọn đã mở',
      'panelClosed': 'Bảng chọn đã đóng',
      'cleared': 'Đã xóa',
      'applied': 'Đã áp dụng',
      'clearSearch': 'Xóa tìm kiếm',
    },
    'zh_Hans': {
      'reset': '重置',
      'apply': '应用',
      'multiple': '多选',
      'search': '搜索',
      'noResults': '暂无结果',
      'error': '错误',
      'decrease': '减少',
      'increase': '增加',
      'panelOpened': '选择面板已打开',
      'panelClosed': '选择面板已关闭',
      'cleared': '已清除',
      'applied': '已应用',
      'clearSearch': '清除搜索',
    },
    'zh_Hant': {
      'reset': '重置',
      'apply': '應用',
      'multiple': '多選',
      'search': '搜尋',
      'noResults': '暫無結果',
      'error': '錯誤',
      'decrease': '減少',
      'increase': '增加',
      'panelOpened': '選擇面板已打開',
      'panelClosed': '選擇面板已關閉',
      'cleared': '已清除',
      'applied': '已應用',
      'clearSearch': '清除搜尋',
    },
    'zh_Hant_HK': {
      'reset': '重設',
      'apply': '立即搜尋',
      'multiple': '多選',
      'search': '搜尋',
      'noResults': '暫無結果',
      'error': '錯誤',
      'decrease': '減少',
      'increase': '增加',
      'panelOpened': '選擇面板已打開',
      'panelClosed': '選擇面板已關閉',
      'cleared': '已清除',
      'applied': '已應用',
      'clearSearch': '清除搜尋',
    },
    'zh_Hant_TW': {
      'reset': '重設',
      'apply': '套用',
      'multiple': '多選',
      'search': '搜尋',
      'noResults': '沒有結果',
      'error': '錯誤',
      'decrease': '減少',
      'increase': '增加',
      'panelOpened': '選擇面板已打開',
      'panelClosed': '選擇面板已關閉',
      'cleared': '已清除',
      'applied': '已套用',
      'clearSearch': '清除搜尋',
    },
  };
}
