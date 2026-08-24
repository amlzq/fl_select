import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';

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
