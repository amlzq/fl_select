import 'dart:async';
import 'dart:convert';

import 'package:fl_select/fl_select.dart';
import 'package:flutter/foundation.dart';

import 'utils.dart';

class HouseFiltersRepository {
  HouseFiltersRepository({
    this.anyEntryText = '不限',
    this.customInputLabel = '自定义',
    this.minHintText = '最小值',
    this.maxHintText = '最大值',
    this.customAreaName = '自定义面积',
  });

  String anyEntryText;
  String customInputLabel;
  String minHintText;
  String maxHintText;
  String customAreaName;

  void updateTexts({
    String? anyEntryText,
    String? customInputLabel,
    String? minHintText,
    String? maxHintText,
    String? customAreaName,
  }) {
    if (anyEntryText != null) this.anyEntryText = anyEntryText;
    if (customInputLabel != null) this.customInputLabel = customInputLabel;
    if (minHintText != null) this.minHintText = minHintText;
    if (maxHintText != null) this.maxHintText = maxHintText;
    if (customAreaName != null) this.customAreaName = customAreaName;
  }

  /// 区域的 初始选中项
  SelectEntries? regionResult;

  final regionIniteialSelected = {
    SelectCategoryEntry(
      id: 'community',
      name: '',
      children: {SelectTextEntry.any(parentId: 'community', name: '')},
    )
  };

  SelectEntries? fetchRegionSelectedData() =>
      regionResult ?? regionIniteialSelected;

  SelectEntries? fetchRegionResetData() => regionIniteialSelected;

  Future<SelectEntries> fetchRegionData({bool singleAll = false}) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 250));

    // 板块/地段
    // 是地产板块（ neighborhood/community ），而不是行政区
    final community =
        RegionData.fromJson(json.decode(await loadJsonData('community.json')));
    debugPrint('community length: ${community.data?.length}');

    final metro =
        RegionData.fromJson(json.decode(await loadJsonData('metro.json')));
    debugPrint('metro length: ${metro.data?.length}');

    final nearby =
        RegionData.fromJson(json.decode(await loadJsonData('nearby.json')));
    debugPrint('nearby length: ${nearby.data?.length}');

    final region = [community, metro, nearby];
    debugPrint('region length: ${region.length}');
    SelectEntries entries = region
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
                                children: l2.data
                                    ?.map((l3) => SelectTextEntry(
                                          parentId: l2.id!,
                                          id: l3.id!,
                                          name: l3.name!,
                                          enabled: l3.enabled ?? true,
                                        ))
                                    .toSet(),
                              ))
                          .toSet(),
                      immediate: category.id == 'nearby',
                    ))
                .toSet(),
            selectionMode: singleAll || category.id == 'nearby'
                ? SelectionMode.single
                : SelectionMode.multiple,
          ),
        )
        .toSet();

    // 将“距地铁”作为地铁类别的 header
    final metroEntry =
        entries.firstWhere((e) => e.id == 'metro') as SelectCategoryEntry;
    final metroRadiusEntry =
        metroEntry.children?.firstWhere((e) => e.id == 'metro_radius');
    metroEntry.children?.remove(metroRadiusEntry);
    metroEntry.header = metroRadiusEntry;

    // 插入"不限"选项
    for (SelectEntry category in entries) {
      category.children?.insert(
          0,
          SelectTextEntry.any(
              parentId: category.id, name: anyEntryText, immediate: true));
      for (SelectEntry l1 in category.children ?? []) {
        l1.children?.insert(
          0,
          SelectTextEntry.any(parentId: l1.id, name: anyEntryText),
        );
      }
    }

    debugPrint('region length: ${entries.length}');
    return Future.value(entries);
  }

  /// 排序 初始选中项
  SelectEntries? buyPriceResult;

  /// 初始选中项
  final buyPriceIniteialSelected = {
    SelectCategoryEntry(
      id: 'total',
      name: '',
      children: {SelectIntEntry(parentId: 'total', id: '203', name: '')},
    ),
    SelectCategoryEntry(
      id: 'unit',
      name: '',
      children: {SelectIntEntry(parentId: 'unit', id: '104', name: '')},
    ),
  };

  SelectEntries? fetchBuyPriceSelectedData() =>
      buyPriceResult; // ?? buyPriceIniteialSelected;

  /// 重置按钮的选中项
  SelectEntries? fetchBuyPriceResetData() => {
        SelectCategoryEntry(
          id: 'total',
          name: '',
          children: {SelectIntEntry.any(parentId: 'total', name: '')},
        ),
        SelectCategoryEntry(
          id: 'unit',
          name: '',
          children: {SelectIntEntry.any(parentId: 'total', name: '')},
        ),
      };

  Future<SelectEntries> fetchBuyPriceData() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 250));

    final totalPrice =
        PriceData.fromJson(json.decode(await loadJsonData('total_price.json')));
    debugPrint('totalPrice length: ${totalPrice.data?.length}');

    final unitPrice =
        PriceData.fromJson(json.decode(await loadJsonData('unit_price.json')));
    debugPrint('unitPrice length: ${unitPrice.data?.length}');

    final prices = [totalPrice, unitPrice];
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
                    ))
                .toSet(),
            selectionMode: SelectionMode.multiple,
          ),
        )
        .toSet();

    // 插入一些特殊选项
    for (SelectEntry category in entries) {
      // 插入"不限"选项
      category.children?.insert(
          0,
          SelectIntEntry.any(
              parentId: category.id, name: anyEntryText, immediate: false));
      // 插入"自定义"选项
      category.children?.insert(
          0,
          SelectIntEntry.custom(
              parentId: category.id,
              inputLabel: customInputLabel,
              minHintText: minHintText,
              maxHintText: maxHintText));
    }

    debugPrint('prices length: ${entries.length}');
    return Future.value(entries);
  }

  /// 价格的 初始选中项
  SelectEntries? sellPriceResult;

  SelectEntries get sellPriceIniteialSelected => {
        SelectCategoryEntry(
          id: 'total',
          name: '',
          children: {SelectIntEntry.any(parentId: 'total', name: anyEntryText)},
        )
      };

  SelectEntries? fetchSellPriceSelectedData() =>
      sellPriceResult ?? sellPriceIniteialSelected;

  SelectEntries? fetchSellPriceResetData() => sellPriceIniteialSelected;

  Future<SelectEntries> fetchSellPriceData() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 250));

    final totalPrice =
        PriceData.fromJson(json.decode(await loadJsonData('total_price.json')));
    debugPrint('totalPrice length: ${totalPrice.data?.length}');

    final downpay =
        PriceData.fromJson(json.decode(await loadJsonData('downpay.json')));
    debugPrint('downpay length: ${downpay.data?.length}');

    final prices = [totalPrice, downpay];
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
                    ))
                .toSet(),
            selectionMode: category.id == 'downpay'
                ? SelectionMode.single
                : SelectionMode.multiple,
          ),
        )
        .toSet();

    // 插入一些特殊选项
    for (SelectEntry category in entries) {
      // 插入"不限"选项
      category.children?.insert(
          0,
          SelectIntEntry.any(
              parentId: category.id, name: anyEntryText, immediate: false));
      // 插入"自定义"选项
      category.children?.insert(
          0,
          SelectIntEntry.custom(
              parentId: category.id,
              inputLabel: customInputLabel,
              minHintText: minHintText,
              maxHintText: maxHintText));
    }

    debugPrint('prices length: ${entries.length}');
    return Future.value(entries);
  }

  /// 租金的 初始选中项
  SelectEntries? rentalResult;

  SelectEntries get rentalIniteialSelected => {
        SelectCategoryEntry(
          id: 'rent',
          name: '',
          children: {SelectIntEntry.any(parentId: 'total', name: anyEntryText)},
        )
      };

  SelectEntries? fetchRentalSelectedData() =>
      rentalResult ?? rentalIniteialSelected;

  SelectEntries? fetchRentalResetData() => rentalIniteialSelected;

  Future<SelectEntries> fetchRentalData() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 250));

    final rent =
        PriceData.fromJson(json.decode(await loadJsonData('rental.json')));
    debugPrint('rent length: ${rent.data?.length}');

    final prices = [rent];
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
                    ))
                .toSet(),
            selectionMode: SelectionMode.single,
          ),
        )
        .toSet();

    // 插入一些特殊选项
    for (SelectEntry category in entries) {
      // 插入"不限"选项
      category.children?.insert(
          0,
          SelectIntEntry.any(
              parentId: category.id, name: anyEntryText, immediate: false));
      // 插入"自定义"选项
      category.children?.insert(
          0,
          SelectIntEntry.custom(
              parentId: category.id,
              inputLabel: customInputLabel,
              minHintText: minHintText,
              maxHintText: maxHintText));
    }

    debugPrint('prices length: ${entries.length}');
    return Future.value(entries);
  }

  /// 户型的 初始选中项
  SelectEntries? floorPlanBuyResult;

  final floorPlanBuyIniteialSelected = <SelectCategoryEntry>{};

  SelectEntries? fetchFloorPlanBuySelectedData() =>
      floorPlanBuyResult ?? floorPlanBuyIniteialSelected;

  SelectEntries? fetchFloorPlanBuyResetData() => floorPlanBuyIniteialSelected;

  Future<SelectEntries> fetchFloorPlanBuyData() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 250));
    final floorPlan =
        floorPlanFromJson(await loadJsonData('floor_plan_buy.json'));
    debugPrint('floorPlan length: ${floorPlan.length}');
    SelectEntries entries = floorPlan
        .map(
          (category) => SelectCategoryEntry(
            id: category.id!,
            name: category.name!,
            children: category.data
                ?.map((l1) => category.id == 'area'
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
            selectionMode: SelectionMode.multiple,
          ),
        )
        .toSet();

    // 插入"面积自定义"选项
    for (SelectEntry category in entries) {
      if (category.id == 'area') {
        category.children?.add(SelectIntEntry.custom(
            parentId: category.id,
            name: customAreaName,
            minHintText: minHintText,
            maxHintText: maxHintText));
        continue;
      }
    }

    debugPrint('floorPlan length: ${entries.length}');
    return Future.value(entries);
  }

  /// 户型的 初始选中项
  SelectEntries? floorPlanSellResult;

  final floorPlanSellIniteialSelected = <SelectCategoryEntry>{};

  SelectEntries? fetchFloorPlanSellSelectedData() =>
      floorPlanSellResult ?? floorPlanSellIniteialSelected;

  SelectEntries? fetchFloorPlanSellResetData() => floorPlanSellIniteialSelected;

  Future<SelectEntries> fetchFloorPlanSellData() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 250));
    final floorPlan =
        floorPlanFromJson(await loadJsonData('floor_plan_sell.json'));
    debugPrint('floorPlan length: ${floorPlan.length}');
    SelectEntries entries = floorPlan
        .map(
          (category) => SelectCategoryEntry(
            id: category.id!,
            name: category.name!,
            children: category.data
                ?.map((l1) => category.id == 'area'
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
            selectionMode: SelectionMode.multiple,
          ),
        )
        .toSet();

    // 插入"面积自定义"选项
    for (SelectEntry category in entries) {
      if (category.id == 'area') {
        category.children?.add(SelectIntEntry.custom(
            parentId: category.id,
            name: customAreaName,
            minHintText: minHintText,
            maxHintText: maxHintText));
        continue;
      }
    }

    debugPrint('floorPlan length: ${entries.length}');
    return Future.value(entries);
  }

  /// 户型的 初始选中项
  SelectEntries? floorPlanRentResult;

  final floorPlanRentIniteialSelected = <SelectCategoryEntry>{};

  SelectEntries? fetchFloorPlanRentSelectedData() =>
      floorPlanRentResult ?? floorPlanRentIniteialSelected;

  SelectEntries? fetchFloorPlanRentResetData() => floorPlanRentIniteialSelected;

  Future<SelectEntries> fetchFloorPlanRentData({bool singleAll = false}) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 250));
    final floorPlan =
        floorPlanFromJson(await loadJsonData('floor_plan_rent.json'));
    debugPrint('floorPlan length: ${floorPlan.length}');
    SelectEntries entries = floorPlan
        .map(
          (category) => SelectCategoryEntry(
            id: category.id!,
            name: category.name!,
            children: category.data
                ?.map((l1) => category.id == 'area'
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
            selectionMode:
                singleAll ? SelectionMode.single : SelectionMode.multiple,
          ),
        )
        .toSet();

    debugPrint('floorPlan length: ${entries.length}');
    return Future.value(entries);
  }

  /// 更多的 初始选中项
  SelectEntries? moreBuyResult;

  final moreBuyIniteialSelected = <SelectTextEntry>{};

  SelectEntries? fetchMoreBuySelectedData() =>
      moreBuyResult ?? moreBuyIniteialSelected;

  SelectEntries? fetchMoreBuyResetData() => moreBuyIniteialSelected;

  Future<SelectEntries> fetchMoreBuyData() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 250));
    final more = moreFromJson(await loadJsonData('more_buy.json'));
    debugPrint('more length: ${more.length}');
    SelectEntries entries = more
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
            selectionMode: SelectionMode.multiple,
          ),
        )
        .toSet();
    debugPrint('more length: ${entries.length}');
    return Future.value(entries);
  }

  /// 排序 初始选中项
  SelectEntries? sortBuyResult;

  final sortBuyIniteialSelected = <SelectTextEntry>{
    SelectTextEntry.id(id: 'default_sort')
  };

  SelectEntries? fetchSortBuySelectedData() =>
      sortBuyResult ?? sortBuyIniteialSelected;

  SelectEntries? fetchSortBuyResetData() => sortBuyIniteialSelected;

  Future<SelectEntries> fetchSortBuyData() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 250));
    final sort = sortFromJson(await loadJsonData('sort_buy.json'));
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

  /// 排序 初始选中项
  SelectEntries? sortSellResult;

  final sortSellIniteialSelected = <SelectTextEntry>{
    SelectTextEntry.id(id: 'comprehensive_sort')
  };

  SelectEntries? fetchSortSellSelectedData() =>
      sortSellResult ?? sortSellIniteialSelected;

  SelectEntries? fetchSortSellResetData() => sortSellIniteialSelected;

  Future<SelectEntries> fetchSortSellData() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 250));
    final sort = sortFromJson(await loadJsonData('sort_sell.json'));
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

  /// 排序 初始选中项
  SelectEntries? sortRentResult;

  final sortRentIniteialSelected = <SelectTextEntry>{
    SelectTextEntry.id(id: 'comprehensive_sort')
  };

  SelectEntries? fetchSortRentSelectedData() =>
      sortRentResult ?? sortRentIniteialSelected;

  SelectEntries? fetchSortRentResetData() => sortRentIniteialSelected;

  Future<SelectEntries> fetchSortRentData() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 250));
    final sort = sortFromJson(await loadJsonData('sort_rent.json'));
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

class RegionData {
  String? id;
  String? name;
  bool? enabled;
  List<RegionData>? data;

  RegionData({this.id, this.name, this.data});

  RegionData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    enabled = json['enabled'];
    if (json['data'] != null) {
      data = <RegionData>[];
      json['data'].forEach((v) {
        data!.add(RegionData.fromJson(v));
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

  PriceItem({this.id, this.name, this.min, this.max});

  PriceItem.fromJson(Map<String, dynamic> json) {
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

List<FloorPlanData> floorPlanFromJson(String str) => List<FloorPlanData>.from(
    json.decode(str).map((x) => FloorPlanData.fromJson(x)));

String floorPlanToJson(List<FloorPlanData> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class FloorPlanData {
  String? id;
  String? name;
  List<FloorPlanItem>? data;

  FloorPlanData({this.id, this.name, this.data});

  FloorPlanData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    if (json['data'] != null) {
      data = <FloorPlanItem>[];
      json['data'].forEach((v) {
        data!.add(FloorPlanItem.fromJson(v));
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

class FloorPlanItem {
  String? id;
  String? name;
  int? min;
  int? max;

  FloorPlanItem({this.id, this.name, this.min, this.max});

  FloorPlanItem.fromJson(Map<String, dynamic> json) {
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

  MoreItem({this.id, this.name});

  MoreItem.fromJson(Map<String, dynamic> json) {
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
