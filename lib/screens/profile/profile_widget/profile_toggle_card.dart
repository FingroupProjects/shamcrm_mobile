import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

class ProfileToggleCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ProfileToggleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appColors.borderSubtle.withValues(alpha: 0.42),
        ),
        boxShadow: context.appShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.appColors.surfaceAccent.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: context.appColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: context.appColors.buttonPrimaryFg,
            inactiveThumbColor: context.appColors.surfacePrimary,
            activeTrackColor: context.appColors.buttonPrimaryBg,
            inactiveTrackColor:
                context.appColors.borderSubtle.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
