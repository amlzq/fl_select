import 'dart:async';
import 'dart:convert';

import 'package:fl_select/fl_select.dart';
import 'package:flutter/foundation.dart';

import 'utils.dart';

class HouseFiltersRepository {
  HouseFiltersRepository({
    this.anyEntryText = 'Any',
    this.noMinHintText = 'No min',
    this.noMaxHintText = 'No max',
  });

  String anyEntryText;
  String noMinHintText;
  String noMaxHintText;

  void updateTexts({
    String? anyEntryText,
    String? noMinHintText,
    String? noMaxHintText,
  }) {
    if (anyEntryText != null) this.anyEntryText = anyEntryText;
    if (noMinHintText != null) this.noMinHintText = noMinHintText;
    if (noMaxHintText != null) this.noMaxHintText = noMaxHintText;
  }

  SelectEntries? neighborhoodResult;

  final neighborhoodIniteialSelected = {
    SelectCategoryEntry(
      id: 'neighborhood',
      name: '',
      children: {SelectTextEntry.any(parentId: 'neighborhood', name: '')},
    )
  };

  SelectEntries? get neighborhoodSelectedData =>
      neighborhoodResult ?? neighborhoodIniteialSelected;

  SelectEntries? get neighborhoodResetData => neighborhoodIniteialSelected;

  Future<SelectEntries> fetchNeighborhoodData() async {
    // simulate network delay
    await Future.delayed(const Duration(milliseconds: 250));
    final neighborhood =
        neighborhoodFromJson(await loadJsonData('neighborhood.json'));
    debugPrint('neighborhood length: ${neighborhood.length}');
    SelectEntries entries = neighborhood
        .map(
          (category) => SelectCategoryEntry(
            id: category.id!,
            name: category.name!,
            children: category.data
                ?.map((l1) => SelectTextEntry(
                      parentId: category.id!,
                      id: l1.id!,
                      name: l1.name!,
                      enabled: l1.enabled ?? true,
                      children: l1.data
                          ?.map((l2) => SelectTextEntry(
                                parentId: l1.id!,
                                id: l2.id!,
                                name: l2.name!,
                                enabled: l2.enabled ?? true,
                              ))
                          .toSet(),
                    ))
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
              parentId: category.id, name: anyEntryText, immediate: true));
    }

    debugPrint('neighborhood length: ${entries.length}');
    return Future.value(entries);
  }

  SelectEntries? priceResult;

  SelectEntries? get priceSelectedData => priceResult;

  Future<SelectEntries> fetchPriceData() async {
    // simulate network delay
    await Future.delayed(const Duration(milliseconds: 350));
    final prices = priceFromJson(await loadJsonData('price.json'));
    SelectEntries entries = prices
        .map(
          (category) => SelectCategoryEntry(
            id: category.id!,
            name: category.name!,
            children: category.data
                ?.map((l1) => SelectIntEntry(
                      parentId: category.id!,
                      id: l1.id!,
                      name: l1.name,
                      min: l1.min,
                      max: l1.max,
                      divisions: l1.divisions,
                    ))
                .toSet(),
            selectionMode: SelectionMode.multiple,
            layout: const SelectRangeLayout(toText: 'to'),
          ),
        )
        .toSet();

    // Add some special entries
    for (SelectEntry category in entries) {
      // Add the "Custom" entry
      category.children?.add(SelectIntEntry.custom(
          parentId: category.id,
          minHintText: noMinHintText,
          maxHintText: noMaxHintText));
    }

    debugPrint('prices length: ${entries.length}');
    return Future.value(entries);
  }

  SelectEntries? roomsResult;

  final roomsIniteialSelected = {
    SelectCategoryEntry(
      id: 'bedrooms',
      name: '',
      children: {SelectTextEntry(parentId: 'bedrooms', id: '203', name: '')},
    ),
    SelectCategoryEntry(
      id: 'bathrooms',
      name: '',
      children: {SelectTextEntry(parentId: 'bathrooms', id: '104', name: '')},
    ),
  };

  SelectEntries? get roomsSelectedData =>
      roomsResult; // ?? roomsIniteialSelected;

  SelectEntries? get roomsResetData => roomsIniteialSelected;

  Future<SelectEntries> fetchRoomsData() async {
    // simulate network delay
    await Future.delayed(const Duration(milliseconds: 450));

    final rooms = roomsFromJson(await loadJsonData('rooms.json'));

    SelectEntries entries = rooms
        .map(
          (category) => SelectCategoryEntry(
            id: category.id!,
            name: category.name!,
            children: category.data
                ?.map((l1) => SelectTextEntry(
                      parentId: category.id!,
                      id: l1.id!,
                      name: l1.name,
                    ))
                .toSet(),
            selectionMode: SelectionMode.single,
            layout: const SelectCounterLayout(),
          ),
        )
        .toSet();

    // Insert some special entries
    for (SelectEntry category in entries) {
      // Insert the "Any" entry
      category.children?.insert(
          0,
          SelectTextEntry.any(
              parentId: category.id, name: anyEntryText, immediate: false));
    }

    debugPrint('rooms length: ${entries.length}');
    return Future.value(entries);
  }

  SelectEntries? moreResult;

  final moreIniteialSelected = <SelectCategoryEntry>{};

  SelectEntries? get moreSelectedData => moreResult ?? moreIniteialSelected;

  SelectEntries? get moreResetData => moreIniteialSelected;

  Future<SelectEntries> fetchMoreData() async {
    // simulate network delay
    await Future.delayed(const Duration(milliseconds: 850));
    final more = moreFromJson(await loadJsonData('more.json'));
    debugPrint('more length: ${more.length}');

    SelectGridLayout? gridLayout(String categoryId) {
      if (categoryId == 'home_type' ||
          categoryId == 'lists_details' ||
          categoryId == 'commute') {
        return const SelectGridLayout(
          crossAxisCount: 2,
          childAspectRatio: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        );
      }
      if (categoryId == 'square_feet' ||
          categoryId == 'lot_size' ||
          categoryId == 'home_features') {
        return const SelectGridLayout(
          crossAxisCount: 3,
          childAspectRatio: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        );
      } else {
        return null;
      }
    }

    SelectChipLayout? chipLayout(String categoryId) {
      if (categoryId == 'expanded_search') {
        return const SelectChipLayout();
      }
      return null;
    }

    SelectEntries entries = more
        .map(
          (category) => SelectCategoryEntry(
            id: category.id!,
            name: category.name!,
            children: category.data
                ?.map((l1) =>
                    (category.id == 'square_feet' || category.id == 'lot_size')
                        ? SelectRangeEntry(
                            parentId: category.id!,
                            id: l1.id!,
                            name: l1.name,
                            min: l1.min,
                            max: l1.max,
                          )
                        : SelectTextEntry(
                            parentId: category.id!,
                            id: l1.id!,
                            name: l1.name,
                          ))
                .toSet(),
            selectionMode: category.id == 'expanded_search'
                ? SelectionMode.single
                : SelectionMode.multiple,
            layout: gridLayout(category.id!) ?? chipLayout(category.id!),
          ),
        )
        .toSet();

    debugPrint('more length: ${entries.length}');
    return Future.value(entries);
  }

  SelectEntries? sortResult;

  final sortIniteialSelected = <SelectTextEntry>{
    SelectTextEntry.id(id: 'comprehensive_sort')
  };

  SelectEntries? get sortSelectedData => sortResult ?? sortIniteialSelected;

  SelectEntries? get sortResetData => sortIniteialSelected;

  Future<SelectEntries> fetchSortData() async {
    // simulate network delay
    await Future.delayed(const Duration(milliseconds: 250));
    final sort = sortFromJson(await loadJsonData('sort.json'));
    debugPrint('sort length: ${sort.length}');
    SelectEntries entries = sort
        .map((e) => SelectTextEntry.name(
              id: e.id!,
              name: e.name!,
              immediate: true,
            ))
        .toSet();

    debugPrint('sort length: ${entries.length}');
    return Future.value(entries);
  }
}

List<NeighborhoodData> neighborhoodFromJson(String str) =>
    List<NeighborhoodData>.from(
        json.decode(str).map((x) => NeighborhoodData.fromJson(x)));

String neighborhoodToJson(List<NeighborhoodData> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class NeighborhoodData {
  String? id;
  String? name;
  bool? enabled;
  List<NeighborhoodData>? data;

  NeighborhoodData({this.id, this.name, this.data});

  NeighborhoodData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    enabled = json['enabled'];
    if (json['data'] != null) {
      data = <NeighborhoodData>[];
      json['data'].forEach((v) {
        data!.add(NeighborhoodData.fromJson(v));
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

List<PriceData> priceFromJson(String str) =>
    List<PriceData>.from(json.decode(str).map((x) => PriceData.fromJson(x)));

String priceToJson(List<PriceData> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class PriceData {
  String? id;
  String? name;
  List<PriceItem>? data;

  PriceData({this.id, this.name, this.data});

  PriceData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['data'] != null) {
      data = <PriceItem>[];
      json['data'].forEach((v) {
        data!.add(PriceItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PriceItem {
  String? id;
  String? name;
  int? min;
  int? max;
  int? divisions;

  PriceItem({this.id, this.name, this.min, this.max, this.divisions});

  PriceItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    min = json['min'];
    max = json['max'];
    divisions = json['divisions'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['min'] = min;
    data['max'] = max;
    data['divisions'] = divisions;
    return data;
  }
}

List<RoomData> roomsFromJson(String str) =>
    List<RoomData>.from(json.decode(str).map((x) => RoomData.fromJson(x)));

String roomsToJson(List<RoomData> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class RoomData {
  String? id;
  String? name;
  List<RoomItem>? data;

  RoomData({this.id, this.name, this.data});

  RoomData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['data'] != null) {
      data = <RoomItem>[];
      json['data'].forEach((v) {
        data!.add(RoomItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RoomItem {
  String? id;
  String? name;

  RoomItem({this.id, this.name});

  RoomItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}

List<MoreData> moreFromJson(String str) =>
    List<MoreData>.from(json.decode(str).map((x) => MoreData.fromJson(x)));

String moreToJson(List<MoreData> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class MoreData {
  String? id;
  String? name;
  List<MoreItem>? data;

  MoreData({this.id, this.name, this.data});

  MoreData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['data'] != null) {
      data = <MoreItem>[];
      json['data'].forEach((v) {
        data!.add(MoreItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MoreItem {
  String? id;
  String? name;
  int? min;
  int? max;

  MoreItem({this.id, this.name, this.min, this.max});

  MoreItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    min = json['min'];
    max = json['max'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['min'] = min;
    data['max'] = max;
    return data;
  }
}

List<SortData> sortFromJson(String str) =>
    List<SortData>.from(json.decode(str).map((x) => SortData.fromJson(x)));

String sortToJson(List<SortData> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SortData {
  String? id;
  String? name;

  SortData({this.id, this.name});

  SortData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}
