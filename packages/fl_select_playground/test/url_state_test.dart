import 'package:fl_select/fl_select.dart';
import 'package:fl_select_playground/playground_l10n.dart';
import 'package:fl_select_playground/playground_params.dart';
import 'package:fl_select_playground/url_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fallback = const PlaygroundUrlState(
    params: kDefaultPlaygroundParams,
    language: PlaygroundLanguage.english,
    themeMode: ThemeMode.system,
  );

  test('default state encodes to an empty query', () {
    expect(PlaygroundUrlCodec.toQuery(fallback), isEmpty);
  });

  test('encode -> decode round-trips every field', () {
    final state = PlaygroundUrlState(
      params: const PlaygroundParams(
        entryPoint: EntryPoint.bottomSheet,
        delegate: Delegate.grid,
        selectionMode: SelectionMode.single,
        crossAxisCount: 3,
        childAspectRatio: 1.75,
        crossAxisSpacing: 6.5,
        mainAxisSpacing: 10,
        spacing: 12.5,
        runSpacing: 4,
        cascadingScrollable: true,
        tileVariant: TileVariant.outlined,
        seedColor: Color(0xFF1565C0),
        useMaterial3: false,
        isScrollable: false,
        direction: PopupSelectDirection.adaptive,
        buttonVariant: PopupSelectButtonVariant.elevated,
        searchEnabled: false,
        headerLeading: true,
        headerTrailing: true,
        centerTitle: false,
        brightness: Brightness.dark,
      ),
      language: PlaygroundLanguage.traditionalChineseTw,
      themeMode: ThemeMode.light,
    );

    final query = PlaygroundUrlCodec.toQuery(state);
    final decoded = PlaygroundUrlCodec.decode(query, fallback: fallback);

    expect(decoded.params.entryPoint, EntryPoint.bottomSheet);
    expect(decoded.params.delegate, Delegate.grid);
    expect(decoded.params.selectionMode, SelectionMode.single);
    expect(decoded.params.crossAxisCount, 3);
    expect(decoded.params.childAspectRatio, 1.75);
    expect(decoded.params.crossAxisSpacing, 6.5);
    expect(decoded.params.mainAxisSpacing, 10);
    expect(decoded.params.spacing, 12.5);
    expect(decoded.params.runSpacing, 4);
    expect(decoded.params.cascadingScrollable, isTrue);
    expect(decoded.params.tileVariant, TileVariant.outlined);
    expect(decoded.params.seedColor, const Color(0xFF1565C0));
    expect(decoded.params.useMaterial3, isFalse);
    expect(decoded.params.isScrollable, isFalse);
    expect(decoded.params.direction, PopupSelectDirection.adaptive);
    expect(decoded.params.buttonVariant, PopupSelectButtonVariant.elevated);
    expect(decoded.params.searchEnabled, isFalse);
    expect(decoded.params.headerLeading, isTrue);
    expect(decoded.params.headerTrailing, isTrue);
    expect(decoded.params.centerTitle, isFalse);
    expect(decoded.params.brightness, Brightness.dark);
    expect(decoded.language, PlaygroundLanguage.traditionalChineseTw);
    expect(decoded.themeMode, ThemeMode.light);
  });

  test('malformed / unknown values fall back to the defaults', () {
    final decoded = PlaygroundUrlCodec.decode(const <String, String>{
      'ep': 'nope',
      'dg': 'zz',
      'cc': '999',
      'ar': 'not-a-number',
      'cs': '999',
      'ms': 'not-a-number',
      'sp': '-50',
      'rs': '-50',
      'tv': 'zz',
      'sb': 'maybe',
      'csb': 'maybe',
      'se': 'maybe',
      'dr': 'nope',
      'bv': 'nope',
      'sc': 'xyz',
      'm3': 'maybe',
      'bm': 'x',
      'lg': 'xx',
      'tm': 'q',
    }, fallback: fallback);

    expect(decoded.params.entryPoint, EntryPoint.bar);
    expect(decoded.params.delegate, Delegate.cascading);
    expect(decoded.params.crossAxisCount, 12); // clamped
    expect(decoded.params.childAspectRatio, 2.5);
    expect(decoded.params.crossAxisSpacing, 64); // clamped
    expect(decoded.params.mainAxisSpacing, 8);
    expect(decoded.params.spacing, 0); // clamped
    expect(decoded.params.runSpacing, 0); // clamped
    expect(decoded.params.tileVariant, TileVariant.filled);
    expect(decoded.params.seedColor, Colors.deepPurple);
    expect(decoded.params.useMaterial3, isTrue);
    expect(decoded.params.isScrollable, isTrue);
    expect(decoded.params.cascadingScrollable, isTrue);
    expect(decoded.params.searchEnabled, isTrue);
    expect(decoded.params.direction, PopupSelectDirection.below);
    expect(decoded.params.buttonVariant, PopupSelectButtonVariant.text);
    expect(decoded.params.brightness, isNull);
    expect(decoded.language, PlaygroundLanguage.english);
    expect(decoded.themeMode, ThemeMode.system);
  });

  test('buildUri yields a clean base URL for an empty query', () {
    final uri = PlaygroundUrlCodec.buildUri(
      Uri.parse('https://flselect.zeaon.dev/'),
      const <String, String>{},
    );
    expect(uri.toString(), 'https://flselect.zeaon.dev/');

    final withQuery = PlaygroundUrlCodec.buildUri(
      Uri.parse('https://flselect.zeaon.dev/'),
      const <String, String>{'ep': 'd', 'dg': 't'},
    );
    expect(withQuery.toString(), 'https://flselect.zeaon.dev/?ep=d&dg=t');
  });
}
