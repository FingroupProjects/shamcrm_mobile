import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class PriceAffectSwitcher extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const PriceAffectSwitcher({
    Key? key,
    required this.isActive,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.fieldBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text( AppLocalizations.of(context)!.translate('has_price_characteristics'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text( AppLocalizations.of(context)!.translate('has_price_characteristics_description'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                    color: colors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeColor: colors.surfacePrimary,
            inactiveTrackColor: colors.textMuted.withValues(alpha: 0.5),
            activeTrackColor: colors.buttonPrimaryBg,
            inactiveThumbColor: colors.surfacePrimary,
          ),
        ],
      ),
    );
  }
}
