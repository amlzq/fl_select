import 'dart:async';

import 'package:example/log.dart';
import 'package:example/widgets/my_widgets.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generated/l10n/app_localizations.dart';
import '../widgets/show_select_result.dart';
import 'house_filters_repository.dart';
import 'house_repository.dart';
import 'utils.dart';

/// For sale
class HousePage extends StatefulWidget {
  const HousePage({super.key});
  @override
  State<HousePage> createState() => _HousePageState();
}

const _bannerHeight = 150.0;
const _filterBarHeight = 44.0;
const _chipBarHeight = 48.0;
const _filterHeaderHeight = _filterBarHeight + _chipBarHeight;

class _HousePageState extends State<HousePage> {
  final PopupSelectController _controller = PopupSelectController();
  late final HouseRepository _repo;
  late final HouseFiltersRepository _filtersRepo;
  HouseFilter? _filter;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffsetVN = ValueNotifier<double>(0);

  bool _isLoadingMore = false;

  final ValueNotifier<String> _moreApplyText = ValueNotifier<String>('');
  Timer? _moreApplyTextDebounce;
  int _moreApplyTextRequestId = 0;

  /// Identifies the filter bar content so [onSelectWillShow] can measure its
  /// current on-screen position and scroll it to a pinned (sticky) position.
  final GlobalKey _filterHeaderKey = GlobalKey();

  StreamSubscription<List<House>>? _housesSubscription;
  List<House>? _houses;
  bool _isLoading = true;
  Object? _error;

  final moreShortcut = [
    MoreItem(id: 'price_reduced', name: 'Price reduced'),
    MoreItem(id: 'open_house', name: 'Open house'),
    MoreItem(id: 'new_listing', name: 'New listing'),
    MoreItem(id: 'new_construction', name: 'New construction'),
    MoreItem(id: 'pool', name: 'Pool'),
  ];

  final _moreShortcutSelected = <String>{};

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
      // Auto-load the next page when scrolled to the bottom.
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
      noMinHintText: l10n?.noMin ?? '',
      noMaxHintText: l10n?.noMax ?? '',
    );
    if (_moreApplyText.value.isEmpty) {
      _moreApplyText.value = l10n?.apply ?? '';
    }
  }

  @override
  void dispose() {
    _housesSubscription?.cancel();
    _repo.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _scrollOffsetVN.dispose();
    _moreApplyTextDebounce?.cancel();
    _moreApplyText.dispose();
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
      // Neighborhood filter
      filter.neighborhood = selected
          .cascadingPairsOf('neighborhood')
          .map((p) => {
                "region_id": p.id,
                "neighborhood_id": p.childIds,
              })
          .toList(growable: false);
    } else if (tabData.index == 1) {
      // Price filter
      final category = selected.firstOrNull;
      if (category == null) return null;
      if (category.id == 'list_price') {
        filter.listPrice = selected
            .childRangesOf('list_price')
            .map((e) => {
                  "id": e.id,
                  "min": e.min,
                  "max": e.max,
                })
            .toList(growable: false);
      } else if (category.id == 'monthly_price') {
        filter.monthlyPayment = selected
            .childRangesOf('monthly_price')
            .map((e) => {
                  "id": e.id,
                  "min": e.min,
                  "max": e.max,
                })
            .toList(growable: false);
      }
    } else if (tabData.index == 2) {
      // Rooms filter
      filter.bedrooms = selected.childIdsOf('bedrooms');
      filter.bathrooms = selected.childIdsOf('bathrooms');
    } else if (tabData.index == 3) {
      // More filter
      filter.homeType = selected.childIdsOf('home_type');
      filter.listsDetails = selected.childIdsOf('lists_details');
      filter.squareFeet = selected.childIdsOf('square_feet');
      filter.lotSize = selected.childIdsOf('lot_size');
      filter.homeFeatures = selected.childIdsOf('home_features');
      filter.commute = selected.childIdsOf('commute');
      filter.expandedSearch = selected.childIdsOf('expanded_search');
    } else if (tabData.index == 4) {
      // Sort filter
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
    if (tabData.index == 3) {
      _moreApplyTextDebounce?.cancel();

      final requestId = ++_moreApplyTextRequestId;
      _moreApplyText.value = l10n?.viewing ?? '';

      _moreApplyTextDebounce = Timer(
        const Duration(milliseconds: 250),
        () async {
          try {
            final count = await _repo.previewCount(_filter!);
            if (!mounted || requestId != _moreApplyTextRequestId) return;
            final l10n = AppLocalizations.of(context);
            _moreApplyText.value = count == 0
                ? (l10n?.nohomes ?? '')
                : (l10n?.viewhomes(count) ?? '');
          } catch (_) {
            if (!mounted || requestId != _moreApplyTextRequestId) return;
            _moreApplyText.value = AppLocalizations.of(context)?.apply ?? '';
          }
        },
      );
    }
  }

  void _handleSelectApply(PopupTabData tabData, SelectEntries selected) {
    final l10n = AppLocalizations.of(context);
    // Persist the applied selection to the repo so it can be restored on reopen.
    if (tabData.index == 0) {
      _filtersRepo.neighborhoodResult = selected;
    } else if (tabData.index == 1) {
      _filtersRepo.priceResult = selected;
    } else if (tabData.index == 2) {
      _filtersRepo.roomsResult = selected;
    } else if (tabData.index == 3) {
      _filtersRepo.moreResult = selected;
    } else if (tabData.index == 4) {
      _filtersRepo.sortResult = selected;
    }
    _filter = _popupSelectResultParser(tabData, selected);
    if (_filter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.resultParseFailed ?? '')),
      );
      return;
    }
    if (tabData.index == 3) {
      final latestMoreFilterSelected = <String>[];
      if (_filter!.homeType != null) {
        latestMoreFilterSelected.addAll(_filter!.homeType!);
      }
      if (_filter!.listsDetails != null) {
        latestMoreFilterSelected.addAll(_filter!.listsDetails!);
      }
      if (_filter!.homeFeatures != null) {
        latestMoreFilterSelected.addAll(_filter!.homeFeatures!);
      }
      if (_filter!.squareFeet != null) {
        latestMoreFilterSelected.addAll(_filter!.squareFeet!);
      }
      if (_filter!.lotSize != null) {
        latestMoreFilterSelected.addAll(_filter!.lotSize!);
      }
      if (_filter!.commute != null) {
        latestMoreFilterSelected.addAll(_filter!.commute!);
      }
      if (_filter!.expandedSearch != null) {
        latestMoreFilterSelected.addAll(_filter!.expandedSearch!);
      }
      _moreShortcutSelected.clear();
      _moreShortcutSelected.addAll(latestMoreFilterSelected);
      setState(() {});
    }
    _repo.refreshData(_filter!);
  }

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
          _buildSectionHeader(context, l10n?.sell ?? 'Homes for sale'),
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
            l10n?.sell ?? '',
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
                        '${userCityId.replaceAll('_', ', ')} homes for sale',
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
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.favorite_border, color: foregroundColor),
          ),
        ],
      ),
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
              isScrollable: true,
              tabs: [
                PopupTab(label: l10n?.neighborhood ?? ''),
                PopupTab(
                  label: l10n?.price ?? '',
                ),
                PopupTab(label: l10n?.rooms ?? ''),
                PopupTab(label: l10n?.more ?? ''),
                PopupTab(
                  child:
                      Image.asset('assets/sorting.png', width: 16, height: 16),
                ),
              ],
              selectDelegates: [
                // Neighborhood filter
                CascadingSelectDelegate(
                  entriesLoader: _filtersRepo.fetchNeighborhoodData,
                  selectedEntriesLoader:
                      _filtersRepo.fetchNeighborhoodSelectedData,
                  resetEntriesLoader: _filtersRepo.fetchNeighborhoodResetData,
                  selectionMode: SelectionMode.multiple,
                  sideBarTheme: const SelectSideBarTheme(width: 150),
                  isScrollable: true,
                ),
                // Price filter
                GridSelectDelegate(
                  entriesLoader: _filtersRepo.fetchPriceData,
                  selectedEntriesLoader: _filtersRepo.fetchPriceSelectedData,
                  // resetEntriesLoader: _filtersRepo.fetchPriceResetData,
                  selectionMode: SelectionMode.multiple,
                  crossAxisCount: 1,
                  childAspectRatio: 10,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  fieldTileTheme: const SelectFieldTileTheme(
                    variant: SelectFieldTileVariant.outlined,
                  ),
                ),
                // Rooms filter
                GridSelectDelegate(
                  entriesLoader: _filtersRepo.fetchRoomsData,
                  selectedEntriesLoader: _filtersRepo.fetchRoomsSelectedData,
                  // resetEntriesLoader: _filtersRepo.fetchRoomsResetData,
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
                ),
                // More filter
                ListSelectDelegate(
                  entriesLoader: _filtersRepo.fetchMoreData,
                  selectedEntriesLoader: _filtersRepo.fetchMoreSelectedData,
                  resetEntriesLoader: _filtersRepo.fetchMoreResetData,
                  selectionMode: SelectionMode.multiple,
                  resetText: AppLocalizations.of(context)?.reset ?? '',
                  applyText: AppLocalizations.of(context)?.apply ?? '',
                ),
                // Sort filter
                ListSelectDelegate(
                  entriesLoader: _filtersRepo.fetchSortData,
                  selectedEntriesLoader: _filtersRepo.fetchSortSelectedData,
                  resetEntriesLoader: _filtersRepo.fetchSortResetData,
                  selectionMode: SelectionMode.single,
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
                debugPrint('onShowed: ${tabData.label}');
              },
              onSelectWillHide: (PopupTabData tabData) {
                debugPrint('onWillHide: ${tabData.label}');
                return true;
              },
              onSelectHidden: (PopupTabData tabData) {
                debugPrint('onHidden: ${tabData.label}');
              },
              onChanged: (tabData, selected) {
                largePrint('onChanged: tabData=$tabData, selected=$selected');
                _handleSelectChange(tabData, selected);
                showSelectResult(context, selected);
              },
              onApplied: (tabData, selected) {
                largePrint('onApplied: tabData=$tabData, selected=$selected');
                _handleSelectApply(tabData, selected);
                if (tabData.index == 3) {
                  _moreApplyTextDebounce?.cancel();
                  _moreApplyTextRequestId++;
                  _moreApplyText.value = l10n?.apply ?? '';
                }
                showSelectResult(context, selected);
              },
              onReset: () {
                debugPrint('onReset');
                if (_controller.currentIndex == 3) {
                  _moreApplyTextDebounce?.cancel();
                  _moreApplyTextRequestId++;
                  _moreApplyText.value = l10n?.apply ?? '';
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
                        debugPrint('apply failed');
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
              return HouseListFooter(
                isLoadingMore: _isLoadingMore,
                hasMore: _repo.hasMore,
                pageInfo: 'Page ${_repo.loadedPages} / ${_repo.totalPages}',
                noMoreText: l10n?.noMore,
              );
            }
            final house = houses[index];
            final broker = (house.price ?? '').split('\n').lastOrNull;
            final tag = house.tag?.trim();
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.asset(
                          house.picture ?? '',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if ((tag ?? '').isNotEmpty)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              tag!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      const Positioned(
                        top: 10,
                        right: 10,
                        child: Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (i) => Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: i == 0 ? Colors.white : Colors.white70,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                house.title ?? '',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            Text(
                              '•••',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          house.second ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          house.address ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            height: 1.15,
                          ),
                        ),
                        if ((broker ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            broker!,
                            style: const TextStyle(
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: houses.length + 1,
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
      _NavData('1.2k', 'For sale', Color(0xFF4CAF50)),
      _NavData('320', 'New', Color(0xFF2196F3)),
      _NavData('85', 'Reduced', Color(0xFFFF7043)),
      _NavData('12', 'Open house', Color(0xFFAB47BC), hot: true),
      _NavData('40', 'Coming soon', Color(0xFF26A69A)),
    ];
    const items = [
      _NavItem(Icons.map_outlined, 'Map'),
      _NavItem(Icons.favorite_border, 'Saved'),
      _NavItem(Icons.draw_outlined, 'Draw'),
      _NavItem(Icons.train_outlined, 'Near transit'),
      _NavItem(Icons.school_outlined, 'Schools'),
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
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
