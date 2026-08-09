import 'package:example/leyoujia/house_filters_repository.dart';
import 'package:example/leyoujia/house_repository.dart';
import 'package:example/leyoujia/utils.dart';
import 'package:example/widgets/my_widgets.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../log.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});
  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final PopupSelectController _controller = PopupSelectController();
  late final HouseRepository _repo;
  late final HouseFiltersRepository _filtersRepo;
  HouseFilter? _filter;

  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _repo = HouseRepository();
    _filtersRepo = HouseFiltersRepository();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        _controller.select(1, {'203', '403'});
      });
    });
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
  }

  @override
  void dispose() {
    _repo.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSelectApply(PopupTabData tabData, SelectEntries selected) {
    _filter ??= HouseFilter(cityId: userCityId);
    if (tabData.index == 0) {
      // 区域筛选
      _filtersRepo.regionResult = selected;
      final category = selected.firstOrNull;
      if (category == null) return;
      if (category.id == 'region') {
        // 行政区
        _filter?.district = selected
            .cascadingPairsOf('region')
            .map((p) => {
                  "district_id": p.id,
                  "subdistrict_id": p.childIds,
                })
            .toList(growable: false);
      } else if (category.id == 'metro') {
        // 地铁
        _filter?.metro = selected
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
        _filter?.nearbyRadiusMeters = nearbyRadiusMeters;
        _filter?.userLatLon = userLatLon;
      }
    } else if (tabData.index == 1) {
      // 价格筛选
      _filtersRepo.sellPriceResult = selected;
      final category = selected.firstOrNull;
      if (category == null) return;
      if (category.id == 'total') {
        // 总价
        _filter?.totalPrice = selected
            .childRangesOf('total')
            .map((e) => {
                  "id": e.id,
                  "min": e.min,
                  "max": e.max,
                })
            .toList(growable: false);
      } else if (category.id == 'downpay') {
        // 首付
        _filter?.unitPrice = selected
            .childRangesOf('downpay')
            .map((e) => {
                  "id": e.id,
                  "min": e.min,
                  "max": e.max,
                })
            .toList(growable: false);
      }
    } else if (tabData.index == 2) {
      // 户型筛选
      _filtersRepo.floorPlanSellResult = selected;
      _filter?.livingRoom = selected.childIdsOf('living_room');
      _filter?.bathroom = selected.childIdsOf('bathroom');
      _filter?.balcony = selected.childIdsOf('balcony');
      _filter?.area = selected
          .childRangesOf('area')
          .map((e) => {
                "id": e.id,
                "min": e.min,
                "max": e.max,
              })
          .toList(growable: false);
    } else if (tabData.index == 3) {
      // 排序筛选
      _filtersRepo.sortSellResult = selected;
      _filter?.sort = selected.firstSelectedId;
    }
    _repo.refreshData(_filter!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final PopupSelectBarTheme dropdownTabBarTheme =
        PopupSelectBarTheme.maybeOf(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.sell ?? ''),
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
          Theme(
            data: Theme.of(context).copyWith(
              extensions: <ThemeExtension<dynamic>>[
                dropdownTabBarTheme.copyWith(
                  labelColor: Colors.amber,
                  overlayStyle: dropdownTabBarTheme.overlayStyle?.copyWith(
                    maxHeightFactor: 0.8,
                  ),
                ),
              ],
            ),
            child: PopupSelectBar(
              controller: _controller,
              isScrollable: true,
              // labelColor: Colors.orange,
              // indicator: Icon(Icons.arrow_upward),
              // unselectedIndicator: Icon(Icons.arrow_downward),
              // overlayStyle: SelectOverlayStyle(
              //   barrierColor: Colors.orange[100],
              // ),
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
                  child:
                      Image.asset('assets/sorting.png', width: 16, height: 16),
                ),
              ],
              selectDelegates: [
                CascadingSelectDelegate(
                  isScrollable: true,
                  entriesLoader: _filtersRepo.fetchRegionData,
                  selectedEntriesLoader: _filtersRepo.fetchRegionSelectedData,
                  resetEntriesLoader: _filtersRepo.fetchRegionResetData,
                  selectionMode: SelectionMode.single,
                  // skeletonBuilder: (_) => const Center(
                  //     child: CircularProgressIndicator(
                  //   color: Colors.black,
                  // )),
                  // categoryBackgroundColor: Colors.grey[200]!,
                  // terminalBackgroundColor: Colors.white,
                  checkboxBuilder: (context, selected) {
                    return MyCheckbox(value: selected);
                  },
                ),
                GridSelectDelegate(
                  entriesLoader: _filtersRepo.fetchSellPriceData,
                  selectedEntriesLoader:
                      _filtersRepo.fetchSellPriceSelectedData,
                  resetEntriesLoader: _filtersRepo.fetchSellPriceResetData,
                  selectionMode: SelectionMode.multiple,
                  crossAxisCount: 4,
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                FlattenSelectDelegate(
                  entriesLoader: _filtersRepo.fetchFloorPlanSellData,
                  selectedEntriesLoader:
                      _filtersRepo.fetchFloorPlanSellSelectedData,
                  resetEntriesLoader: _filtersRepo.fetchFloorPlanSellResetData,
                  selectionMode: SelectionMode.multiple,
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  sideBarTheme: const SelectSideBarTheme(width: 98),
                ),
                ListSelectDelegate(
                  entriesLoader: _filtersRepo.fetchSortSellData,
                  selectedEntriesLoader: _filtersRepo.fetchSortSellSelectedData,
                  resetEntriesLoader: _filtersRepo.fetchSortSellResetData,
                  selectionMode: SelectionMode.single,
                  radioBuilder: (context, selected) {
                    return MyRadio(value: selected);
                  },
                ),
              ],
              onSelectShowed: (PopupTabData tabData) {
                largePrint('onShowed: ${tabData.label}');
              },
              onSelectHidden: (PopupTabData tabData) {
                largePrint('onHidden: ${tabData.label}');
              },
              onChanged: (tabData, selected) {
                largePrint('onChanged: tabData=$tabData, selected=$selected');
                final conditions = '${selected.flatten()}';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.selectResult(conditions) ?? conditions,
                    ),
                  ),
                );
              },
              onApplied: (tabData, selected) {
                largePrint('onApplied: tabData=$tabData, selected=$selected');
                _handleSelectApply(tabData, selected);
                final conditions = '${selected.flatten()}';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.selectResult(conditions) ?? conditions,
                    ),
                  ),
                );
              },
              onReset: () {
                debugPrint('onReset');
              },
            ),
          ),
          // ChoseChips
          // _controller.select();
          // _controller.showSelect();
          // _controller.hideSelect();
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
