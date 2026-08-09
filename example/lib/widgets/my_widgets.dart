import 'package:fl_select/fl_select.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';

class MyRadio extends StatelessWidget {
  final bool value;

  const MyRadio({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value) {
      return Icon(Icons.check,
          size: 14, color: Theme.of(context).colorScheme.primary);
    } else {
      return const SizedBox.shrink();
    }
  }
}

class MyCheckbox extends StatelessWidget {
  final bool value;

  const MyCheckbox({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final effectiveCheckColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: value ? effectiveCheckColor : Colors.grey,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(3),
        color: value ? effectiveCheckColor : Colors.transparent,
      ),
      child:
          value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }
}

class MyActionBar extends StatelessWidget {
  const MyActionBar({
    super.key,
    required this.applyTextVN,
    required this.onResetTap,
    required this.onApplyTap,
  });

  final ValueNotifier<String> applyTextVN;

  final VoidCallback onResetTap;
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    // final SelectController? controller = SelectController.of(context)!;
    return ValueListenableBuilder<String>(
      valueListenable: applyTextVN,
      builder: (context, applyText, _) {
        return SelectActionBar(
          applyText: applyText,
          onResetTap: onResetTap,
          onApplyTap: onApplyTap,
        );
      },
    );
  }
}

/// Pagination status footer for a house list: a loading spinner,
/// "No more" + page info, or page info only.
class HouseListFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;
  final String pageInfo;
  final String? noMoreText;
  final String? loadingText;

  const HouseListFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    required this.pageInfo,
    this.noMoreText,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loading = loadingText ?? l10n?.loading ?? 'Loading...';
    final noMore = noMoreText ?? l10n?.noMore ?? 'No more';
    if (isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(loading),
            ],
          ),
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            '$noMore · $pageInfo',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          pageInfo,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }
}
