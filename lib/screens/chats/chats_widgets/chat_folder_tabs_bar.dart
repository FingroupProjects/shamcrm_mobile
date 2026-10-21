import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/chat/chat_tab_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class ChatFolderTabsBar extends StatelessWidget {
  final List<ChatTab> tabs;
  final int? selectedTabId; // null = 'Все'
  final ValueChanged<int?> onTabSelected;
  final VoidCallback onCreateTabPressed;
  final ValueChanged<ChatTab>? onEditTabPressed;
  final ValueChanged<ChatTab>? onDeleteTabPressed;
  final VoidCallback? onReorderTabsPressed;
  final bool isLoading;

  const ChatFolderTabsBar({
    super.key,
    required this.tabs,
    required this.selectedTabId,
    required this.onTabSelected,
    required this.onCreateTabPressed,
    this.onEditTabPressed,
    this.onDeleteTabPressed,
    this.onReorderTabsPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final allChatsLabel = localizations?.translate('all_chats') ?? 'Все';

    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const horizontalPadding = 16.0;
          final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
          const addButtonWidth = 38.0;
          const spacing = 8.0;
          final tabCount = 1 + tabs.length; // 'Все' + tabs

          // Вычисляем ширину для каждой вкладки, чтобы они растягивались на весь экран
          final totalSpacing = tabCount * spacing;
          final availableForTabs = availableWidth - addButtonWidth - totalSpacing;
          final equalTabWidth =
              availableForTabs > 0 ? (availableForTabs / tabCount) : 0.0;

          // Если вкладки комфортно помещаются (>= 72px на вкладку),
          // растягиваем их равномерно по ширине во весь экран ("до предела").
          // Если папок много или длинные названия — даем натуральную ширину и включаем скролл.
          final minTabWidth = (equalTabWidth >= 72.0) ? equalTabWidth : null;

          final items = <Widget>[];

          // 1. Вкладка "Все"
          final isAllSelected = selectedTabId == null;
          items.add(
            _buildTabPill(
              context: context,
              label: allChatsLabel,
              isSelected: isAllSelected,
              minWidth: minTabWidth,
              onTap: () {
                HapticFeedback.selectionClick();
                onTabSelected(null);
              },
            ),
          );

          // 2. Вкладки папок
          for (final tab in tabs) {
            final isSelected = selectedTabId == tab.id;

            items.add(
              _buildTabPill(
                context: context,
                label: tab.name,
                count: tab.unreadCount ?? tab.chatsCount,
                isSelected: isSelected,
                minWidth: minTabWidth,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTabSelected(tab.id);
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  _showFolderContextMenu(context, tab);
                },
              ),
            );
          }

          // Если вкладки еще ни разу не кэшированы и идет первая загрузка,
          // показываем аккуратные placeholder-пилюли, чтобы интерфейс не прыгал с одной лишь вкладкой 'Все'
          if (tabs.isEmpty && isLoading) {
            for (int i = 0; i < 2; i++) {
              items.add(_buildSkeletonPill(context));
            }
          }

          // 3. Кнопка '+' в конце списка (без текста "папка", аккуратная по ширине)
          items.add(_buildAddButton(context));

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: availableWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: spacing),
                    items[i],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabPill({
    required BuildContext context,
    required String label,
    String? icon,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    double? minWidth,
  }) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 36,
          constraints: minWidth != null
              ? BoxConstraints(minWidth: minWidth)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.buttonPrimaryBg
                : colors.surfacePrimary.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colors.buttonPrimaryBg
                  : colors.borderSubtle.withValues(alpha: 0.7),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.buttonPrimaryBg.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && icon.isNotEmpty) ...[
                Text(
                  icon,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textStyles.labelMd.copyWith(
                    color: isSelected
                        ? colors.buttonPrimaryFg
                        : colors.textPrimary.withValues(alpha: 0.85),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.buttonPrimaryFg.withValues(alpha: 0.25)
                        : colors.buttonPrimaryBg.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: TextStyle(
                      color: isSelected
                          ? colors.buttonPrimaryFg
                          : colors.buttonPrimaryBg,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final colors = context.appColors;
    final localizations = AppLocalizations.of(context);
    final tooltip = localizations?.translate('folder_new') ?? 'Создать папку';

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onCreateTabPressed();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 38,
            height: 36,
            decoration: BoxDecoration(
              color: colors.surfacePrimary.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.borderSubtle.withValues(alpha: 0.7),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                size: 20,
                color: colors.buttonPrimaryBg,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFolderContextMenu(BuildContext context, ChatTab tab) {
    final localizations = AppLocalizations.of(context);
    final editLabel =
        localizations?.translate('folder_edit') ?? 'Редактировать папку';
    final deleteLabel =
        localizations?.translate('folder_delete') ?? 'Удалить папку';
    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tab.name,
                      style: context.appTextStyles.titleMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: colors.textPrimary),
                title: Text(
                  editLabel,
                  style: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onEditTabPressed?.call(tab);
                },
              ),
              if (onReorderTabsPressed != null && tabs.length > 1)
                ListTile(
                  leading:
                      Icon(Icons.swap_vert_rounded, color: colors.textPrimary),
                  title: Text(
                    localizations?.translate('folder_reorder') ??
                        'Изменить порядок',
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onReorderTabsPressed?.call();
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: colors.error),
                title: Text(
                  deleteLabel,
                  style: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.error,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDeleteTabPressed?.call(tab);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonPill(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 36,
      width: 68,
      decoration: BoxDecoration(
        color: colors.buttonSecondaryBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
    );
  }
}
