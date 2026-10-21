import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/chat/chat_tab_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class FolderReorderSheet extends StatefulWidget {
  final List<ChatTab> tabs;
  final ValueChanged<List<ChatTab>> onReorder;

  const FolderReorderSheet({
    super.key,
    required this.tabs,
    required this.onReorder,
  });

  static Future<List<ChatTab>?> show(
    BuildContext context, {
    required List<ChatTab> tabs,
    required ValueChanged<List<ChatTab>> onReorder,
  }) {
    return showModalBottomSheet<List<ChatTab>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FolderReorderSheet(
        tabs: tabs,
        onReorder: onReorder,
      ),
    );
  }

  @override
  State<FolderReorderSheet> createState() => _FolderReorderSheetState();
}

class _FolderReorderSheetState extends State<FolderReorderSheet> {
  late List<ChatTab> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = List<ChatTab>.from(widget.tabs);
  }

  void _handleReorder(int oldIndex, int newIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _tabs.removeAt(oldIndex);
      _tabs.insert(newIndex, item);
    });
    widget.onReorder(List<ChatTab>.from(_tabs));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final localizations = AppLocalizations.of(context);
    final title =
        localizations?.translate('folder_reorder_title') ?? 'Порядок папок';
    final hint = localizations?.translate('folder_reorder_hint') ??
        'Зажмите и перетаскивайте папки, чтобы изменить порядок';
    final rawDone = localizations?.translate('done');
    final doneLabel = (rawDone == null ||
            rawDone.trim().isEmpty ||
            rawDone.trim().toLowerCase() == 'done')
        ? (localizations?.locale.languageCode == 'en' ? 'Done' : 'Готово')
        : rawDone;

    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Верхняя полоска-индикатор
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Заголовок и кнопка закрытия
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textStyles.titleMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hint,
                          style: textStyles.caption.copyWith(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(_tabs),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Список папок с возможностью перетаскивания
            Flexible(
              child: _tabs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Нет созданных папок',
                          style: textStyles.bodyMd.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      itemCount: _tabs.length,
                      onReorder: _handleReorder,
                      onReorderStart: (index) {
                        HapticFeedback.mediumImpact();
                      },
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            final double scale = 1.0 + (animation.value * 0.03);
                            return Transform.scale(
                              scale: scale,
                              child: Material(
                                elevation: 8,
                                shadowColor:
                                    colors.shadow.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(16),
                                color: colors.surfacePrimary,
                                child: child,
                              ),
                            );
                          },
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final tab = _tabs[index];
                        return _buildFolderTile(
                          key: ValueKey('folder_reorder_${tab.id}'),
                          tab: tab,
                          index: index,
                        );
                      },
                    ),
            ),

            // Нижняя кнопка "Готово"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: CustomButton(
                buttonText: doneLabel,
                buttonColor: colors.buttonPrimaryBg,
                textColor: colors.textInverse,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(_tabs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderTile({
    required Key key,
    required ChatTab tab,
    required int index,
  }) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.buttonPrimaryBg.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.folder_rounded,
              size: 20,
              color: colors.buttonPrimaryBg,
            ),
          ),
        ),
        title: Text(
          tab.name,
          style: textStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: tab.chatsCount != null && tab.chatsCount! > 0
            ? Text(
                'Чатов: ${tab.chatsCount}',
                style: textStyles.caption.copyWith(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab.unreadCount != null && tab.unreadCount! > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.buttonPrimaryBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tab.unreadCount! > 99 ? '99+' : '${tab.unreadCount}',
                  style: textStyles.caption.copyWith(
                    color: colors.textInverse,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.borderSubtle.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.drag_handle_rounded,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
