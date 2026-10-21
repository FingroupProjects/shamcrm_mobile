import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/chat/chat_tab_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class AddToFolderSheet extends StatefulWidget {
  final List<ChatTab> tabs;
  final List<int> selectedChatIds;
  final int? currentTabId;
  final VoidCallback onCreateNewFolder;
  final String endpoint;

  const AddToFolderSheet({
    super.key,
    required this.tabs,
    required this.selectedChatIds,
    this.currentTabId,
    required this.onCreateNewFolder,
    this.endpoint = 'lead',
  });

  static Future<bool?> show(
    BuildContext context, {
    required List<ChatTab> tabs,
    required List<int> selectedChatIds,
    int? currentTabId,
    required VoidCallback onCreateNewFolder,
    String endpoint = 'lead',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddToFolderSheet(
        tabs: tabs,
        selectedChatIds: selectedChatIds,
        currentTabId: currentTabId,
        onCreateNewFolder: onCreateNewFolder,
        endpoint: endpoint,
      ),
    );
  }

  @override
  State<AddToFolderSheet> createState() => _AddToFolderSheetState();
}

class _AddToFolderSheetState extends State<AddToFolderSheet> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _attachToTab(ChatTab tab) async {
    setState(() => _isLoading = true);
    try {
      if (widget.currentTabId != null && widget.currentTabId != tab.id) {
        // Bulk move
        await _apiService.bulkMoveChats(
          fromTabId: widget.currentTabId!,
          toTabId: tab.id,
          chatIds: widget.selectedChatIds,
          type: widget.endpoint,
        );
      } else {
        await _apiService.attachChatsToTab(
          tabId: tab.id,
          chatIds: widget.selectedChatIds,
          type: widget.endpoint,
        );
      }
      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

  Future<void> _detachFromCurrentTab() async {
    if (widget.currentTabId == null) return;
    setState(() => _isLoading = true);
    try {
      await _apiService.detachChatsFromTab(
        tabId: widget.currentTabId!,
        chatIds: widget.selectedChatIds,
        type: widget.endpoint,
      );
      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final localizations = AppLocalizations.of(context);

    final title = localizations?.translate('folder_add_to') ?? 'В папку';
    final newFolderLabel =
        localizations?.translate('folder_new') ?? 'Новая папка';
    final removeFromFolderLabel = localizations?.translate('folder_remove_from') ??
        'Удалить из этой папки';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textStyles.titleLg.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${localizations?.translate('selected_count') ?? 'Выбрано'}: ${widget.selectedChatIds.length}',
                          style: textStyles.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shrinkWrap: true,
                  children: [
                    // Create new folder action
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.create_new_folder_outlined,
                          color: colors.buttonPrimaryBg,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        newFolderLabel,
                        style: textStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.buttonPrimaryBg,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onCreateNewFolder();
                      },
                    ),

                    if (widget.currentTabId != null) ...[
                      const Divider(height: 12),
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.folder_off_outlined,
                            color: colors.error,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          removeFromFolderLabel,
                          style: textStyles.bodyLg.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.error,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        onTap: _detachFromCurrentTab,
                      ),
                    ],

                    const Divider(height: 12),

                    // Available folders
                    ...widget.tabs.map((tab) {
                      final isCurrentTab = widget.currentTabId == tab.id;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.buttonPrimaryBg.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.folder_outlined,
                            color: colors.buttonPrimaryBg,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          tab.name,
                          style: textStyles.bodyLg.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCurrentTab
                                ? colors.textSecondary
                                : colors.textPrimary,
                          ),
                        ),
                        trailing: isCurrentTab
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.borderSubtle,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Текущая',
                                  style: textStyles.caption.copyWith(
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.chevron_right_rounded,
                                color: colors.textSecondary,
                              ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        onTap: isCurrentTab ? null : () => _attachToTab(tab),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
