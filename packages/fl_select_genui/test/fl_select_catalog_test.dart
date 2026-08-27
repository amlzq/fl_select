import 'dart:convert';

import 'package:fl_select/fl_select.dart';
import 'package:fl_select_genui/src/catalog/fl_select_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  test('schema + exampleData + catalog merge', () {
    final item = FlSelectCatalogItems.selectFilter;
    expect(item.name, 'SelectFilter');
    expect(item.dataSchema.required, containsAll(['delegate', 'entries']));

    for (final example in item.exampleData) {
      final json = jsonDecode(example()) as Map<String, dynamic>;
      final entries = SelectEntryCodec.fromJson(json['entries'] as List);
      expect(entries.first, isA<SelectCategoryEntry>());
    }

    final merged = const Catalog(
      <CatalogItem>[],
      catalogId: 'base',
    ).copyWith(newItems: FlSelectCatalogItems.all);
    expect(merged.items.length, 1);
  });
}
