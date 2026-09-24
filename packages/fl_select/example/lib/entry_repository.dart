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
  final cascading = cascadingFromJson(await loadJsonData('cascading.json'));
  debugPrint('cascading length: ${cascading.length}');
  SelectEntries entries = cascading
      .map(
        (category) => SelectCategoryEntry(
          id: category.id!,
          name: category.name!,
          children: category.data
              ?.map(
                (l1) => SelectTextEntry(
                  id: l1.id!,
                  name: l1.name!,
                  enabled: l1.enabled ?? true,
                  children: l1.data
                      ?.map(
                        (l2) => SelectTextEntry(
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
      SelectTextEntry.any(name: 'Any', immediate: true),
    );
  }

  final residentialEntry =
      entries.firstWhere((e) => e.id == 'residential') as SelectCategoryEntry;
  residentialEntry.header = SelectTextEntry(
    id: 'h',
    name: 'Header',
    children: {
      // SelectIntEntry.custom(name: ''),
      SelectTextEntry(id: 'h-a', name: '1'),
      SelectTextEntry(id: 'h-b', name: '2'),
      SelectTextEntry(id: 'h-c', name: '3'),
      SelectTextEntry(id: 'h-d', name: '4'),
      SelectTextEntry(id: 'h-e', name: '5'),
      SelectTextEntry(id: 'h-f', name: '6'),
      SelectTextEntry(id: 'h-g', name: '7'),
      SelectTextEntry(id: 'h-h', name: '8'),
      SelectTextEntry(id: 'h-i', name: '9'),
      SelectTextEntry(id: 'h-j', name: '10'),
    },
  );

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
    SelectTextEntry(id: 'a', name: 'Kiwi'),
    SelectTextEntry(id: 'b', name: 'Grape'),
    SelectTextEntry(id: 'c', name: 'Strawberry'),
    SelectTextEntry(id: 'd', name: 'Pineapple'),
    SelectTextEntry(id: 'e', name: 'Orange'),
    SelectTextEntry(id: 'f', name: 'Banana'),
    SelectTextEntry(id: 'g', name: 'Pine'),
    SelectTextEntry(id: 'h', name: 'Mango'),
    SelectTextEntry(id: 'i', name: 'Pear'),
    SelectTextEntry(id: 'j', name: 'Peach'),
    SelectTextEntry(id: 'k', name: 'Cherry'),
    SelectTextEntry(id: 'l', name: 'Lemon'),
    SelectTextEntry(id: 'm', name: 'Lime'),
    SelectTextEntry(id: 'n', name: 'Grapefruit'),
  };
}

SelectEntries get listDataWithAny {
  return {
    SelectTextEntry.any(name: 'Any'),
    SelectTextEntry(id: 'a', name: 'Kiwi'),
    SelectTextEntry(id: 'b', name: 'Grape'),
    SelectTextEntry(id: 'c', name: 'Strawberry'),
    SelectTextEntry(id: 'd', name: 'Pineapple'),
    SelectTextEntry(id: 'e', name: 'Orange'),
    SelectTextEntry(id: 'f', name: 'Banana'),
    SelectTextEntry(id: 'g', name: 'Pine'),
    SelectTextEntry(id: 'h', name: 'Mango'),
    SelectTextEntry(id: 'i', name: 'Pear'),
    SelectTextEntry(id: 'j', name: 'Peach'),
    SelectTextEntry(id: 'k', name: 'Cherry'),
    SelectTextEntry(id: 'l', name: 'Lemon'),
    SelectTextEntry(id: 'm', name: 'Lime'),
    SelectTextEntry(id: 'n', name: 'Grapefruit'),
  };
}

SelectEntries get gridData {
  return {
    SelectIntEntry.custom(),
    SelectIntEntry(id: 'a', name: '\$0-\$25', min: 0, max: 25),
    SelectIntEntry(id: 'b', name: '\$25-\$50', min: 25, max: 50),
    SelectIntEntry(id: 'c', name: '\$50-\$100', min: 50, max: 100),
    SelectIntEntry(id: 'd', name: '\$100-\$250', min: 100, max: 250),
    SelectIntEntry(id: 'e', name: '\$250-\$500', min: 250, max: 500),
    SelectIntEntry(id: 'f', name: '\$500-\$1000', min: 500, max: 1000),
    // SelectIntEntry(
    //   id: 'g',
    //   name: '\$1000-\$2500',
    //   min: 1000,
    //   max: 2500,
    // ),
    // SelectIntEntry(
    //   id: 'h',
    //   name: '\$2500-\$5000',
    //   min: 2500,
    //   max: 5000,
    // ),
    // SelectIntEntry(
    //   id: 'i',
    //   name: '\$5000-\$10000',
    //   min: 5000,
    //   max: 10000,
    // ),
    // SelectIntEntry(
    //   id: 'j',
    //   name: '\$10000-\$25000',
    //   min: 10000,
    //   max: 25000,
    // ),
    // SelectIntEntry(
    //   id: 'k',
    //   name: '\$25000-\$50000',
    //   min: 250,
    //   max: 50000,
    // ),
    // SelectIntEntry(
    //   id: 'l',
    //   name: '\$50000-\$100000',
    //   min: 50000,
    //   max: 100000,
    // ),
    // SelectIntEntry(
    //   id: 'm',
    //   name: '\$100000-\$250000',
    //   min: 100000,
    //   max: 250000,
    // ),
    // SelectIntEntry(
    //   id: 'n',
    //   name: '\$250000-\$500000',
    //   min: 250000,
    //   max: 500000,
    // ),
    // SelectIntEntry(
    //   id: 'o',
    //   name: '\$500000-\$1000000',
    //   min: 500000,
    //   max: 1000000,
    // ),
    // SelectIntEntry(
    //   id: 'p',
    //   name: '\$1000000-\$2500000',
    //   min: 1000000,
    //   max: 2500000,
    // ),
    // SelectIntEntry(
    //   id: 'q',
    //   name: '\$2500000-\$5000000',
    //   min: 2500000,
    //   max: 5000000,
    // ),
    // SelectIntEntry(
    //   id: 'r',
    //   name: '\$5000000-\$10000000',
    //   min: 5000000,
    //   max: 10000000,
    // ),
    // SelectIntEntry(
    //   id: 's',
    //   name: '\$10000000-\$25000000',
    //   min: 10000000,
    //   max: 25000000,
    // ),
    // SelectIntEntry(
    //   id: 't',
    //   name: '\$25000000-\$50000000',
    //   min: 25000000,
    //   max: 50000000,
    // ),
    // SelectIntEntry(
    //   id: 'u',
    //   name: '\$50000000-\$100000000',
    //   min: 50000000,
    //   max: 100000000,
    // ),
    // SelectIntEntry(
    //   id: 'v',
    //   name: '\$100000000-\$250000000',
    //   min: 100000000,
    //   max: 250000000,
    // ),
    // SelectIntEntry(
    //   id: 'w',
    //   name: '\$250000000-\$500000000',
    //   min: 250000000,
    //   max: 500000000,
    // ),
    // SelectIntEntry(
    //   id: 'x',
    //   name: '\$500000000-\$1000000000',
    //   min: 500000000,
    //   max: 1000000000,
    // ),
    // SelectIntEntry(
    //   id: 'y',
    //   name: '\$1000000000-\$2500000000',
    //   min: 1000000000,
    //   max: 2500000000,
    // ),
    // SelectIntEntry(
    //   id: 'z',
    //   name: '\$2500000000-\$5000000000',
    //   min: 2500000000,
    //   max: 5000000000,
    // ),
  };
}

SelectEntries get gridDataWithAny {
  return {
    SelectIntEntry.custom(),
    SelectIntEntry.any(name: 'Any'),
    SelectIntEntry(id: 'a', name: '\$0-\$25', min: 0, max: 25),
    SelectIntEntry(id: 'b', name: '\$25-\$50', min: 25, max: 50),
    SelectIntEntry(id: 'c', name: '\$50-\$100', min: 50, max: 100),
    SelectIntEntry(id: 'd', name: '\$100-\$250', min: 100, max: 250),
    SelectIntEntry(id: 'e', name: '\$250-\$500', min: 250, max: 500),
    SelectIntEntry(id: 'f', name: '\$500-\$1000', min: 500, max: 1000),
  };
}

SelectEntries get wrapData {
  return {
    SelectTextEntry(id: 'a', name: 'Tiger'),
    SelectTextEntry(id: 'b', name: 'Lion'),
    SelectTextEntry(id: 'c', name: 'Bear'),
    SelectTextEntry(id: 'd', name: 'Elephant'),
    SelectTextEntry(id: 'e', name: 'Monkey'),
    SelectTextEntry(id: 'f', name: 'Dog'),
    SelectTextEntry(id: 'g', name: 'Cat'),
    SelectTextEntry(id: 'h', name: 'Pig'),
    SelectTextEntry(id: 'i', name: 'Horse'),
    SelectTextEntry(id: 'j', name: 'Sheep'),
    SelectTextEntry(id: 'k', name: 'Cow'),
    SelectTextEntry(id: 'l', name: 'Chicken'),
    SelectTextEntry(id: 'm', name: 'Duck'),
    SelectTextEntry(id: 'n', name: 'Penguin'),
    SelectTextEntry(id: 'o', name: 'Rabbit'),
    SelectTextEntry(id: 'p', name: 'Fish'),
    SelectTextEntry(id: 'q', name: 'Bird'),
    SelectTextEntry(id: 'r', name: 'Snake'),
    SelectTextEntry(id: 's', name: 'Turtle'),
    SelectTextEntry(id: 't', name: 'Frog'),
    SelectTextEntry(id: 'u', name: 'Mouse'),
    SelectTextEntry(id: 'v', name: 'Rat'),
    SelectTextEntry(id: 'w', name: 'Snail'),
    SelectTextEntry(id: 'x', name: 'Ant'),
    SelectTextEntry(id: 'y', name: 'Spider'),
    SelectTextEntry(id: 'z', name: 'Fly'),
    // SelectTextEntry(id: 'aa', name: 'Bat'),
    // SelectTextEntry(id: 'ab', name: 'Worm'),
    // SelectTextEntry(id: 'ac', name: 'Beetle'),
    // SelectTextEntry(id: 'ad', name: 'Elephant'),
    // SelectTextEntry(id: 'ae', name: 'Elephant'),
    // SelectTextEntry(id: 'af', name: 'Elephant'),
    // SelectTextEntry(id: 'ag', name: 'Elephant'),
    // SelectTextEntry(id: 'ah', name: 'Elephant'),
    // SelectTextEntry(id: 'ai', name: 'Elephant'),
    // SelectTextEntry(id: 'aj', name: 'Elephant'),
    // SelectTextEntry(id: 'ak', name: 'Elephant'),
    // SelectTextEntry(id: 'al', name: 'Elephant'),
    // SelectTextEntry(id: 'am', name: 'Elephant'),
    // SelectTextEntry(id: 'an', name: 'Elephant'),
    // SelectTextEntry(id: 'ao', name: 'Elephant'),
    // SelectTextEntry(id: 'ap', name: 'Elephant'),
    // SelectTextEntry(id: 'aq', name: 'Elephant'),
    // SelectTextEntry(id: 'ar', name: 'Elephant'),
    // SelectTextEntry(id: 'as', name: 'Elephant'),
    // SelectTextEntry(id: 'at', name: 'Elephant'),
    // SelectTextEntry(id: 'au', name: 'Elephant'),
    // SelectTextEntry(id: 'av', name: 'Elephant'),
    // SelectTextEntry(id: 'aw', name: 'Elephant'),
    // SelectTextEntry(id: 'ax', name: 'Elephant'),
    // SelectTextEntry(id: 'ay', name: 'Elephant'),
    // SelectTextEntry(id: 'az', name: 'Elephant'),
    // SelectTextEntry(id: 'ba', name: 'Elephant'),
    // SelectTextEntry(id: 'bb', name: 'Elephant'),
    // SelectTextEntry(id: 'bc', name: 'Elephant'),
    // SelectTextEntry(id: 'bd', name: 'Elephant'),
    // SelectTextEntry(id: 'be', name: 'Elephant'),
    // SelectTextEntry(id: 'bf', name: 'Elephant'),
    // SelectTextEntry(id: 'bg', name: 'Elephant'),
    // SelectTextEntry(id: 'bh', name: 'Elephant'),
    // SelectTextEntry(id: 'bi', name: 'Elephant'),
    // SelectTextEntry(id: 'bj', name: 'Elephant'),
    // SelectTextEntry(id: 'bk', name: 'Elephant'),
    // SelectTextEntry(id: 'bl', name: 'Elephant'),
    // SelectTextEntry(id: 'bm', name: 'Elephant'),
  };
}

SelectEntries get wrapDataWithAny {
  return {
    SelectTextEntry.any(name: 'Any'),
    SelectTextEntry(id: 'a', name: 'Tiger'),
    SelectTextEntry(id: 'b', name: 'Lion'),
    SelectTextEntry(id: 'c', name: 'Bear'),
    SelectTextEntry(id: 'd', name: 'Dog'),
    SelectTextEntry(id: 'e', name: 'Cat'),
    SelectTextEntry(id: 'f', name: 'Elephant'),
    SelectTextEntry(id: 'g', name: 'Monkey'),
    SelectTextEntry(id: 'h', name: 'Pig'),
    SelectTextEntry(id: 'i', name: 'Horse'),
    SelectTextEntry(id: 'j', name: 'Sheep'),
    SelectTextEntry(id: 'k', name: 'Cow'),
    SelectTextEntry(id: 'l', name: 'Chicken'),
    SelectTextEntry(id: 'm', name: 'Duck'),
    SelectTextEntry(id: 'n', name: 'Penguin'),
    // SelectTextEntry(id: 'aa', name: 'Bat'),
    // SelectTextEntry(id: 'ab', name: 'Worm'),
    // SelectTextEntry(id: 'ac', name: 'Beetle'),
    // SelectTextEntry(id: 'ad', name: 'Elephant'),
    // SelectTextEntry(id: 'ae', name: 'Elephant'),
    // SelectTextEntry(id: 'af', name: 'Elephant'),
    // SelectTextEntry(id: 'ag', name: 'Elephant'),
    // SelectTextEntry(id: 'ah', name: 'Elephant'),
    // SelectTextEntry(id: 'ai', name: 'Elephant'),
    // SelectTextEntry(id: 'aj', name: 'Elephant'),
    // SelectTextEntry(id: 'ak', name: 'Elephant'),
    // SelectTextEntry(id: 'al', name: 'Elephant'),
    // SelectTextEntry(id: 'am', name: 'Elephant'),
    // SelectTextEntry(id: 'an', name: 'Elephant'),
    // SelectTextEntry(id: 'ao', name: 'Elephant'),
    // SelectTextEntry(id: 'ap', name: 'Elephant'),
    // SelectTextEntry(id: 'aq', name: 'Elephant'),
    // SelectTextEntry(id: 'ar', name: 'Elephant'),
    // SelectTextEntry(id: 'as', name: 'Elephant'),
    // SelectTextEntry(id: 'at', name: 'Elephant'),
    // SelectTextEntry(id: 'au', name: 'Elephant'),
    // SelectTextEntry(id: 'av', name: 'Elephant'),
    // SelectTextEntry(id: 'aw', name: 'Elephant'),
    // SelectTextEntry(id: 'ax', name: 'Elephant'),
    // SelectTextEntry(id: 'ay', name: 'Elephant'),
    // SelectTextEntry(id: 'az', name: 'Elephant'),
    // SelectTextEntry(id: 'ba', name: 'Elephant'),
    // SelectTextEntry(id: 'bb', name: 'Elephant'),
    // SelectTextEntry(id: 'bc', name: 'Elephant'),
    // SelectTextEntry(id: 'bd', name: 'Elephant'),
    // SelectTextEntry(id: 'be', name: 'Elephant'),
    // SelectTextEntry(id: 'bf', name: 'Elephant'),
    // SelectTextEntry(id: 'bg', name: 'Elephant'),
    // SelectTextEntry(id: 'bh', name: 'Elephant'),
    // SelectTextEntry(id: 'bi', name: 'Elephant'),
    // SelectTextEntry(id: 'bj', name: 'Elephant'),
    // SelectTextEntry(id: 'bk', name: 'Elephant'),
    // SelectTextEntry(id: 'bl', name: 'Elephant'),
    // SelectTextEntry(id: 'bm', name: 'Elephant'),
  };
}

SelectEntries get multiCategoryData {
  return {
    SelectCategoryEntry(
      id: 'cate1',
      name: 'Sport',
      children: {
        SelectTextEntry(id: 'a', name: 'Football'),
        SelectTextEntry(id: 'b', name: 'Basketball'),
        SelectTextEntry(id: 'c', name: 'Baseball'),
        SelectTextEntry(id: 'd', name: 'Tennis'),
      },
      selectionMode: SelectionMode.single,
      footer: SelectTextEntry(
        id: 'c1-f',
        name: 'Letter Grade',
        children: {
          SelectTextEntry(id: 'f-a', name: 'A'),
          SelectTextEntry(id: 'f-b', name: 'B'),
          SelectTextEntry(id: 'f-c', name: 'C'),
          SelectTextEntry(id: 'f-d', name: 'D'),
          SelectTextEntry(id: 'f-e', name: 'E'),
          SelectTextEntry(id: 'f-f', name: 'F'),
          SelectTextEntry(id: 'f-g', name: 'G'),
          SelectTextEntry(id: 'f-h', name: 'H'),
          SelectTextEntry(id: 'f-i', name: 'I'),
          SelectTextEntry(id: 'f-j', name: 'J'),
          SelectTextEntry(id: 'f-k', name: 'K'),
        },
      ),
      footerSelectionMode: SelectionMode.single,
    ),
    SelectCategoryEntry(
      id: 'cate2',
      name: 'Cuisine',
      header: SelectTextEntry(
        id: 'c2-h',
        name: 'Letter Grade',
        children: {
          SelectTextEntry(id: 'h-a', name: '1'),
          SelectTextEntry(id: 'h-b', name: '2'),
          SelectTextEntry(id: 'h-c', name: '3'),
          SelectTextEntry(id: 'h-d', name: '4'),
          SelectTextEntry(id: 'h-e', name: '5'),
          SelectTextEntry(id: 'h-f', name: '6'),
          SelectTextEntry(id: 'h-g', name: '7'),
          SelectTextEntry(id: 'h-h', name: '8'),
          SelectTextEntry(id: 'h-i', name: '9'),
          SelectTextEntry(id: 'h-j', name: '10'),
          SelectTextEntry(id: 'h-k', name: '11'),
        },
      ),
      headerSelectionMode: SelectionMode.single,
      children: {
        SelectTextEntry(id: 'a', name: 'Chinese'),
        SelectTextEntry(id: 'b', name: 'French'),
        SelectTextEntry(id: 'c', name: 'Indian'),
        SelectTextEntry(id: 'd', name: 'Turkish'),
      },
      selectionMode: SelectionMode.single,
    ),
    SelectCategoryEntry(
      id: 'cate3',
      name: 'Storage (GB)',
      children: {
        SelectIntEntry.custom(),
        SelectRangeEntry(id: '0-64', name: '0-64', min: 0, max: 64),
        SelectRangeEntry(id: '64-128', name: '64-128', min: 64, max: 128),
        SelectRangeEntry(id: '128-256', name: '128-256', min: 128, max: 256),
        SelectRangeEntry(id: '256-512', name: '256-512', min: 256, max: 512),
        SelectRangeEntry(id: '512-1024', name: '512-1024', min: 512, max: 1024),
        SelectRangeEntry(
          id: '1024-2048',
          name: '1024-2048',
          min: 1024,
          max: 2048,
        ),
      },
      selectionMode: SelectionMode.single,
    ),
    SelectCategoryEntry(
      id: 'cate4',
      name: 'Animal',
      children: {
        SelectTextEntry(id: 'a', name: 'Tiger'),
        SelectTextEntry(id: 'b', name: 'Lion'),
        SelectTextEntry(id: 'c', name: 'Bear'),
        SelectTextEntry(id: 'd', name: 'Elephant'),
        SelectTextEntry(id: 'e', name: 'Monkey'),
        SelectTextEntry(id: 'f', name: 'Dog'),
        SelectTextEntry(id: 'g', name: 'Cat'),
        SelectTextEntry(id: 'h', name: 'Pig'),
        SelectTextEntry(id: 'i', name: 'Horse'),
        SelectTextEntry(id: 'j', name: 'Sheep'),
        SelectTextEntry(id: 'k', name: 'Cow'),
        SelectTextEntry(id: 'l', name: 'Chicken'),
        SelectTextEntry(id: 'm', name: 'Duck'),
        SelectTextEntry(id: 'n', name: 'Pig'),
        // SelectTextEntry(id: 'aa', name: 'Bat'),
        // SelectTextEntry(id: 'ab', name: 'Worm'),
        // SelectTextEntry(id: 'ac', name: 'Beetle'),
        // SelectTextEntry(id: 'ad', name: 'Elephant'),
        // SelectTextEntry(id: 'ae', name: 'Elephant'),
        // SelectTextEntry(id: 'af', name: 'Elephant'),
        // SelectTextEntry(id: 'ag', name: 'Elephant'),
        // SelectTextEntry(id: 'ah', name: 'Elephant'),
        // SelectTextEntry(id: 'ai', name: 'Elephant'),
        // SelectTextEntry(id: 'aj', name: 'Elephant'),
        // SelectTextEntry(id: 'ak', name: 'Elephant'),
        // SelectTextEntry(id: 'al', name: 'Elephant'),
        // SelectTextEntry(id: 'am', name: 'Elephant'),
        // SelectTextEntry(id: 'an', name: 'Elephant'),
        // SelectTextEntry(id: 'ao', name: 'Elephant'),
        // SelectTextEntry(id: 'ap', name: 'Elephant'),
        // SelectTextEntry(id: 'aq', name: 'Elephant'),
        // SelectTextEntry(id: 'ar', name: 'Elephant'),
        // SelectTextEntry(id: 'as', name: 'Elephant'),
        // SelectTextEntry(id: 'at', name: 'Elephant'),
        // SelectTextEntry(id: 'au', name: 'Elephant'),
        // SelectTextEntry(id: 'av', name: 'Elephant'),
        // SelectTextEntry(id: 'aw', name: 'Elephant'),
        // SelectTextEntry(id: 'ax', name: 'Elephant'),
        // SelectTextEntry(id: 'ay', name: 'Elephant'),
        // SelectTextEntry(id: 'az', name: 'Elephant'),
        // SelectTextEntry(id: 'ba', name: 'Elephant'),
        // SelectTextEntry(id: 'bb', name: 'Elephant'),
        // SelectTextEntry(id: 'bc', name: 'Elephant'),
        // SelectTextEntry(id: 'bd', name: 'Elephant'),
        // SelectTextEntry(id: 'be', name: 'Elephant'),
        // SelectTextEntry(id: 'bf', name: 'Elephant'),
        // SelectTextEntry(id: 'bg', name: 'Elephant'),
        // SelectTextEntry(id: 'bh', name: 'Elephant'),
        // SelectTextEntry(id: 'bi', name: 'Elephant'),
        // SelectTextEntry(id: 'bj', name: 'Elephant'),
        // SelectTextEntry(id: 'bk', name: 'Elephant'),
        // SelectTextEntry(id: 'bl', name: 'Elephant'),
        // SelectTextEntry(id: 'bm', name: 'Elephant'),
      },
    ),
    SelectCategoryEntry(
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
    SelectCategoryEntry(
      id: 'cate6',
      name: 'Counter',
      children: {
        SelectTextEntry.any(name: 'Any'),
        SelectTextEntry(id: 'a', name: '1'),
        SelectTextEntry(id: 'b', name: '2'),
        SelectTextEntry(id: 'c', name: '3'),
        SelectTextEntry(id: 'd', name: '4'),
        SelectTextEntry(id: 'e', name: '5'),
        SelectTextEntry(id: 'f', name: '5+'),
      },
      selectionMode: SelectionMode.single,
      layout: const SelectCounterLayout(),
    ),
  };
}
