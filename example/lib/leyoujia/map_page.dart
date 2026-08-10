import 'dart:async';

import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../log.dart';
import '../widgets/show_select_result.dart';
import 'house_filters_repository.dart';
import 'house_repository.dart';
import 'utils.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final PopupSelectController _controller = PopupSelectController();
  late final HouseRepository _repo;
  late final HouseFiltersRepository _filtersRepo;
  HouseFilter? _filter;

  final ValueNotifier<String> _floorPlanApplyText = ValueNotifier<String>('');
  Timer? _floorPlanApplyTextDebounce;
  int _floorPlanApplyTextRequestId = 0;

  @override
  void initState() {
    super.initState();
    _repo = HouseRepository();
    _filtersRepo = HouseFiltersRepository();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    _filtersRepo.updateTexts(
      anyEntryText: l10n?.any ?? '',
      customInputLabel: l10n?.custom ?? '',
      minHintText: l10n?.minHint ?? '',
      maxHintText: l10n?.maxHint ?? '',
      customAreaName: l10n?.customArea ?? '',
    );
    if (_floorPlanApplyText.value.isEmpty) {
      _floorPlanApplyText.value = l10n?.apply ?? '';
    }
  }

  @override
  void dispose() {
    _repo.dispose();
    _controller.dispose();
    _floorPlanApplyTextDebounce?.cancel();
    _floorPlanApplyText.dispose();
    super.dispose();
  }

  HouseFilter? _popupSelectResultParser(
      PopupTabData tabData, SelectEntries selected) {
    final filter = HouseFilter(cityId: userCityId);
    if (tabData.index == 0) {
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
    } else if (tabData.index == 1) {
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
      } else if (category.id == 'unit') {
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
    } else if (tabData.index == 2) {
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
    } else if (tabData.index == 3) {
      // 排序筛选
      filter.sort = selected.firstSelectedId;
    }
    return filter;
  }

  void _handleSelectChange(PopupTabData tabData, SelectEntries selected) async {
    final l10n = AppLocalizations.of(context);
    _filter = _popupSelectResultParser(tabData, selected);
    if (_filter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.resultParseFailed ?? '')),
      );
      return;
    }
    if (tabData.index == 2) {
      _floorPlanApplyTextDebounce?.cancel();

      final requestId = ++_floorPlanApplyTextRequestId;
      _floorPlanApplyText.value = l10n?.viewing ?? '';

      _floorPlanApplyTextDebounce = Timer(
        const Duration(milliseconds: 250),
        () async {
          try {
            final count = await _repo.previewCount(_filter!);
            if (!mounted || requestId != _floorPlanApplyTextRequestId) return;
            final l10n = AppLocalizations.of(context);
            _floorPlanApplyText.value = count == 0
                ? (l10n?.nohomes ?? '')
                : (l10n?.viewhomes(count) ?? '');
          } catch (_) {
            if (!mounted || requestId != _floorPlanApplyTextRequestId) return;
            _floorPlanApplyText.value =
                AppLocalizations.of(context)?.apply ?? '';
          }
        },
      );
    }
  }

  void _handleSelectApply(PopupTabData tabData, SelectEntries selected) {
    showSelectResult(context, selected);

    // Persist the applied selection to the repo so it can be restored on reopen.
    if (tabData.index == 0) {
      _filtersRepo.regionResult = selected;
    } else if (tabData.index == 1) {
      _filtersRepo.buyPriceResult = selected;
    } else if (tabData.index == 2) {
      _filtersRepo.floorPlanBuyResult = selected;
    } else if (tabData.index == 3) {
      _filtersRepo.sortBuyResult = selected;
    }

    final l10n = AppLocalizations.of(context);
    _filter = _popupSelectResultParser(tabData, selected);
    if (_filter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.resultParseFailed ?? '')),
      );
      return;
    }

    _repo.refreshData(_filter!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final PopupSelectBarTheme dropdownTabBarTheme =
        PopupSelectBarTheme.maybeOf(context)!;
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          dropdownTabBarTheme.copyWith(
            labelColor: Colors.deepOrange,
            overlayStyle: dropdownTabBarTheme.overlayStyle?.copyWith(
              maxHeightFactor: 0.8,
            ),
          ),
        ],
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n?.onMap ?? ''),
          bottom: PopupSelectBar(
            controller: _controller,
            tabs: [
              PopupTab(
                // tag: 'region',
                label: l10n?.region ?? '',
                // labelLoader: (tabData, selected) {
                //   // 可选：用户根据结果自定义标签
                //   return '自定义标签';
                // },
              ),
              PopupTab(label: l10n?.price ?? ''),
              PopupTab(label: l10n?.floorPlan ?? ''),
              PopupTab(
                child: Image.asset('assets/sorting.png', width: 16, height: 16),
              ),
            ],
            selectDelegates: [
              CascadingSelectDelegate(
                entriesLoader: _filtersRepo.fetchRegionData,
                selectedEntriesLoader: _filtersRepo.fetchRegionSelectedData,
                resetEntriesLoader: _filtersRepo.fetchRegionResetData,
                selectionMode: SelectionMode.single,
              ),
              GridSelectDelegate(
                entriesLoader: _filtersRepo.fetchBuyPriceData,
                selectedEntriesLoader: _filtersRepo.fetchBuyPriceSelectedData,
                selectionMode: SelectionMode.single,
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
              ),
              FlattenSelectDelegate(
                entriesLoader: _filtersRepo.fetchFloorPlanBuyData,
                selectedEntriesLoader:
                    _filtersRepo.fetchFloorPlanBuySelectedData,
                resetEntriesLoader: _filtersRepo.fetchFloorPlanBuyResetData,
                selectionMode: SelectionMode.multiple,
              ),
              ListSelectDelegate(
                entriesLoader: _filtersRepo.fetchSortBuyData,
                selectedEntriesLoader: _filtersRepo.fetchSortBuySelectedData,
                resetEntriesLoader: _filtersRepo.fetchSortBuyResetData,
                selectionMode: SelectionMode.single,
              ),
            ],
            onChanged: (tabData, selected) {
              largePrint('onChanged: tabData=$tabData, selected=$selected');
              _handleSelectChange(tabData, selected);
            },
            onApplied: (tabData, selected) {
              largePrint('onApplied: tabData=$tabData, selected=$selected');
              _handleSelectApply(tabData, selected);
            },
            onReset: () {
              debugPrint('onReset');
            },
          ),
        ),
        body: StreamBuilder<List<House>>(
          stream: _repo.housesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  l10n?.loadError('${snapshot.error}') ?? '${snapshot.error}',
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(l10n?.nohomes ?? ''));
            }
            final houses = snapshot.data!;
            return ListView.builder(
              itemCount: houses.length,
              itemBuilder: (context, index) {
                final house = houses[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: AspectRatio(
                      aspectRatio: 120 / 80,
                      child: Image.asset(
                        house.picture ?? '',
                        width: 120,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(house.title ?? ''),
                    subtitle: Text(house.price ?? ''),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
