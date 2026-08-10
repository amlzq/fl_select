import 'package:example/widgets/my_widgets.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../log.dart';
import '../widgets/show_select_result.dart';
import 'house_filters_repository.dart';
import 'house_repository.dart';
import 'utils.dart';

class ButtonDemoPage extends StatefulWidget {
  const ButtonDemoPage({super.key});

  @override
  State<ButtonDemoPage> createState() => _ButtonDemoPageState();
}

class _ButtonDemoPageState extends State<ButtonDemoPage> {
  late final HouseFiltersRepository _filtersRepo;
  HouseFilter? _filter;

  @override
  void initState() {
    super.initState();
    _filtersRepo = HouseFiltersRepository();
  }

  @override
  void dispose() {
    super.dispose();
  }

  HouseFilter? _parseFilter(String domain, SelectEntries selected) {
    final filter = HouseFilter(cityId: userCityId);
    if (domain == 'region') {
      // 区域
      final category = selected.firstOrNull;
      if (category == null) return null;
      if (category.id == 'region') {
        // 行政区
        filter.district = selected
            .cascadingPairsOf('region')
            .map((p) => {
                  "district_id": p.id,
                  "subdistrict_id": p.childIds,
                })
            .toList(growable: false);
      } else if (category.id == 'metro') {
        // 地铁
        filter.metro = selected
            .cascadingPairsOf('metro')
            .map((p) => {
                  "line_id": p.id,
                  "station_id": p.childIds,
                })
            .toList(growable: false);
      } else if (category.id == 'nearby') {
        // 附近
        final nearbyRadiusMeters =
            selected.findIdsAtLevel(category, 1).firstOrNull;
        filter.nearbyRadiusMeters = nearbyRadiusMeters;
        filter.userLatLon = userLatLon;
      }
    } else if (domain == 'price') {
      // 价格筛选
      final category = selected.firstOrNull;
      if (category == null) return null;
      if (category.id == 'total') {
        // 总价
        filter.totalPrice = selected
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
        filter.unitPrice = selected
            .childRangesOf('unit')
            .map((e) => {
                  "id": e.id,
                  "min": e.min,
                  "max": e.max,
                })
            .toList(growable: false);
      }
    } else if (domain == 'floorplan') {
      // 户型筛选
      filter.livingRoom = selected.childIdsOf('living_room');
      filter.bathroom = selected.childIdsOf('bathroom');
      filter.balcony = selected.childIdsOf('balcony');
      filter.area = selected
          .childRangesOf('area')
          .map((e) => {
                "id": e.id,
                "min": e.min,
                "max": e.max,
              })
          .toList(growable: false);
    } else if (domain == 'more') {
      // 更多筛选
      filter.homeType = selected.childIdsOf('home_type');
      filter.saleStatus = selected.childIdsOf('sale_status');
      filter.openTime = selected.childIdsOf('open_time');
      filter.deliveryTime = selected.childIdsOf('delivery_time');
      filter.decorationStatus = selected.childIdsOf('decoration_status');
      filter.buildingFeatures = selected.childIdsOf('building_features');
      filter.houseViewService = selected.childIdsOf('house_view_service');
    } else if (domain == 'sort') {
      // 排序筛选
      filter.sort = selected.firstSelectedId;
    }
    return filter;
  }

  void _handleSelectChange(String domain, SelectEntries selected) async {
    final l10n = AppLocalizations.of(context);
    _filter = _parseFilter(domain, selected);
    if (_filter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.resultParseFailed ?? '')),
      );
      return;
    }
  }

  void _handleSelectApply(String domain, SelectEntries selected) {
    final l10n = AppLocalizations.of(context);
    // Persist the applied selection to the repo so it can be restored on reopen.
    if (domain == 'region') {
      _filtersRepo.regionResult = selected;
    } else if (domain == 'price') {
      _filtersRepo.buyPriceResult = selected;
    } else if (domain == 'floorplan') {
      _filtersRepo.floorPlanBuyResult = selected;
    } else if (domain == 'more') {
      _filtersRepo.moreBuyResult = selected;
    } else if (domain == 'sort') {
      _filtersRepo.sortBuyResult = selected;
    }
    _filter = _parseFilter(domain, selected);
    if (_filter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.resultParseFailed ?? '')),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PopupSelectButton')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          PopupSelectButton(
            label: '区域',
            selectDelegate: CascadingSelectDelegate(
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
              largePrint('onChanged: $selected');
              _handleSelectChange('region', selected);
              showSelectResult(context, selected);
            },
            onApplied: (selected) {
              largePrint('onApplied: $selected');
              _handleSelectApply('region', selected);
              showSelectResult(context, selected);
            },
            onReset: () {
              debugPrint('onReset');
            },
          ),
          Center(
            child: PopupSelectButton.elevated(
              label: '价格',
              labelLoader: (selected) {
                return '价格${selected.length}';
              },
              selectDelegate: GridSelectDelegate(
                entriesLoader: _filtersRepo.fetchBuyPriceData,
                selectedEntriesLoader: _filtersRepo.fetchBuyPriceSelectedData,
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
                panelTheme: const SelectPanelTheme(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  clipBehavior: Clip.antiAlias,
                ),
                applyText: AppLocalizations.of(context)?.apply ?? '',
              ),
              onChanged: (selected) {
                largePrint('onChanged: $selected');
                _handleSelectChange('price', selected);
                showSelectResult(context, selected);
              },
              onApplied: (selected) {
                largePrint('onApplied: $selected');
                _handleSelectApply('price', selected);
                showSelectResult(context, selected);
              },
              onReset: () {
                debugPrint('onReset');
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: PopupSelectButton.outlined(
              label: '户型',
              selectDelegate: FlattenSelectDelegate(
                entriesLoader: _filtersRepo.fetchFloorPlanBuyData,
                selectedEntriesLoader:
                    _filtersRepo.fetchFloorPlanBuySelectedData,
                resetEntriesLoader: _filtersRepo.fetchFloorPlanBuyResetData,
                selectionMode: SelectionMode.multiple,
                sideBarTheme: const SelectSideBarTheme(width: 98),
              ),
              onChanged: (selected) {
                largePrint('onChanged: $selected');
                _handleSelectChange('floorplan', selected);
                showSelectResult(context, selected);
              },
              onApplied: (selected) {
                largePrint('onApplied: $selected');
                _handleSelectApply('floorplan', selected);
                showSelectResult(context, selected);
              },
              onReset: () {
                debugPrint('onReset');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: PopupSelectButton(
              label: '更多',
              icon: const Icon(Icons.filter_alt_outlined),
              selectDelegate: ListSelectDelegate(
                entriesLoader: _filtersRepo.fetchSortBuyData,
                selectedEntriesLoader: _filtersRepo.fetchSortBuySelectedData,
                resetEntriesLoader: _filtersRepo.fetchSortBuyResetData,
                selectionMode: SelectionMode.single,
                radioBuilder: (context, selected) {
                  return MyRadio(value: selected);
                },
              ),
              onChanged: (selected) {
                largePrint('onChanged: $selected');
                _handleSelectChange('sort', selected);
                showSelectResult(context, selected);
              },
              onApplied: (selected) {
                largePrint('onApplied: $selected');
                _handleSelectApply('sort', selected);
                showSelectResult(context, selected);
              },
              onReset: () {
                debugPrint('onReset');
              },
            ),
          ),
        ],
      ),
    );
  }
}
