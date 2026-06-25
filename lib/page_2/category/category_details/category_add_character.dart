import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class CategoryTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final bool isAffectingPrice;

  CategoryTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.isAffectingPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.fieldBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('show_as'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.translate('show_as_description'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Gilroy',
              color: colors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<String>(
            value: 'a',
            groupValue: selectedType,
            onChanged: isAffectingPrice
                ? null
                : (value) {
                    if (value != null) onTypeChanged(value);
                  },
            activeColor: colors.buttonPrimaryBg,
            title: Text(
              AppLocalizations.of(context)!.translate('product'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: isAffectingPrice ? colors.textMuted : colors.textPrimary,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: 'b',
            groupValue: selectedType,
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
            activeColor: colors.buttonPrimaryBg,
            title: Text(
              AppLocalizations.of(context)!.translate('characteristic'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
