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
  };
}

SelectEntries get gridData {
  return {
    SelectRangeEntry.custom(),
    SelectTextEntry.name(id: 'a', name: '0-100'),
    SelectTextEntry.name(id: 'b', name: '100-500'),
    SelectTextEntry.name(id: 'c', name: '500-1000'),
    SelectTextEntry.name(id: 'd', name: '1000-2000'),
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
  };
}

SelectEntries get multiCategoryData {
  return {
    SelectCategoryEntry.children(
      id: 'cate1',
      name: 'Cate 1',
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
        },
      ),
      footerSelectionMode: SelectionMode.single,
      layout: const SelectListLayout(),
    ),
    SelectCategoryEntry.children(
      id: 'cate2',
      name: 'Cate 2',
      header: SelectTextEntry.children(
        id: 'c2-h',
        name: 'Letter Grade',
        children: {
          SelectTextEntry.name(id: 'h-a', name: 'A'),
          SelectTextEntry.name(id: 'h-b', name: 'B'),
          SelectTextEntry.name(id: 'h-c', name: 'C'),
          SelectTextEntry.name(id: 'h-d', name: 'D'),
        },
      ),
      headerSelectionMode: SelectionMode.single,
      children: {
        SelectTextEntry.name(id: 'a', name: 'Mathematics'),
        SelectTextEntry.name(id: 'b', name: 'Language'),
        SelectTextEntry.name(id: 'c', name: 'Science'),
        SelectTextEntry.name(id: 'd', name: 'History'),
      },
      selectionMode: SelectionMode.single,
    ),
    SelectCategoryEntry.children(
      id: 'cate3',
      name: 'Cate 3',
      children: {
        SelectTextEntry.name(id: 'a', name: '0-100'),
        SelectTextEntry.name(id: 'b', name: '100-500'),
        SelectTextEntry.name(id: 'c', name: '500-1000'),
        SelectTextEntry.name(id: 'd', name: '1000-2000'),
        SelectRangeEntry.custom(),
      },
      layout: SelectGridLayout(
        crossAxisCount: 3,
        childAspectRatio: 3.2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
    ),
    SelectCategoryEntry.children(
      id: 'cate4',
      name: 'Cate 4',
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
        SelectTextEntry.name(id: 'o', name: 'Horse'),
        SelectTextEntry.name(id: 'p', name: 'Sheep'),
        SelectTextEntry.name(id: 'q', name: 'Cow'),
      },
      selectionMode: SelectionMode.single,
      layout: SelectWrapLayout(),
    ),
    SelectCategoryEntry.children(
      id: 'cate5',
      name: 'Cate 5',
      children: {
        SelectRangeEntry(
          id: 'a',
          name: '\$0-\$2000000',
          min: 0,
          max: 2000000,
          divisions: 80,
        ),
        SelectRangeEntry.custom(),
      },
      layout: const SelectRangeLayout(),
    ),
    SelectCategoryEntry.children(
      id: 'cate6',
      name: 'Cate 6',
      children: {
        SelectTextEntry.name(id: 'a', name: '1'),
        SelectTextEntry.name(id: 'b', name: '2'),
        SelectTextEntry.name(id: 'c', name: '3'),
        SelectTextEntry.name(id: 'd', name: '4'),
        SelectTextEntry.name(id: 'e', name: '5'),
      },
      layout: const SelectCounterLayout(),
    ),
  };
}
