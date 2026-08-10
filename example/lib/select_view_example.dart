import 'package:example/widgets/my_widgets.dart';
import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import 'generated/l10n/app_localizations.dart';
import 'log.dart';
import 'widgets/show_select_result.dart';
import 'zillow/house_filters_repository.dart';
import 'zillow/house_repository.dart';
import 'zillow/utils.dart';

class SelectViewExamplePage extends StatefulWidget {
  const SelectViewExamplePage({super.key});

  @override
  State<SelectViewExamplePage> createState() => _ViewPageState();
}

class _ViewPageState extends State<SelectViewExamplePage> {
  late final HouseFiltersRepository _filtersRepo;
  HouseFilter? _filter;

  @override
  void initState() {
    super.initState();
    _filtersRepo = HouseFiltersRepository();
  }

  void _handleNeighborhoodChange(SelectEntries result) async {
    final l10n = AppLocalizations.of(context);
    _filter ??= HouseFilter(cityId: userCityId);
    _filtersRepo.neighborhoodResult = result;
    _filter?.neighborhood = result
        .cascadingPairsOf('neighborhood')
        .map((p) => {
              "region_id": p.id,
              "neighborhood_id": p.childIds,
            })
        .toList(growable: false);

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
      appBar: AppBar(title: const Text('SelectView')),
      body: SafeArea(
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Neighborhood',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: CascadingSelectDelegate(
                    entriesLoader: _filtersRepo.fetchNeighborhoodData,
                    selectedEntriesLoader:
                        _filtersRepo.fetchNeighborhoodSelectedData,
                    resetEntriesLoader: _filtersRepo.fetchNeighborhoodResetData,
                    selectionMode: SelectionMode.multiple,
                    sideBarTheme: const SelectSideBarTheme(width: 150),
                    isScrollable: true,
                    radioBuilder: (context, selected) {
                      return MyRadio(value: selected);
                    },
                    checkboxBuilder: (context, selected) {
                      return MyCheckbox(value: selected);
                    },
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    _handleNeighborhoodChange(selected);
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'GridSelectDelegate-1L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: GridSelectDelegate(
                    entriesLoader: () async => {
                      SelectTextEntry.name(id: 'a', name: 'A'),
                      SelectTextEntry.name(id: 'b', name: 'B'),
                      SelectTextEntry.name(id: 'c', name: 'C'),
                      SelectTextEntry.name(id: 'd', name: 'D'),
                    },
                    crossAxisCount: 3,
                    childAspectRatio: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    applyText: AppLocalizations.of(context)?.apply ?? '',
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'GridSelectDelegate-2L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: GridSelectDelegate(
                    entriesLoader: () async => {
                      SelectCategoryEntry.children(
                        id: 'c1',
                        name: 'Cate 1',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                        },
                      ),
                      SelectCategoryEntry.children(
                        id: 'c2',
                        name: 'Cate 2',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Tiger'),
                          SelectTextEntry.name(id: 'b', name: 'Lion'),
                          SelectTextEntry.name(id: 'c', name: 'Bear'),
                          SelectTextEntry.name(id: 'd', name: 'Elephant'),
                          SelectTextEntry.name(id: 'e', name: 'Monkey'),
                          SelectTextEntry.name(id: 'f', name: 'Dog'),
                          SelectTextEntry.name(id: 'g', name: 'Cat'),
                          SelectTextEntry.name(id: 'h', name: 'Pig'),
                          SelectTextEntry.name(id: 'i', name: 'Horse'),
                          SelectTextEntry.name(id: 'j', name: 'Sheep'),
                          SelectTextEntry.name(id: 'k', name: 'Cow'),
                          SelectTextEntry.name(id: 'l', name: 'Chicken'),
                          SelectTextEntry.name(id: 'm', name: 'Duck'),
                          SelectTextEntry.name(id: 'n', name: 'Pig'),
                          SelectTextEntry.name(id: 'o', name: 'Horse'),
                          SelectTextEntry.name(id: 'p', name: 'Sheep'),
                          SelectTextEntry.name(id: 'q', name: 'Cow'),
                        },
                        layout: const SelectChipLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'c3',
                        name: 'Cate 3',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                        },
                        layout: const SelectListLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'c4',
                        name: 'Cate 4',
                        children: {
                          SelectRangeEntry(
                            id: 'a',
                            name: '\$0-\$2000000',
                            min: 0,
                            max: 2000000,
                            divisions: 80,
                          ),
                          SelectRangeEntry.custom(),
                        },
                        layout: const SelectRangeLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'c5',
                        name: 'Cate 5',
                        children: {
                          SelectTextEntry.name(id: 'a', name: '1'),
                          SelectTextEntry.name(id: 'b', name: '2'),
                          SelectTextEntry.name(id: 'c', name: '3'),
                          SelectTextEntry.name(id: 'd', name: '4'),
                          SelectTextEntry.name(id: 'e', name: '5'),
                        },
                        layout: const SelectCounterLayout(),
                      ),
                    },
                    selectionMode: SelectionMode.multiple,
                    crossAxisCount: 3,
                    childAspectRatio: 3,
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
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'FlattenSelectDelegate 1L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: FlattenSelectDelegate(
                    entriesLoader: () async => {
                      SelectTextEntry.name(id: 'a', name: 'Tiger'),
                      SelectTextEntry.name(id: 'b', name: 'Lion'),
                      SelectTextEntry.name(id: 'c', name: 'Bear'),
                      SelectTextEntry.name(id: 'd', name: 'Elephant'),
                      SelectTextEntry.name(id: 'e', name: 'Monkey'),
                      SelectTextEntry.name(id: 'f', name: 'Dog'),
                      SelectTextEntry.name(id: 'g', name: 'Cat'),
                      SelectTextEntry.name(id: 'h', name: 'Pig'),
                      SelectTextEntry.name(id: 'i', name: 'Horse'),
                      SelectTextEntry.name(id: 'j', name: 'Sheep'),
                      SelectTextEntry.name(id: 'k', name: 'Cow'),
                      SelectTextEntry.name(id: 'l', name: 'Chicken'),
                      SelectTextEntry.name(id: 'm', name: 'Duck'),
                      SelectTextEntry.name(id: 'n', name: 'Pig'),
                      SelectTextEntry.name(id: 'o', name: 'Horse'),
                      SelectTextEntry.name(id: 'p', name: 'Sheep'),
                      SelectTextEntry.name(id: 'q', name: 'Cow'),
                    },
                    sideBarTheme: const SelectSideBarTheme(width: 90),
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'FlattenSelectDelegate 2L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: FlattenSelectDelegate(
                    entriesLoader: () async => {
                      SelectCategoryEntry.children(
                        id: 'c1',
                        name: 'Cate 1',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Tiger'),
                          SelectTextEntry.name(id: 'b', name: 'Lion'),
                          SelectTextEntry.name(id: 'c', name: 'Bear'),
                          SelectTextEntry.name(id: 'd', name: 'Elephant'),
                          SelectTextEntry.name(id: 'e', name: 'Monkey'),
                          SelectTextEntry.name(id: 'f', name: 'Dog'),
                        },
                      ),
                      SelectCategoryEntry.children(
                        id: 'c2',
                        name: 'Cate 2',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                        },
                        layout: const SelectGridLayout(
                          crossAxisCount: 2,
                          childAspectRatio: 3.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                      ),
                      SelectCategoryEntry.children(
                        id: 'c3',
                        name: 'Cate 3',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                        },
                        layout: const SelectListLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'c4',
                        name: 'Cate 4',
                        children: {
                          SelectRangeEntry(
                            id: 'a',
                            name: '\$0-\$2000000',
                            min: 0,
                            max: 2000000,
                            divisions: 80,
                          ),
                          SelectRangeEntry.custom(),
                        },
                        layout: const SelectRangeLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'c5',
                        name: 'Cate 5',
                        children: {
                          SelectTextEntry.name(id: 'a', name: '1'),
                          SelectTextEntry.name(id: 'b', name: '2'),
                          SelectTextEntry.name(id: 'c', name: '3'),
                          SelectTextEntry.name(id: 'd', name: '4'),
                          SelectTextEntry.name(id: 'e', name: '5'),
                        },
                        layout: const SelectCounterLayout(),
                      ),
                    },
                    selectionMode: SelectionMode.multiple,
                    sideBarTheme: const SelectSideBarTheme(width: 90),
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'ListSelectDelegate 1L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: ListSelectDelegate(
                    entriesLoader: () async => {
                      SelectTextEntry.name(id: 'a', name: 'A'),
                      SelectTextEntry.name(id: 'b', name: 'B'),
                      SelectTextEntry.name(id: 'c', name: 'C'),
                      SelectTextEntry.name(id: 'd', name: 'D'),
                    },
                    resetText: AppLocalizations.of(context)?.reset ?? '',
                    applyText: AppLocalizations.of(context)?.apply ?? '',
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'ListSelectDelegate 2L',
                  style: TextStyle(fontSize: 20),
                ),
                SelectView(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  delegate: ListSelectDelegate(
                    entriesLoader: () async => {
                      SelectCategoryEntry.children(
                        id: 'c1',
                        name: 'Cate 1',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                        },
                      ),
                      SelectCategoryEntry.children(
                        id: 'c2',
                        name: 'Cate 2',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'Tiger'),
                          SelectTextEntry.name(id: 'b', name: 'Lion'),
                          SelectTextEntry.name(id: 'c', name: 'Bear'),
                          SelectTextEntry.name(id: 'd', name: 'Elephant'),
                          SelectTextEntry.name(id: 'e', name: 'Monkey'),
                          SelectTextEntry.name(id: 'f', name: 'Dog'),
                          SelectTextEntry.name(id: 'g', name: 'Cat'),
                          SelectTextEntry.name(id: 'h', name: 'Pig'),
                          SelectTextEntry.name(id: 'i', name: 'Horse'),
                          SelectTextEntry.name(id: 'j', name: 'Sheep'),
                          SelectTextEntry.name(id: 'k', name: 'Cow'),
                          SelectTextEntry.name(id: 'l', name: 'Chicken'),
                          SelectTextEntry.name(id: 'm', name: 'Duck'),
                          SelectTextEntry.name(id: 'n', name: 'Pig'),
                          SelectTextEntry.name(id: 'o', name: 'Horse'),
                          SelectTextEntry.name(id: 'p', name: 'Sheep'),
                          SelectTextEntry.name(id: 'q', name: 'Cow'),
                        },
                        layout: const SelectChipLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'c3',
                        name: 'Cate 3',
                        children: {
                          SelectTextEntry.name(id: 'a', name: 'A'),
                          SelectTextEntry.name(id: 'b', name: 'B'),
                          SelectTextEntry.name(id: 'c', name: 'C'),
                          SelectTextEntry.name(id: 'd', name: 'D'),
                        },
                        layout: const SelectGridLayout(
                          crossAxisCount: 3,
                          childAspectRatio: 2.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                      ),
                      SelectCategoryEntry.children(
                        id: 'c4',
                        name: 'Cate 4',
                        children: {
                          SelectRangeEntry(
                            id: 'a',
                            name: '\$0-\$2000000',
                            min: 0,
                            max: 2000000,
                            divisions: 80,
                          ),
                          SelectRangeEntry.custom(),
                        },
                        layout: const SelectRangeLayout(),
                      ),
                      SelectCategoryEntry.children(
                        id: 'c5',
                        name: 'Cate 5',
                        children: {
                          SelectTextEntry.name(id: 'a', name: '1'),
                          SelectTextEntry.name(id: 'b', name: '2'),
                          SelectTextEntry.name(id: 'c', name: '3'),
                          SelectTextEntry.name(id: 'd', name: '4'),
                          SelectTextEntry.name(id: 'e', name: '5'),
                        },
                        layout: const SelectCounterLayout(),
                      ),
                    },
                    selectionMode: SelectionMode.single,
                  ),
                  onChanged: (selected) {
                    largePrint('onChangeTap: $selected');
                    showSelectResult(context, selected);
                  },
                ),
                const SizedBox(height: 250),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
