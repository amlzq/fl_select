import 'dart:convert';

import 'package:fl_select/fl_select.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<String> loadJsonData(String fileName) async {
  return await rootBundle.loadString('assets/$fileName');
}

Future<SelectEntries> fetchCascadingData() async {
  // simulate network delay
  await Future.delayed(const Duration(milliseconds: 350));
  final cascading = cascadingFromJson(
    await loadJsonData('cascading.json'),
  );
  debugPrint('cascading length: ${cascading.length}');
  SelectEntries entries = cascading
      .map(
        (category) => SelectCategoryEntry(
          id: category.id!,
          name: category.name!,
          children: category.data
              ?.map(
                (l1) => SelectTextEntry(
                  parentId: category.id!,
                  id: l1.id!,
                  name: l1.name!,
                  enabled: l1.enabled ?? true,
                  children: l1.data
                      ?.map(
                        (l2) => SelectTextEntry(
                          parentId: l1.id!,
                          id: l2.id!,
                          name: l2.name!,
                          enabled: l2.enabled ?? true,
                        ),
                      )
                      .toSet(),
                ),
              )
              .toSet(),
          selectionMode: SelectionMode.multiple,
        ),
      )
      .toSet();

  // insert any entry
  for (SelectEntry category in entries) {
    category.children?.insert(
      0,
      SelectTextEntry.any(
        parentId: category.id,
        name: 'Any',
        immediate: true,
      ),
    );
  }

  debugPrint('cascading length: ${entries.length}');
  return Future.value(entries);
}

List<CascadingData> cascadingFromJson(String str) => List<CascadingData>.from(
      json.decode(str).map((x) => CascadingData.fromJson(x)),
    );

String cascadingToJson(List<CascadingData> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CascadingData {
  String? id;
  String? name;
  bool? enabled;
  List<CascadingData>? data;

  CascadingData({this.id, this.name, this.data});

  CascadingData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    enabled = json['enabled'];
    if (json['data'] != null) {
      data = <CascadingData>[];
      json['data'].forEach((v) {
        data!.add(CascadingData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['id'] = id;
    json['name'] = name;
    json['enabled'] = enabled;
    if (data != null) {
      json['data'] = data!.map((v) => v.toJson()).toList();
    }
    return json;
  }
}

SelectEntries get listData {
  return {
    SelectTextEntry.name(id: 'a', name: 'Kiwi'),
    SelectTextEntry.name(id: 'b', name: 'Grape'),
    SelectTextEntry.name(id: 'c', name: 'Strawberry'),
    SelectTextEntry.name(id: 'd', name: 'Pineapple'),
    SelectTextEntry.name(id: 'e', name: 'Orange'),
    SelectTextEntry.name(id: 'f', name: 'Banana'),
    SelectTextEntry.name(id: 'g', name: 'Pine'),
    SelectTextEntry.name(id: 'h', name: 'Mango'),
    SelectTextEntry.name(id: 'i', name: 'Pear'),
    SelectTextEntry.name(id: 'j', name: 'Peach'),
    SelectTextEntry.name(id: 'k', name: 'Cherry'),
    SelectTextEntry.name(id: 'l', name: 'Lemon'),
    SelectTextEntry.name(id: 'm', name: 'Lime'),
    SelectTextEntry.name(id: 'n', name: 'Grapefruit'),
  };
}

SelectEntries get gridData {
  return {
    SelectIntEntry.custom(),
    SelectIntEntry(
      id: 'a',
      name: '\$0-\$25',
      min: 0,
      max: 25,
    ),
    SelectIntEntry(
      id: 'b',
      name: '\$25-\$50',
      min: 25,
      max: 50,
    ),
    SelectIntEntry(
      id: 'c',
      name: '\$50-\$100',
      min: 50,
      max: 100,
    ),
    SelectIntEntry(
      id: 'd',
      name: '\$100-\$250',
      min: 100,
      max: 250,
    ),
    SelectIntEntry(
      id: 'e',
      name: '\$250-\$500',
      min: 250,
      max: 500,
    ),
    SelectIntEntry(
      id: 'f',
      name: '\$500-\$1000',
      min: 500,
      max: 1000,
    ),
  };
}

SelectEntries get wrapData {
  return {
    SelectTextEntry.name(id: 'a', name: 'Tiger'),
    SelectTextEntry.name(id: 'b', name: 'Lion'),
    SelectTextEntry.name(id: 'c', name: 'Bear'),
    SelectTextEntry.name(id: 'd', name: 'Elephant'),
    SelectTextEntry.name(id: 'e', name: 'Monkey'),
    SelectTextEntry.name(id: 'f', name: 'Dog'),
    SelectTextEntry.name(id: 'g', name: 'Cat'),
    SelectTextEntry.name(id: 'h', name: 'Pig'),
    SelectTextEntry.name(id: 'i', name: 'Horse'),
    SelectTextEntry.name(id: 'j', name: 'Sheep'),
    SelectTextEntry.name(id: 'k', name: 'Cow'),
    SelectTextEntry.name(id: 'l', name: 'Chicken'),
    SelectTextEntry.name(id: 'm', name: 'Duck'),
    SelectTextEntry.name(id: 'n', name: 'Penguin'),
  };
}

SelectEntries get multiCategoryData {
  return {
    SelectCategoryEntry.children(
      id: 'cate1',
      name: 'Sport',
      children: {
        SelectTextEntry.name(id: 'a', name: 'Football'),
        SelectTextEntry.name(id: 'b', name: 'Basketball'),
        SelectTextEntry.name(id: 'c', name: 'Baseball'),
        SelectTextEntry.name(id: 'd', name: 'Tennis'),
      },
      selectionMode: SelectionMode.single,
      footer: SelectTextEntry.children(
        id: 'c1-f',
        name: 'Letter Grade',
        children: {
          SelectTextEntry.name(id: 'f-a', name: 'A'),
          SelectTextEntry.name(id: 'f-b', name: 'B'),
          SelectTextEntry.name(id: 'f-c', name: 'C'),
          SelectTextEntry.name(id: 'f-d', name: 'D'),
          SelectTextEntry.name(id: 'f-d', name: 'E'),
        },
      ),
      footerSelectionMode: SelectionMode.single,
    ),
    SelectCategoryEntry.children(
      id: 'cate2',
      name: 'Cuisine',
      header: SelectTextEntry.children(
        id: 'c2-h',
        name: 'Letter Grade',
        children: {
          SelectTextEntry.name(id: 'h-a', name: '1'),
          SelectTextEntry.name(id: 'h-b', name: '2'),
          SelectTextEntry.name(id: 'h-c', name: '3'),
          SelectTextEntry.name(id: 'h-d', name: '4'),
          SelectTextEntry.name(id: 'h-d', name: '5'),
        },
      ),
      headerSelectionMode: SelectionMode.single,
      children: {
        SelectTextEntry.name(id: 'a', name: 'Chinese'),
        SelectTextEntry.name(id: 'b', name: 'French'),
        SelectTextEntry.name(id: 'c', name: 'Indian'),
        SelectTextEntry.name(id: 'd', name: 'Turkish'),
      },
      selectionMode: SelectionMode.single,
    ),
    SelectCategoryEntry.children(
      id: 'cate3',
      name: 'Storage (GB)',
      children: {
        SelectIntEntry.custom(),
        SelectRangeEntry(id: '0-64', name: '0-64', min: 0, max: 64),
        SelectRangeEntry(id: '64-128', name: '64-128', min: 64, max: 128),
        SelectRangeEntry(id: '128-256', name: '128-256', min: 128, max: 256),
        SelectRangeEntry(id: '256-512', name: '256-512', min: 256, max: 512),
        SelectRangeEntry(
          id: '512-1024',
          name: '512-1024',
          min: 512,
          max: 1024,
        ),
        SelectRangeEntry(
          id: '1024-2048',
          name: '1024-2048',
          min: 1024,
          max: 2048,
        ),
      },
      selectionMode: SelectionMode.single,
    ),
    SelectCategoryEntry.children(
      id: 'cate4',
      name: 'Animal',
      children: {
        SelectTextEntry.name(id: 'a', name: 'Tiger'),
        SelectTextEntry.name(id: 'b', name: 'Lion'),
        SelectTextEntry.name(id: 'c', name: 'Bear'),
        SelectTextEntry.name(id: 'd', name: 'Elephant'),
        SelectTextEntry.name(id: 'e', name: 'Monkey'),
        SelectTextEntry.name(id: 'f', name: 'Dog'),
        SelectTextEntry.name(id: 'g', name: 'Cat'),
        SelectTextEntry.name(id: 'h', name: 'Pig'),
        SelectTextEntry.name(id: 'i', name: 'Horse'),
        SelectTextEntry.name(id: 'j', name: 'Sheep'),
        SelectTextEntry.name(id: 'k', name: 'Cow'),
        SelectTextEntry.name(id: 'l', name: 'Chicken'),
        SelectTextEntry.name(id: 'm', name: 'Duck'),
        SelectTextEntry.name(id: 'n', name: 'Pig'),
      },
    ),
    SelectCategoryEntry.children(
      id: 'cate5',
      name: 'Price (Dollar)',
      children: {
        SelectRangeEntry(
          id: 'a',
          name: '0-2000000',
          min: 0,
          max: 2000000,
          divisions: 80,
        ),
        SelectRangeEntry.custom(),
      },
      selectionMode: SelectionMode.single,
      layout: const SelectRangeLayout(),
    ),
    SelectCategoryEntry.children(
      id: 'cate6',
      name: 'Counter',
      children: {
        SelectTextEntry.any(parentId: 'cate6', name: 'Any'),
        SelectTextEntry.name(id: 'a', name: '1'),
        SelectTextEntry.name(id: 'b', name: '2'),
        SelectTextEntry.name(id: 'c', name: '3'),
        SelectTextEntry.name(id: 'd', name: '4'),
        SelectTextEntry.name(id: 'e', name: '5'),
        SelectTextEntry.name(id: 'e', name: '5+'),
      },
      selectionMode: SelectionMode.single,
      layout: const SelectCounterLayout(),
    ),
  };
}
