import 'package:crm_task_manager/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

class ProfileSettingsTile extends StatelessWidget {
  const ProfileSettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = danger ? colors.error : colors.iconBrand;
    final leadingBackground =
        danger ? colors.surfaceDangerSubtle : colors.surfaceInteractive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: margin,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderPrimary),
          ),
          child: Row(
            children: [
              leading ??
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: leadingBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon ?? Icons.tune_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: danger ? colors.error : colors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.iconSecondary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
