import 'dart:async';

import 'package:example/leyoujia/house_filters_repository.dart';
import 'package:example/widgets/my_widgets.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../log.dart';
import '../widgets/show_select_result.dart';
import 'house_repository.dart';
import 'utils.dart';

class RentPage extends StatefulWidget {
  const RentPage({super.key});
  @override
  State<RentPage> createState() => _RentPageState();
}

class _RentPageState extends State<RentPage> {
  final PopupSelectController _controller = PopupSelectController();
  late final HouseRepository _repo;
  late final HouseFiltersRepository _filtersRepo;
  HouseFilter? _filter;

  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  final ValueNotifier<String> _floorPlanApplyText = ValueNotifier<String>('');
  Timer? _floorPlanApplyTextDebounce;
  int _floorPlanApplyTextRequestId = 0;

  @override
  void initState() {
    super.initState();
    _repo = HouseRepository();
    _filtersRepo = HouseFiltersRepository();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (maxScroll - current < 200 && _repo.hasMore && !_isLoadingMore) {
      _loadMore();
    }
  }

  void _loadMore() async {
    if (_isLoadingMore || !_repo.hasMore) return;
    if (!mounted) return;
    setState(() => _isLoadingMore = true);
    try {
      await _repo.loadNextPage();
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
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
    _scrollController.dispose();
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
      if (category.id == 'rent') {
        // 租金
        filter.rent = selected
            .childRangesOf('rent')
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
    final l10n = AppLocalizations.of(context);
    // Persist the applied selection to the repo so it can be restored on reopen.
    if (tabData.index == 0) {
      _filtersRepo.regionResult = selected;
    } else if (tabData.index == 1) {
      _filtersRepo.rentalResult = selected;
    } else if (tabData.index == 2) {
      _filtersRepo.floorPlanRentResult = selected;
    } else if (tabData.index == 3) {
      _filtersRepo.sortRentResult = selected;
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.rent ?? ''),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child:
                Image.asset('assets/realestate/banner.jpg', fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PopupSelectBar(
              controller: _controller,
              // labelColor: Colors.orange,
              // indicator: Icon(Icons.arrow_upward, size: 16),
              // unselectedIndicator: Icon(Icons.arrow_downward, size: 16),
              // overlayStyle: SelectOverlayStyle(
              //   barrierColor: Colors.orange.withOpacity(0.54),
              // ),
              tabs: [
                PopupTab(
                  // tag: 'region',
                  label: l10n?.region ?? '',
                  // labelLoader: (PopupTabData tabData, SelectEntries selected) {
                  //   // 可选：用户根据结果自定义标签
                  //   return '自定义标签';
                  // },
                ),
                PopupTab(label: l10n?.price ?? ''),
                PopupTab(label: l10n?.floorPlan ?? ''),
                PopupTab(
                  child:
                      Image.asset('assets/sorting.png', width: 16, height: 16),
                ),
              ],
              selectDelegates: [
                CascadingSelectDelegate(
                  entriesLoader: () =>
                      _filtersRepo.fetchRegionData(singleAll: true),
                  selectedEntries: _filtersRepo.regionSelectedData,
                  resetEntries: _filtersRepo.regionResetData,
                  selectionMode: SelectionMode.single,
                  // skeletonBuilder: (_) => const Center(
                  //     child: CircularProgressIndicator(
                  //   color: Colors.black,
                  // )),
                  // categoryBackgroundColor: Colors.grey[200]!,
                  // terminalBackgroundColor: Colors.white,
                  radioBuilder: (context, selected) {
                    return MyRadio(value: selected);
                  },
                  checkboxBuilder: (context, selected) {
                    return MyCheckbox(value: selected);
                  },
                ),
                GridSelectDelegate(
                  entriesLoader: _filtersRepo.fetchRentalData,
                  selectedEntries: _filtersRepo.fetchRentalSelectedData,
                  resetEntries: _filtersRepo.fetchRentalResetData,
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
                  entriesLoader: () =>
                      _filtersRepo.fetchFloorPlanRentData(singleAll: true),
                  selectedEntries: _filtersRepo.floorPlanRentSelectedData,
                  resetEntries: _filtersRepo.floorPlanRentResetData,
                  selectionMode: SelectionMode.single,
                  actionBarBuilder: (
                    context, {
                    required onResetTap,
                    required onApplyTap,
                  }) {
                    return MyActionBar(
                      applyTextVN: _floorPlanApplyText,
                      onResetTap: onResetTap,
                      onApplyTap: onApplyTap,
                    );
                  },
                ),
                ListSelectDelegate(
                  entriesLoader: _filtersRepo.fetchSortRentData,
                  selectedEntries: _filtersRepo.sortRentSelectedData,
                  resetEntries: _filtersRepo.sortRentResetData,
                  selectionMode: SelectionMode.single,
                  radioBuilder: (context, selected) {
                    return MyRadio(value: selected);
                  },
                ),
              ],
              onSelectShowed: (PopupTabData tabData) {
                largePrint('onShowed: $tabData');
              },
              onSelectHidden: (PopupTabData tabData) {
                largePrint('onHidden: $tabData');
              },
              onChanged: (PopupTabData tabData, SelectEntries selected) {
                largePrint('onChanged: tabData=$tabData, selected=$selected');
                _handleSelectChange(tabData, selected);
                showSelectResult(context, selected);
              },
              onApplied: (PopupTabData tabData, SelectEntries selected) {
                largePrint('onApplied: tabData=$tabData, selected=$selected');
                _handleSelectApply(tabData, selected);
                if (tabData.index == 2) {
                  _floorPlanApplyTextDebounce?.cancel();
                  _floorPlanApplyTextRequestId++;
                  _floorPlanApplyText.value = l10n?.apply ?? '';
                }
                showSelectResult(context, selected);
              },
              onReset: () {
                debugPrint('onReset');
                if (_controller.currentIndex == 2) {
                  _floorPlanApplyTextDebounce?.cancel();
                  _floorPlanApplyTextRequestId++;
                  _floorPlanApplyText.value = l10n?.apply ?? '';
                }
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<House>>(
              stream: _repo.housesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      l10n?.loadError('${snapshot.error}') ??
                          '${snapshot.error}',
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(l10n?.nohomes ?? ''));
                }
                final houses = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: houses.length + 1,
                  itemBuilder: (context, index) {
                    if (index == houses.length) {
                      return HouseListFooter(
                        isLoadingMore: _isLoadingMore,
                        hasMore: _repo.hasMore,
                        pageInfo:
                            '第 ${_repo.loadedPages} / ${_repo.totalPages} 页',
                        noMoreText: l10n?.noMore,
                      );
                    }
                    final house = houses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
        ],
      ),
    );
  }
}
