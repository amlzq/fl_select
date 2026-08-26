import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'utils.dart';

/// A house paging data source (decoupled from the concrete House type;
/// private implementation within this file).
///
/// It "fakes" a large dataset on top of limited real mock data:
/// 1. Uses the [clone] callback to copy-expand the base list returned by
///    [baseLoader] into a pool of at most [maxPages] * [pageSize] houses;
/// 2. Each [applyFilter] randomly trims S entries, constrained so
///    [minPages] * [pageSize] <= S <= [maxPages] * [pageSize],
///    i.e. guarantees the filtered result is at least [minPages] pages
///    and at most [maxPages] pages;
/// 3. [loadNextPage] appends one more page ([pageSize] entries) to
///    [displayed], used by the page's "scroll to bottom to load more".
class _HousePager<H> {
  final int pageSize;
  final int minPages;
  final int maxPages;

  /// Returns the base (real) house list; the source copies-expands on top of it.
  final List<H> Function() baseLoader;

  /// Clones a single house and assigns a new unique [newId] (for faking paging).
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

  /// The cumulative loaded list.
  List<H> get displayed => _displayed;

  /// Whether there are more pages to load.
  bool get hasMore => _displayed.length < _totalCount;

  /// The total count of the current filter result
  /// (constrained to [minPages, maxPages] * [pageSize]).
  int get totalCount => _totalCount;

  /// Total page count (3~9).
  int get totalPages => _totalCount == 0 ? 0 : (_totalCount / pageSize).ceil();

  /// Number of loaded entries.
  int get loadedCount => _displayed.length;

  /// Number of loaded pages.
  int get loadedPages =>
      _displayed.isEmpty ? 0 : (_displayed.length / pageSize).ceil();

  /// For preview: estimates a total count (in the 3~9 pages range) without
  /// changing the current loading progress.
  int estimateTotal() =>
      minPages * pageSize +
      Random().nextInt((maxPages - minPages) * pageSize + 1);

  /// Applies the filter: rebuilds the pool, resets progress, and returns the
  /// first page ([pageSize] entries).
  List<H> applyFilter({Object? filter}) {
    final base = baseLoader();
    final poolSize = maxPages * pageSize;

    if (base.isEmpty) {
      _pool = const [];
      _totalCount = 0;
      _displayed = const [];
      return _displayed;
    }

    // Fake it: copy-expand the few base entries into a pool of poolSize.
    final baseShuffled = [...base]..shuffle();
    final pool = <H>[];
    for (var i = 0; i < poolSize; i++) {
      final baseItem = baseShuffled[i % baseShuffled.length];
      pool.add(clone(baseItem, 'gen_$i'));
    }
    _pool = pool;

    // Constrain the total to [minPages, maxPages] * pageSize, i.e. 3~9 pages.
    final minCount = minPages * pageSize;
    final maxCount = maxPages * pageSize;
    _totalCount = minCount + Random().nextInt(maxCount - minCount + 1);

    // Reset progress and take the first page.
    _displayed = pool.take(pageSize).toList();
    return _displayed;
  }

  /// Loads the next page ([pageSize] entries), appends to [displayed],
  /// and returns the cumulative list.
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
  // A realtime data stream, pushing the "loaded cumulative list"
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

  /// Preview count: estimate total under the current "illusion" (3~9 pages).
  Future<int> previewCount(HouseFilter filterParams) async {
    debugPrint('previewCount filterParams: ${filterParams.toJson()}');
    await Future.delayed(const Duration(milliseconds: 250));
    return _paging.estimateTotal();
  }

  // Refresh
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

  /// Load the next page (simulated network delay) and push cumulative list.
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
  List<Map<String, dynamic>>? neighborhood;
  List<Map<String, dynamic>>? listPrice;
  List<Map<String, dynamic>>? monthlyPayment;
  List<String>? bedrooms;
  List<String>? bathrooms;
  List<String>? homeType;
  List<String>? listsDetails;
  List<String>? squareFeet;
  List<String>? lotSize;
  List<String>? homeFeatures;
  List<String>? commute;
  List<String>? expandedSearch;
  String? sort;

  HouseFilter({
    required this.cityId,
    this.neighborhood,
    this.listPrice,
    this.monthlyPayment,
    this.bedrooms,
    this.bathrooms,
    this.homeType,
    this.listsDetails,
    this.squareFeet,
    this.lotSize,
    this.homeFeatures,
    this.commute,
    this.expandedSearch,
    this.sort,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['city_id'] = cityId;
    data['neighborhood'] = neighborhood;
    data['list_price'] = listPrice;
    data['monthly_payment'] = monthlyPayment;
    data['bedrooms'] = bedrooms;
    data['bathrooms'] = bathrooms;
    data['home_type'] = homeType;
    data['lists_details'] = listsDetails;
    data['square_feet'] = squareFeet;
    data['lot_size'] = lotSize;
    data['home_features'] = homeFeatures;
    data['commute'] = commute;
    data['expanded_search'] = expandedSearch;
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
  String? tag;
  String? title;
  String? second;
  String? price;
  String? unitPrice;
  String? address;
  String? city;
  String? cityId;
  String? district;
  String? districtId;
  String? lat;
  String? lon;
  String? area;
  String? type;
  String? builtYear;

  House(
      {this.id,
      this.picture,
      this.tag,
      this.title,
      this.second,
      this.price,
      this.unitPrice,
      this.address,
      this.city,
      this.cityId,
      this.district,
      this.districtId,
      this.lat,
      this.lon,
      this.area,
      this.type,
      this.builtYear});

  House.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    picture = json['picture'];
    tag = json['tag'];
    title = json['title'];
    second = json['second'];
    price = json['price'];
    unitPrice = json['unitPrice'];
    address = json['address'];
    city = json['city'];
    cityId = json['city_id'];
    district = json['district'];
    districtId = json['district_id'];
    lat = json['lat'];
    lon = json['lon'];
    area = json['area'];
    type = json['type'];
    builtYear = json['builtYear'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['picture'] = picture;
    data['tag'] = tag;
    data['title'] = title;
    data['second'] = second;
    data['price'] = price;
    data['unitPrice'] = unitPrice;
    data['address'] = address;
    data['city'] = city;
    data['city_id'] = cityId;
    data['district'] = district;
    data['district_id'] = districtId;
    data['lat'] = lat;
    data['lon'] = lon;
    data['area'] = area;
    data['type'] = type;
    data['builtYear'] = builtYear;
    return data;
  }

  House copyWith({String? id}) => House(
        id: id ?? this.id,
        picture: picture,
        tag: tag,
        title: title,
        second: second,
        price: price,
        unitPrice: unitPrice,
        address: address,
        city: city,
        cityId: cityId,
        district: district,
        districtId: districtId,
        lat: lat,
        lon: lon,
        area: area,
        type: type,
        builtYear: builtYear,
      );
}
