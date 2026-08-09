import 'dart:async';
import 'dart:convert';

import 'dart:math';

import 'package:flutter/foundation.dart';

import 'utils.dart';

/// 房源分页数据源（与具体 House 类型解耦，本文件内私有实现）。
///
/// 在有限的真实 mock 数据之上"制造假象"：
/// 1. 通过 [clone] 回调把 [baseLoader] 返回的基础数据复制扩展成一个
///    最多 [maxPages] * [pageSize] 条的房源池；
/// 2. 每次 [applyFilter] 随机裁剪出 S 条，约束
///    [minPages] * [pageSize] <= S <= [maxPages] * [pageSize]，
///    即保证筛选结果至少 [minPages] 页、最多 [maxPages] 页；
/// 3. [loadNextPage] 向 [displayed] 累计追加一页（[pageSize] 条），
///    供页面"滚动到底加载更多"使用。
class _HousePager<H> {
  final int pageSize;
  final int minPages;
  final int maxPages;

  /// 返回基础（真实）房源列表，数据源会在此之上复制扩展。
  final List<H> Function() baseLoader;

  /// 克隆单条房源并赋予新的唯一 [newId]（用于制造分页假象）。
  final H Function(H base, String newId) clone;

  _HousePager({
    required this.baseLoader,
    required this.clone,
    this.pageSize = 20,
    this.minPages = 3,
    this.maxPages = 9,
  })  : assert(minPages <= maxPages),
        assert(pageSize > 0);

  List<H>? _pool;
  List<H> _displayed = const [];
  int _totalCount = 0;

  /// 已加载的累计列表。
  List<H> get displayed => _displayed;

  /// 是否还有更多页可加载。
  bool get hasMore => _displayed.length < _totalCount;

  /// 当前筛选结果总量（约束在 [minPages, maxPages] * [pageSize] 之间）。
  int get totalCount => _totalCount;

  /// 总页数（3~9）。
  int get totalPages =>
      _totalCount == 0 ? 0 : (_totalCount / pageSize).ceil();

  /// 已加载条数。
  int get loadedCount => _displayed.length;

  /// 已加载页数。
  int get loadedPages =>
      _displayed.isEmpty ? 0 : (_displayed.length / pageSize).ceil();

  /// 预览用：在不改动已加载进度的前提下，估算一个总量（落在 3~9 页范围）。
  int estimateTotal() =>
      minPages * pageSize +
      Random().nextInt((maxPages - minPages) * pageSize + 1);

  /// 应用筛选条件：重建房源池并重置进度，返回首页（[pageSize] 条）。
  List<H> applyFilter({Object? filter}) {
    final base = baseLoader();
    final poolSize = maxPages * pageSize;

    if (base.isEmpty) {
      _pool = const [];
      _totalCount = 0;
      _displayed = const [];
      return _displayed;
    }

    // 制造假象：把少量基础数据复制扩展为 poolSize 条的池子。
    final baseShuffled = [...base]..shuffle();
    final pool = <H>[];
    for (var i = 0; i < poolSize; i++) {
      final baseItem = baseShuffled[i % baseShuffled.length];
      pool.add(clone(baseItem, 'gen_$i'));
    }
    _pool = pool;

    // 约束总量在 [minPages, maxPages] * pageSize 之间，保证 3~9 页。
    final minCount = minPages * pageSize;
    final maxCount = maxPages * pageSize;
    _totalCount = minCount + Random().nextInt(maxCount - minCount + 1);

    // 重置进度并取首页。
    _displayed = pool.take(pageSize).toList();
    return _displayed;
  }

  /// 加载下一页（[pageSize] 条），追加到 [displayed] 并返回累计列表。
  List<H> loadNextPage() {
    if (!hasMore || _pool == null) return _displayed;
    final next = _pool!.skip(_displayed.length).take(pageSize).toList();
    _displayed = [..._displayed, ...next];
    if (_displayed.length > _totalCount) {
      _displayed = _displayed.take(_totalCount).toList();
    }
    return _displayed;
  }
}

class HouseRepository {
  // 一个实时数据流，推送"已加载累计列表"
  final StreamController<List<House>> _controller =
      StreamController.broadcast();

  late final _HousePager<House> _paging;
  List<House> _baseHouses = const [];

  HouseRepository() {
    _paging = _HousePager<House>(
      baseLoader: () => _baseHouses,
      clone: (base, newId) => base.copyWith(id: newId),
    );
    _loadInitialData();
  }

  Stream<List<House>> get housesStream => _controller.stream;

  void _loadInitialData() async {
    try {
      _baseHouses = houseFromJson(await loadJsonData('house.json'));
      final firstPage = _paging.applyFilter();
      debugPrint('initial houses.length: ${firstPage.length}, '
          'totalCount: ${_paging.totalCount}');
      _controller.add(firstPage);
    } catch (e, st) {
      _controller.addError(e, st);
    }
  }

  /// 预览数量：返回当前筛选"假象"下的估算总量（3~9 页）。
  Future<int> previewCount(HouseFilter filterParams) async {
    debugPrint('previewCount filterParams: ${filterParams.toJson()}');
    await Future.delayed(const Duration(milliseconds: 250));
    return _paging.estimateTotal();
  }

  /// 刷新：应用筛选条件，重建房源池并先推送首页。
  void refreshData(HouseFilter filterParams) async {
    debugPrint('refreshData filterParams: ${filterParams.toJson()}');
    await Future.delayed(const Duration(milliseconds: 250));
    try {
      final firstPage = _paging.applyFilter(filter: filterParams);
      debugPrint('refreshData totalCount: ${_paging.totalCount}, '
          'firstPage: ${firstPage.length}');
      _controller.add(firstPage);
    } catch (e, st) {
      _controller.addError(e, st);
    }
  }

  /// 加载下一页（模拟网络延迟），并向 stream 推送累计列表。
  Future<void> loadNextPage() async {
    if (!_paging.hasMore) return;
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final next = _paging.loadNextPage();
      debugPrint('loadNextPage loaded: ${_paging.loadedCount}/'
          '${_paging.totalCount}');
      _controller.add(next);
    } catch (e, st) {
      _controller.addError(e, st);
    }
  }

  bool get hasMore => _paging.hasMore;
  int get totalPages => _paging.totalPages;
  int get totalCount => _paging.totalCount;
  int get loadedPages => _paging.loadedPages;

  void dispose() => _controller.close();
}

class HouseFilter {
  String? cityId;
  List<Map<String, dynamic>>? district;
  List<Map<String, dynamic>>? metro;
  (String, String)? userLatLon;
  String? nearbyRadiusMeters;
  List<Map<String, dynamic>>? totalPrice;
  List<Map<String, dynamic>>? unitPrice;
  List<Map<String, dynamic>>? rent;
  List<Map<String, dynamic>>? downPay;
  List<String>? livingRoom;
  List<String>? bathroom;
  List<String>? balcony;
  List<Map<String, dynamic>>? area;
  List<String>? homeType;
  List<String>? saleStatus;
  List<String>? openTime;
  List<String>? deliveryTime;
  List<String>? decorationStatus;
  List<String>? buildingFeatures;
  List<String>? houseViewService;
  String? sort;

  HouseFilter({
    required this.cityId,
    this.district,
    this.metro,
    this.userLatLon,
    this.nearbyRadiusMeters,
    this.livingRoom,
    this.bathroom,
    this.balcony,
    this.area,
    this.homeType,
    this.saleStatus,
    this.openTime,
    this.deliveryTime,
    this.decorationStatus,
    this.buildingFeatures,
    this.houseViewService,
    this.sort,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['city_id'] = cityId;
    data['district'] = district;
    data['metro'] = metro;
    data['user_lat_lon'] = userLatLon;
    data['nearby_radius_meters'] = nearbyRadiusMeters;
    data['total_price'] = totalPrice;
    data['unit_price'] = unitPrice;
    data['rent_amount'] = rent;
    data['down_pay'] = downPay;
    data['living_room'] = livingRoom;
    data['bathroom'] = bathroom;
    data['balcony'] = balcony;
    data['area'] = area;
    data['home_type'] = homeType;
    data['sale_status'] = saleStatus;
    data['open_time'] = openTime;
    data['delivery_time'] = deliveryTime;
    data['decoration_status'] = decorationStatus;
    data['building_features'] = buildingFeatures;
    data['house_view_service'] = houseViewService;
    data['sort'] = sort;
    return data;
  }
}

List<House> houseFromJson(String str) =>
    List<House>.from(json.decode(str).map((x) => House.fromJson(x)));

String houseToJson(List<House> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class House {
  String? id;
  String? picture;
  String? title;
  String? second;
  String? price;
  String? unitPrice;
  String? address;
  String? city;
  String? cityId;
  String? district;
  String? districtId;
  String? subdistrict;
  String? subdistrictId;
  String? community;
  String? line;
  String? lineId;
  String? stationId;
  String? station;
  String? lat;
  String? lon;
  String? floor;
  String? area;
  String? type;
  String? orientation;
  String? decoration;
  String? builtYear;

  House(
      {this.id,
      this.picture,
      this.title,
      this.second,
      this.price,
      this.unitPrice,
      this.address,
      this.city,
      this.cityId,
      this.district,
      this.districtId,
      this.subdistrict,
      this.subdistrictId,
      this.community,
      this.line,
      this.lineId,
      this.stationId,
      this.station,
      this.lat,
      this.lon,
      this.floor,
      this.area,
      this.type,
      this.orientation,
      this.decoration,
      this.builtYear});

  House.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    picture = json['picture'];
    title = json['title'];
    second = json['second'];
    price = json['price'];
    unitPrice = json['unitPrice'];
    address = json['address'];
    city = json['city'];
    cityId = json['city_id'];
    district = json['district'];
    districtId = json['district_id'];
    subdistrict = json['subdistrict'];
    subdistrictId = json['subdistrict_id'];
    community = json['community'];
    line = json['line'];
    lineId = json['line_id'];
    stationId = json['station_id'];
    station = json['station'];
    lat = json['lat'];
    lon = json['lon'];
    floor = json['floor'];
    area = json['area'];
    type = json['type'];
    orientation = json['orientation'];
    decoration = json['decoration'];
    builtYear = json['builtYear'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['picture'] = picture;
    data['title'] = title;
    data['second'] = second;
    data['price'] = price;
    data['unitPrice'] = unitPrice;
    data['address'] = address;
    data['city'] = city;
    data['city_id'] = cityId;
    data['district'] = district;
    data['district_id'] = districtId;
    data['subdistrict'] = subdistrict;
    data['subdistrict_id'] = subdistrictId;
    data['community'] = community;
    data['line'] = line;
    data['line_id'] = lineId;
    data['station_id'] = stationId;
    data['station'] = station;
    data['lat'] = lat;
    data['lon'] = lon;
    data['floor'] = floor;
    data['area'] = area;
    data['type'] = type;
    data['orientation'] = orientation;
    data['decoration'] = decoration;
    data['builtYear'] = builtYear;
    return data;
  }

  House copyWith({String? id}) => House(
        id: id ?? this.id,
        picture: picture,
        title: title,
        second: second,
        price: price,
        unitPrice: unitPrice,
        address: address,
        city: city,
        cityId: cityId,
        district: district,
        districtId: districtId,
        subdistrict: subdistrict,
        subdistrictId: subdistrictId,
        community: community,
        line: line,
        lineId: lineId,
        stationId: stationId,
        station: station,
        lat: lat,
        lon: lon,
        floor: floor,
        area: area,
        type: type,
        orientation: orientation,
        decoration: decoration,
        builtYear: builtYear,
      );
}
