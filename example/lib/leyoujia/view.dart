import 'package:example/widgets/my_widgets.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../log.dart';
import '../widgets/show_select_result.dart';
import 'house_filters_repository.dart';
import 'house_repository.dart';
import 'utils.dart';

class ViewPage extends StatefulWidget {
  const ViewPage({super.key});

  @override
  State<ViewPage> createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  late final HouseFiltersRepository _filtersRepo;
  HouseFilter? _filter;

  @override
  void initState() {
    super.initState();
    _filtersRepo = HouseFiltersRepository();
  }

  void _handleRegionChange(SelectEntries result) async {
    final l10n = AppLocalizations.of(context);
    _filter ??= HouseFilter(cityId: userCityId);
    // 区域
    _filtersRepo.regionResult = result;
    final category = result.firstOrNull;
    if (category == null) return null;
    if (category.id == 'region') {
      // 行政区
      _filter?.district = result
          .cascadingPairsOf('region')
          .map((p) => {
                "district_id": p.id,
                "subdistrict_id": p.childIds,
              })
          .toList(growable: false);
    } else if (category.id == 'metro') {
      // 地铁
      _filter?.metro = result
          .cascadingPairsOf('metro')
          .map((p) => {
                "line_id": p.id,
                "station_id": p.childIds,
              })
          .toList(growable: false);
    } else if (category.id == 'nearby') {
      // 附近
      final nearbyRadiusMeters = result.firstSelectedId;
      _filter?.nearbyRadiusMeters = nearbyRadiusMeters;
      _filter?.userLatLon = userLatLon;
    }

    if (_filter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.resultParseFailed ?? '')),
      );
      return;
    }
  }

  void _handlePriceChange(SelectEntries result) async {
    _filter ??= HouseFilter(cityId: userCityId);
    // 价格筛选
    _filtersRepo.buyPriceResult = result;
    final category = result.firstOrNull;
    if (category == null) return null;
    if (category.id == 'total') {
      // 总价
      _filter?.totalPrice = result
          .childRangesOf('total')
          .map((e) => {
                "id": e.id,
                "min": e.min,
                "max": e.max,
              })
          .toList(growable: false);
    }
    if (category.id == 'unit') {
      // 单价
      _filter?.unitPrice = result
          .childRangesOf('unit')
          .map((e) => {
                "id": e.id,
                "min": e.min,
                "max": e.max,
              })
          .toList(growable: false);
    }
  }

  void _handleFloorPlanChange(SelectEntries result) async {
    _filter ??= HouseFilter(cityId: userCityId);
    // 户型筛选
    _filtersRepo.floorPlanBuyResult = result;
    _filter?.livingRoom = result.childIdsOf('living_room');
    _filter?.bathroom = result.childIdsOf('bathroom');
    _filter?.balcony = result.childIdsOf('balcony');
    _filter?.area = result
        .childRangesOf('area')
        .map((e) => {
              "id": e.id,
              "min": e.min,
              "max": e.max,
            })
        .toList(growable: false);
  }

  void _handleSortChange(SelectEntries result) async {
    _filter = HouseFilter(cityId: userCityId);
    // 排序筛选
    _filtersRepo.sortBuyResult = result;
    _filter?.sort = result.firstSelectedId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SelectView')),
      body: SafeArea(
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选择区域',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: CascadingSelectDelegate(
                    entriesLoader: _filtersRepo.fetchRegionData,
                    selectedEntriesLoader: _filtersRepo.fetchRegionSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchRegionResetData,
                    selectionMode: SelectionMode.single,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                    checkboxBuilder: (context, selected) {
                      return MyCheckbox(value: selected);
                    },
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    _handleRegionChange(selected);
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  '选择价格',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: GridSelectDelegate(
                    entriesLoader: _filtersRepo.fetchBuyPriceData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchBuyPriceSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchBuyPriceResetData,
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 4,
                    childAspectRatio: 2.5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    gridTileTheme: const SelectGridTileTheme(
                      variant: SelectGridTileVariant.outlined,
                    ),
                    fieldTileTheme: const SelectFieldTileTheme(
                      variant: SelectFieldTileVariant.outlined,
                    ),
                    applyText: AppLocalizations.of(context)?.apply ?? '',
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    _handlePriceChange(selected);
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  '选择户型',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: FlattenSelectDelegate(
                    entriesLoader: _filtersRepo.fetchFloorPlanBuyData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchFloorPlanBuySelectedData,
                    resetEntriesLoader: _filtersRepo.fetchFloorPlanBuyResetData,
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    sideBarTheme: const SelectSideBarTheme(width: 98),
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    _handleFloorPlanChange(selected);
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  '选择排序',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: ListSelectDelegate(
                    entriesLoader: _filtersRepo.fetchSortBuyData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchSortBuySelectedData,
                    resetEntriesLoader: _filtersRepo.fetchSortBuyResetData,
                    selectionMode: SelectionMode.single,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    _handleSortChange(selected);
                    showSelectResult(context, selected);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
