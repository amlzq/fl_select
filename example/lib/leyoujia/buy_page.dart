import 'dart:async';

import 'package:example/leyoujia/house_filters_repository.dart';
import 'package:example/leyoujia/house_repository.dart';
import 'package:example/leyoujia/utils.dart';
import 'package:example/log.dart';
import 'package:example/widgets/my_widgets.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generated/l10n/app_localizations.dart';
import '../widgets/show_select_result.dart';

const _bannerHeight = 150.0;
const _filterBarHeight = 44.0;
const _chipBarHeight = 48.0;
const _filterHeaderHeight = _filterBarHeight + _chipBarHeight;

class BuyPage extends StatefulWidget {
  const BuyPage({super.key});
  @override
  State<BuyPage> createState() => _BuyPageState();
}

class _BuyPageState extends State<BuyPage> {
  final PopupSelectController _controller = PopupSelectController();
  late final HouseRepository _repo;
  late final HouseFiltersRepository _filtersRepo;
  HouseFilter? _filter;

  final ValueNotifier<String> _floorPlanApplyText = ValueNotifier<String>('');
  Timer? _floorPlanApplyTextDebounce;
  int _floorPlanApplyTextRequestId = 0;

  final moreShortcut = [
    MoreItem(id: '3701', name: '现房'),
    MoreItem(id: '3903', name: '折扣好盘'),
    MoreItem(id: '3904', name: '免费专车'),
    MoreItem(id: '3605', name: '本月开盘'),
    MoreItem(id: '3902', name: '优惠活动'),
    MoreItem(id: '4004', name: 'VR看房'),
  ];

  final _moreShortcutSelected = <String>{};

  StreamSubscription<List<House>>? _housesSubscription;
  List<House>? _houses;
  bool _isLoading = true;
  Object? _error;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _repo = HouseRepository();
    _filtersRepo = HouseFiltersRepository();

    _scrollController.addListener(() {
      final offset = _scrollController.hasClients
          ? _scrollController.offset.clamp(0.0, _bannerHeight)
          : 0.0;
      if ((offset - _scrollOffsetVN.value).abs() > 0.5) {
        _scrollOffsetVN.value = offset;
      }
      // 触底自动加载下一页
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final current = _scrollController.offset;
        if (maxScroll - current < 200 && _repo.hasMore && !_isLoadingMore) {
          _loadMore();
        }
      }
    });

    _housesSubscription = _repo.housesStream.listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _houses = data;
          _isLoading = false;
          _error = null;
        });
      },
      onError: (Object e, StackTrace st) {
        if (!mounted) return;
        setState(() {
          _error = e;
          _isLoading = false;
        });
      },
    );
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
    _housesSubscription?.cancel();
    _scrollController.dispose();
    _scrollOffsetVN.dispose();
    _repo.dispose();
    _controller.dispose();
    _floorPlanApplyTextDebounce?.cancel();
    _floorPlanApplyText.dispose();
    super.dispose();
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
      // 更多筛选
      filter.homeType = selected.childIdsOf('home_type');
      filter.saleStatus = selected.childIdsOf('sale_status');
      filter.openTime = selected.childIdsOf('open_time');
      filter.deliveryTime = selected.childIdsOf('delivery_time');
      filter.decorationStatus = selected.childIdsOf('decoration_status');
      filter.buildingFeatures = selected.childIdsOf('building_features');
      filter.houseViewService = selected.childIdsOf('house_view_service');
    } else if (tabData.index == 4) {
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
      _filtersRepo.buyPriceResult = selected;
    } else if (tabData.index == 2) {
      _filtersRepo.floorPlanBuyResult = selected;
    } else if (tabData.index == 3) {
      _filtersRepo.moreBuyResult = selected;
    } else if (tabData.index == 4) {
      _filtersRepo.sortBuyResult = selected;
    }
    _filter = _popupSelectResultParser(tabData, selected);
    if (_filter == null) {
      if (tabData.index == 3) {
        _moreShortcutSelected.clear();
        setState(() {});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.resultParseFailed ?? '')),
      );
      return;
    }
    if (tabData.index == 3) {
      final latestMoreFilterSelected = <String>[];
      if (_filter!.deliveryTime != null) {
        latestMoreFilterSelected.addAll(_filter!.deliveryTime!);
      }
      if (_filter!.buildingFeatures != null) {
        latestMoreFilterSelected.addAll(_filter!.buildingFeatures!);
      }
      if (_filter!.openTime != null) {
        latestMoreFilterSelected.addAll(_filter!.openTime!);
      }
      _moreShortcutSelected.clear();
      _moreShortcutSelected.addAll(latestMoreFilterSelected);
      setState(() {});
    }
    _repo.refreshData(_filter!);
  }

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffsetVN = ValueNotifier<double>(0);

  /// Identifies the filter bar content so [onSelectWillShow] can measure its
  /// current on-screen position and scroll it to a pinned (sticky) position.
  final GlobalKey _filterHeaderKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final searchRowHeight = kToolbarHeight + topPadding;
    const expandedHeight = kToolbarHeight + _bannerHeight;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          ValueListenableBuilder<double>(
            valueListenable: _scrollOffsetVN,
            builder: (context, offset, child) {
              final colorScheme = Theme.of(context).colorScheme;
              final isDark = colorScheme.brightness == Brightness.dark;
              final isCollapsed = offset >= _bannerHeight;
              // Expanded: over the banner image, keep light-on-image colors.
              // Collapsed: over the surface, follow the current theme.
              final foregroundColor =
                  isCollapsed ? colorScheme.onSurface : Colors.white;
              final searchFillColor = isCollapsed
                  ? colorScheme.surfaceContainerHighest
                  : Colors.white;
              final searchHintColor =
                  isCollapsed ? colorScheme.onSurfaceVariant : Colors.grey;
              final systemOverlayStyle = isCollapsed
                  ? (isDark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  : SystemUiOverlayStyle.light;
              return _buildAppBar(
                l10n,
                searchRowHeight: searchRowHeight,
                expandedHeight: expandedHeight,
                foregroundColor: foregroundColor,
                searchFillColor: searchFillColor,
                searchHintColor: searchHintColor,
                systemOverlayStyle: systemOverlayStyle,
              );
            },
          ),
          const _NavigationGrid(),
          _buildSectionHeader(context, '全部房源'),
          _buildStickyFilter(l10n),
          _buildHouseList(l10n),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    AppLocalizations? l10n, {
    required double searchRowHeight,
    required double expandedHeight,
    required Color foregroundColor,
    required Color searchFillColor,
    required Color searchHintColor,
    required SystemUiOverlayStyle systemOverlayStyle,
  }) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 0,
      systemOverlayStyle: systemOverlayStyle,
      title: Row(
        children: [
          BackButton(color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            l10n?.buy ?? '',
            style: TextStyle(
              color: foregroundColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: searchFillColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 18, color: searchHintColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '搜索热门项目名…',
                        style: TextStyle(
                          color: searchHintColor,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.location_on_outlined, color: foregroundColor),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.chat_bubble_outline, color: foregroundColor),
        ),
        const SizedBox(width: 4),
      ],
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      expandedHeight: expandedHeight,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _buildBannerBackground(),
      ),
    );
  }

  Widget _buildBannerBackground() {
    return SizedBox.expand(
      child: Image.asset(
        'assets/realestate/banner.jpg',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 16, 15, 12),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildStickyFilter(AppLocalizations? l10n) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FilterHeaderDelegate(
        height: _filterHeaderHeight,
        child: Column(
          key: _filterHeaderKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupSelectBar(
              controller: _controller,
              tabs: [
                PopupTab(label: l10n?.region ?? ''),
                PopupTab(label: l10n?.price ?? ''),
                PopupTab(label: l10n?.floorPlan ?? ''),
                PopupTab(label: l10n?.more ?? ''),
                PopupTab(
                  child:
                      Image.asset('assets/sorting.png', width: 16, height: 16),
                ),
              ],
              selectDelegates: [
                CascadingSelectDelegate(
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
                GridSelectDelegate(
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
                  applyText: AppLocalizations.of(context)?.apply ?? '',
                ),
                FlattenSelectDelegate(
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
                FlattenSelectDelegate(
                  entriesLoader: _filtersRepo.fetchMoreBuyData,
                  selectedEntriesLoader: _filtersRepo.fetchMoreBuySelectedData,
                  resetEntriesLoader: _filtersRepo.fetchMoreBuyResetData,
                  selectionMode: SelectionMode.multiple,
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  sideBarTheme: const SelectSideBarTheme(width: 98),
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
                  entriesLoader: _filtersRepo.fetchSortBuyData,
                  selectedEntriesLoader: _filtersRepo.fetchSortBuySelectedData,
                  resetEntriesLoader: _filtersRepo.fetchSortBuyResetData,
                  selectionMode: SelectionMode.single,
                  radioBuilder: (context, selected) {
                    return MyRadio(value: selected);
                  },
                ),
              ],
              onSelectWillShow: (PopupTabData tabData) async {
                // Programmatic sticky: scroll exactly enough so the filter bar
                // (SliverPersistentHeader) pins just below the collapsed app
                // bar, then let the overlay anchor to that final layout.
                // Returning `true` proceeds with showing the overlay.
                final ctx = _filterHeaderKey.currentContext;
                if (ctx != null) {
                  final RenderBox? box = ctx.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final double headerTop = box.localToGlobal(Offset.zero).dy;
                    final double stickyTop =
                        kToolbarHeight + MediaQuery.of(context).padding.top;
                    final double delta = headerTop - stickyTop;
                    if (delta > 0) {
                      await _scrollController.animateTo(
                        _scrollController.offset + delta,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  }
                }
                return true;
              },
              onSelectShowed: (PopupTabData tabData) {
                largePrint('onShowed: ${tabData.label}');
              },
              onSelectWillHide: (PopupTabData tabData) {
                largePrint('onWillHide: ${tabData.label}');
                return true;
              },
              onSelectHidden: (PopupTabData tabData) {
                largePrint('onHidden: ${tabData.label}');
              },
              onChanged: (tabData, selected) {
                largePrint('onChanged: $tabData, $selected');
                _handleSelectChange(tabData, selected);
                showSelectResult(context, selected);
              },
              onApplied: (tabData, selected) {
                largePrint('onApplied: $tabData, $selected');
                _handleSelectApply(tabData, selected);
                if (tabData.index == 2) {
                  _floorPlanApplyTextDebounce?.cancel();
                  _floorPlanApplyTextRequestId++;
                  _floorPlanApplyText.value =
                      AppLocalizations.of(context)?.apply ?? '';
                }
                showSelectResult(context, selected);
              },
              onReset: () {
                debugPrint('onReset');
                if (_controller.currentIndex == 2) {
                  _floorPlanApplyTextDebounce?.cancel();
                  _floorPlanApplyTextRequestId++;
                  _floorPlanApplyText.value =
                      AppLocalizations.of(context)?.apply ?? '';
                }
              },
            ),
            Container(
              height: _chipBarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: moreShortcut.length,
                itemBuilder: (context, int index) {
                  final item = moreShortcut[index];
                  return ChoiceChip(
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    showCheckmark: false,
                    label: Text(item.name ?? ''),
                    selected: _moreShortcutSelected.contains(item.id ?? ''),
                    onSelected: (bool selected) async {
                      setState(() {
                        if (selected) {
                          _moreShortcutSelected.add(item.id ?? '');
                        } else {
                          _moreShortcutSelected.remove(item.id ?? '');
                        }
                      });
                      final ok = await _controller.apply(
                          tabIndex: 3, selectedEntryIds: _moreShortcutSelected);
                      if (!ok) {
                        largePrint('apply failed');
                      }
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(width: 10);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseList(AppLocalizations? l10n) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            l10n?.loadError('$_error') ?? '$_error',
          ),
        ),
      );
    }
    final houses = _houses;
    if (houses == null || houses.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: Text(l10n?.nohomes ?? '')),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == houses.length) {
              return _buildListFooter(l10n);
            }
            final house = houses[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: AspectRatio(
                  aspectRatio: 120 / 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      house.picture ?? '',
                      width: 120,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(house.title ?? ''),
                subtitle: Text(house.price ?? ''),
              ),
            );
          },
          childCount: houses.length + 1,
        ),
      ),
    );
  }

  Widget _buildListFooter(AppLocalizations? l10n) {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('加载中…'),
            ],
          ),
        ),
      );
    }
    final pageInfo = '第 ${_repo.loadedPages} / ${_repo.totalPages} 页';
    if (!_repo.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            '${l10n?.noMore ?? '没有更多了'} · $pageInfo',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          pageInfo,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _NavData {
  const _NavData(this.value, this.label, this.color, {this.hot = false});
  final String value;
  final String label;
  final Color color;
  final bool hot;
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _NavigationGrid extends StatelessWidget {
  const _NavigationGrid();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;
    final onSurface = colorScheme.onSurface;
    const data = [
      _NavData('768', '全部楼盘', Color(0xFFFF6B6B)),
      _NavData('605', '在售楼盘', Color(0xFFFFA726)),
      _NavData('117', '折扣好盘', Color(0xFF66BB6A)),
      _NavData('23', '特价房源', Color(0xFF42A5F5)),
      _NavData('1', '本月开盘', Color(0xFFFF6B6B), hot: true),
    ];
    const items = [
      _NavItem(Icons.grid_view_outlined, '板块找房'),
      _NavItem(Icons.location_on_outlined, '地图找房'),
      _NavItem(Icons.person_outline, '找经纪人'),
      _NavItem(Icons.train_outlined, '近地铁'),
      _NavItem(Icons.school_outlined, '学校找房'),
    ];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Card(
          elevation: 0,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: data
                      .map((item) => Expanded(
                            child: InkWell(
                              onTap: () {},
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: item.color,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            item.value,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (item.hot)
                                        Positioned(
                                          top: -4,
                                          right: -10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'HOT',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                        fontSize: 12, color: onSurface),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: items
                      .map((item) => Expanded(
                            child: InkWell(
                              onTap: () {},
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(item.icon, size: 28, color: onSurface),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                        fontSize: 12, color: onSurface),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _FilterHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) => true;
}
