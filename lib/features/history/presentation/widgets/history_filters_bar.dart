import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/locale/app_strings.dart';
import '../../../../core/ui/app_motion.dart';
import '../../domain/history_list_query.dart';

class HistoryFiltersBar extends StatelessWidget {
  const HistoryFiltersBar({
    required this.s,
    required this.filter,
    required this.sort,
    required this.onFilterSelected,
    required this.onSortSelected,
    super.key,
  });

  final AppStrings s;
  final HistoryFilter filter;
  final HistorySort sort;
  final ValueChanged<HistoryFilter> onFilterSelected;
  final ValueChanged<HistorySort> onSortSelected;

  String _filterLabel(HistoryFilter f) {
    return switch (f) {
      HistoryFilter.all => s.historyFilterAll,
      HistoryFilter.recognized => s.historyFilterRecognized,
      HistoryFilter.waiting => s.historyFilterWaiting,
      HistoryFilter.corrected => s.historyFilterCorrected,
      HistoryFilter.public => s.historyFilterPublic,
    };
  }

  String _sortLabel(HistorySort so) {
    return switch (so) {
      HistorySort.newest => s.historySortNewest,
      HistorySort.oldest => s.historySortOldest,
      HistorySort.confidence => s.historySortConfidence,
      HistorySort.brand => s.historySortBrand,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filters = HistoryFilter.values;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = filters[i];
                final selected = filter == f;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: _filterLabel(f),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.emphasizedDecelerate,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.16)
                          : scheme.surfaceContainerHighest.withValues(
                              alpha: 0.85,
                            ),
                      border: Border.all(
                        color: selected
                            ? scheme.primary.withValues(alpha: 0.45)
                            : scheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          AppHaptics.selection();
                          onFilterSelected(f);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            _filterLabel(f),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? scheme.primary
                                      : scheme.onSurface,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<HistorySort>(
              tooltip: s.historySortMenuTitle,
              initialValue: sort,
              onSelected: (v) {
                AppHaptics.selection();
                onSortSelected(v);
              },
              itemBuilder: (ctx) => [
                for (final so in HistorySort.values)
                  PopupMenuItem(value: so, child: Text(_sortLabel(so))),
              ],
              child: Padding(
                padding: const EdgeInsets.only(right: 4, top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_rounded, size: 20, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      _sortLabel(sort),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down_rounded, color: scheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
