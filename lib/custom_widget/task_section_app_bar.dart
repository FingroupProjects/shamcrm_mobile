import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:flutter/material.dart';

class TaskSectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TaskSectionAppBar({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.appColors.backgroundPrimary.withValues(alpha: 0.35),
              Colors.transparent,
            ],
          ),
        ),
      ),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleSpacing: 16,
      title: AppBarShell(
        leading: AppBarShell.capsule(
          context,
          width: AppBarShell.orbSize,
          padding: EdgeInsets.zero,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 22,
              height: 22,
              color: context.appColors.iconPrimary,
            ),
            onPressed: onBack,
          ),
        ),
        center: AppBarShell.capsule(
          context,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appTextStyles.bodyLg.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appTextStyles.bodySm.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        trailing: actions.isEmpty
            ? null
            : AppBarShell.capsule(
                context,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      actions[i],
                      if (i != actions.length - 1) const SizedBox(width: 2),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
