import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import 'playground_l10n.dart';
import 'playground_params.dart';

/// Baseline the URL query is diffed against: only fields that differ from
/// these values are encoded, so the default configuration maps to the bare
/// URL with no query string.
const PlaygroundParams kDefaultPlaygroundParams = PlaygroundParams(
  entryPoint: EntryPoint.bar,
  delegate: Delegate.cascading,
  selectionMode: SelectionMode.multiple,
  crossAxisCount: 4,
  childAspectRatio: 2.5,
  crossAxisSpacing: 8,
  mainAxisSpacing: 8,
  spacing: 8,
  runSpacing: 8,
  cascadingScrollable: true,
  tileVariant: TileVariant.filled,
  seedColor: Colors.deepPurple,
  useMaterial3: true,
  isScrollable: true,
  direction: PopupSelectDirection.below,
  buttonVariant: PopupSelectButtonVariant.text,
  searchEnabled: true,
);

/// The complete restorable state of the playground: demo parameters, UI
/// language and theme mode.
class PlaygroundUrlState {
  final PlaygroundParams params;

  final PlaygroundLanguage language;

  final ThemeMode themeMode;

  const PlaygroundUrlState({
    required this.params,
    required this.language,
    required this.themeMode,
  });
}

/// Encodes the playground state into URL query parameters and decodes it
/// back, so a copied link reproduces the exact configuration — the basis for
/// shareable bug reports.
///
/// Only fields that differ from the defaults ([kDefaultPlaygroundParams],
/// English, system theme mode) are written, keeping URLs short. Decoding
/// falls back to the defaults for any missing, unknown or malformed value,
/// so links stay valid across playground updates that rename or remove
/// options.
abstract final class PlaygroundUrlCodec {
  const PlaygroundUrlCodec._();

  // ---- Short code tables (compact keys keep the URL readable). ----

  static const Map<EntryPoint, String> _entryPointCodes = <EntryPoint, String>{
    EntryPoint.view: 'v',
    // `pb` / `pn` are historical codes (popupBar / popupButton); kept so
    // shared links stay valid after the entry points were renamed to
    // `bar` / `button`.
    EntryPoint.bar: 'pb',
    EntryPoint.button: 'pn',
    EntryPoint.dialog: 'd',
    EntryPoint.bottomSheet: 'b',
  };

  static const Map<Delegate, String> _delegateCodes = <Delegate, String>{
    Delegate.list: 'l',
    Delegate.grid: 'g',
    Delegate.wrap: 'w',
    Delegate.cascading: 'c',
    Delegate.tabNav: 't',
    Delegate.sideNav: 's',
    Delegate.expandable: 'e',
  };

  static const Map<SelectionMode, String> _selectionModeCodes =
      <SelectionMode, String>{
        SelectionMode.single: 's',
        SelectionMode.multiple: 'm',
      };

  static const Map<TileVariant, String> _tileVariantCodes =
      <TileVariant, String>{TileVariant.filled: 'f', TileVariant.outlined: 'o'};

  static const Map<PopupSelectDirection, String> _directionCodes =
      <PopupSelectDirection, String>{
        PopupSelectDirection.below: 'b',
        PopupSelectDirection.above: 'a',
        PopupSelectDirection.adaptive: 'ad',
      };

  static const Map<PopupSelectButtonVariant, String> _buttonVariantCodes =
      <PopupSelectButtonVariant, String>{
        PopupSelectButtonVariant.elevated: 'e',
        PopupSelectButtonVariant.filled: 'f',
        PopupSelectButtonVariant.outlined: 'o',
        PopupSelectButtonVariant.text: 't',
      };

  static const Map<PlaygroundLanguage, String> _languageCodes =
      <PlaygroundLanguage, String>{
        PlaygroundLanguage.english: 'en',
        PlaygroundLanguage.german: 'de',
        PlaygroundLanguage.spanish: 'es',
        PlaygroundLanguage.french: 'fr',
        PlaygroundLanguage.indonesian: 'id',
        PlaygroundLanguage.japanese: 'ja',
        PlaygroundLanguage.korean: 'ko',
        PlaygroundLanguage.portuguese: 'pt',
        PlaygroundLanguage.vietnamese: 'vi',
        PlaygroundLanguage.simplifiedChinese: 'zh-Hans',
        PlaygroundLanguage.traditionalChinese: 'zh-Hant',
        PlaygroundLanguage.traditionalChineseHk: 'zh-HK',
        PlaygroundLanguage.traditionalChineseTw: 'zh-TW',
      };

  static const Map<ThemeMode, String> _themeModeCodes = <ThemeMode, String>{
    ThemeMode.system: 's',
    ThemeMode.light: 'l',
    ThemeMode.dark: 'd',
  };

  /// Encodes [state] into query parameters, omitting default-valued fields.
  static Map<String, String> toQuery(PlaygroundUrlState state) {
    final p = state.params;
    final d = kDefaultPlaygroundParams;
    final q = <String, String>{};

    if (p.entryPoint != d.entryPoint) q['ep'] = _entryPointCodes[p.entryPoint]!;
    if (p.delegate != d.delegate) q['dg'] = _delegateCodes[p.delegate]!;
    if (p.selectionMode != d.selectionMode) {
      q['sm'] = _selectionModeCodes[p.selectionMode]!;
    }
    if (p.crossAxisCount != d.crossAxisCount) {
      q['cc'] = '${p.crossAxisCount}';
    }
    if (p.childAspectRatio != d.childAspectRatio) {
      q['ar'] = _formatDouble(p.childAspectRatio);
    }
    if (p.crossAxisSpacing != d.crossAxisSpacing) {
      q['cs'] = _formatDouble(p.crossAxisSpacing);
    }
    if (p.mainAxisSpacing != d.mainAxisSpacing) {
      q['ms'] = _formatDouble(p.mainAxisSpacing);
    }
    if (p.spacing != d.spacing) q['sp'] = _formatDouble(p.spacing);
    if (p.runSpacing != d.runSpacing) q['rs'] = _formatDouble(p.runSpacing);
    if (p.tileVariant != d.tileVariant) {
      q['tv'] = _tileVariantCodes[p.tileVariant]!;
    }
    if (p.seedColor.toARGB32() != d.seedColor.toARGB32()) {
      // Opaque seed color: encode the 24-bit RGB hex without alpha.
      q['sc'] = (p.seedColor.toARGB32() & 0xFFFFFF)
          .toRadixString(16)
          .padLeft(6, '0');
    }
    if (p.useMaterial3 != d.useMaterial3) q['m3'] = p.useMaterial3 ? '1' : '0';
    if (p.isScrollable != d.isScrollable) {
      q['sb'] = p.isScrollable ? '1' : '0';
    }
    if (p.cascadingScrollable != d.cascadingScrollable) {
      q['csb'] = p.cascadingScrollable ? '1' : '0';
    }
    if (p.direction != d.direction) q['dr'] = _directionCodes[p.direction]!;
    if (p.buttonVariant != d.buttonVariant) {
      q['bv'] = _buttonVariantCodes[p.buttonVariant]!;
    }
    if (p.searchEnabled != d.searchEnabled) {
      q['se'] = p.searchEnabled ? '1' : '0';
    }
    if (p.headerLeading != d.headerLeading) {
      q['hl'] = p.headerLeading ? '1' : '0';
    }
    if (p.headerTrailing != d.headerTrailing) {
      q['ht'] = p.headerTrailing ? '1' : '0';
    }
    if (p.centerTitle != d.centerTitle) {
      q['ct'] = p.centerTitle ? '1' : '0';
    }
    if (p.brightness != d.brightness) {
      q['bm'] = p.brightness == Brightness.dark ? 'd' : 'l';
    }
    if (state.language != PlaygroundLanguage.english) {
      q['lg'] = _languageCodes[state.language]!;
    }
    if (state.themeMode != ThemeMode.system) {
      q['tm'] = _themeModeCodes[state.themeMode]!;
    }
    return q;
  }

  /// Decodes query parameters (e.g. from `Uri.base.queryParameters`) back
  /// into a [PlaygroundUrlState], falling back to [fallback] field by field
  /// for anything missing or invalid.
  static PlaygroundUrlState decode(
    Map<String, String> query, {
    required PlaygroundUrlState fallback,
  }) {
    final f = fallback.params;
    return PlaygroundUrlState(
      params: PlaygroundParams(
        entryPoint: _decode(_entryPointCodes, query['ep'], f.entryPoint),
        delegate: _decode(_delegateCodes, query['dg'], f.delegate),
        selectionMode: _decode(
          _selectionModeCodes,
          query['sm'],
          f.selectionMode,
        ),
        crossAxisCount: _clamp(
          int.tryParse(query['cc'] ?? ''),
          1,
          12,
          f.crossAxisCount,
        ),
        childAspectRatio: _clamp(
          double.tryParse(query['ar'] ?? ''),
          0.1,
          20,
          f.childAspectRatio,
        ),
        crossAxisSpacing: _clamp(
          double.tryParse(query['cs'] ?? ''),
          0,
          64,
          f.crossAxisSpacing,
        ),
        mainAxisSpacing: _clamp(
          double.tryParse(query['ms'] ?? ''),
          0,
          64,
          f.mainAxisSpacing,
        ),
        spacing: _clamp(double.tryParse(query['sp'] ?? ''), 0, 64, f.spacing),
        runSpacing: _clamp(
          double.tryParse(query['rs'] ?? ''),
          0,
          64,
          f.runSpacing,
        ),
        tileVariant: _decode(_tileVariantCodes, query['tv'], f.tileVariant),
        seedColor: _decodeColor(query['sc']) ?? f.seedColor,
        useMaterial3: _decodeBool(query['m3']) ?? f.useMaterial3,
        isScrollable: _decodeBool(query['sb']) ?? f.isScrollable,
        cascadingScrollable: _decodeBool(query['csb']) ?? f.cascadingScrollable,
        direction: _decode(_directionCodes, query['dr'], f.direction),
        buttonVariant: _decode(
          _buttonVariantCodes,
          query['bv'],
          f.buttonVariant,
        ),
        searchEnabled: _decodeBool(query['se']) ?? f.searchEnabled,
        headerLeading: _decodeBool(query['hl']) ?? f.headerLeading,
        headerTrailing: _decodeBool(query['ht']) ?? f.headerTrailing,
        centerTitle: _decodeBool(query['ct']) ?? f.centerTitle,
        brightness: switch (query['bm']) {
          'l' => Brightness.light,
          'd' => Brightness.dark,
          _ => f.brightness,
        },
      ),
      language: _decode(_languageCodes, query['lg'], fallback.language),
      themeMode: _decode(_themeModeCodes, query['tm'], fallback.themeMode),
    );
  }

  /// Rebuilds [base] with [query] as its query string. An empty [query]
  /// yields a clean URI with no trailing `?`.
  static Uri buildUri(Uri base, Map<String, String> query) {
    // A null port is omitted from the URI; an explicit 0 would render ":0".
    var uri = Uri(
      scheme: base.scheme,
      host: base.host,
      path: base.path.isEmpty ? '/' : base.path,
      queryParameters: query.isEmpty ? null : query,
    );
    if (base.hasPort) {
      uri = uri.replace(port: base.port);
    }
    return uri;
  }

  // ---- Helpers ----

  /// Looks up the enum value whose code equals [code]; [fallback] when the
  /// key is absent or unknown.
  static K _decode<K, V>(Map<K, V> codes, V? code, K fallback) {
    if (code == null) return fallback;
    for (final entry in codes.entries) {
      if (entry.value == code) return entry.key;
    }
    return fallback;
  }

  static bool? _decodeBool(String? code) => switch (code) {
    '1' => true,
    '0' => false,
    _ => null,
  };

  /// Parses a 6-digit RGB hex string (as produced by [toQuery]).
  static Color? _decodeColor(String? hex) {
    final v = hex == null ? null : int.tryParse(hex, radix: 16);
    return v == null ? null : Color(v | 0xFF000000);
  }

  /// Clamps a parsed number into a sane range so a tampered link cannot
  /// produce a degenerate layout (zero columns, huge gutters, ...).
  static T _clamp<T extends num>(T? value, T min, T max, T fallback) {
    if (value == null || value.isNaN) return fallback;
    return value.clamp(min, max) as T;
  }

  /// Drops the trailing `.0` of whole doubles (`2.5` stays `2.5`, `4.0`
  /// becomes `4`).
  static String _formatDouble(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
}
