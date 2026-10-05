import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

/// Чипсы под поиском: активные фильтры и недавние запросы.
class ListFilterChips extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;
  final List<String> recentQueries;
  final ValueChanged<String> onPickQuery;

  const ListFilterChips({
    super.key,
    required this.hasFilters,
    required this.onClearFilters,
    required this.recentQueries,
    required this.onPickQuery,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasFilters && recentQueries.isEmpty) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context);
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (hasFilters)
              _Chip(
                label: loc?.translate('list_active_filters') ?? 'Filters',
                onRemove: onClearFilters,
              ),
            for (final query in recentQueries)
              ActionChip(
                label: Text(
                  query,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                backgroundColor: colors.surfacePrimary,
                side: BorderSide(color: colors.borderSubtle),
                shape: const StadiumBorder(),
                onPressed: () => onPickQuery(query),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _Chip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onRemove,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.buttonPrimaryBg,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.close_rounded, size: 16, color: colors.buttonPrimaryBg),
            ],
          ),
        ),
      ),
    );
  }
}
