import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/chat/chat_tab_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class ChatSyncTabsSheet extends StatefulWidget {
  final int chatId;
  final String chatName;
  final List<ChatTab> allTabs;
  final List<int> initialTabIds;
  final String endpoint;

  const ChatSyncTabsSheet({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.allTabs,
    required this.initialTabIds,
    this.endpoint = 'lead',
  });

  static Future<bool?> show(
    BuildContext context, {
    required int chatId,
    required String chatName,
    required List<ChatTab> allTabs,
    required List<int> initialTabIds,
    String endpoint = 'lead',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ChatSyncTabsSheet(
        chatId: chatId,
        chatName: chatName,
        allTabs: allTabs,
        initialTabIds: initialTabIds,
        endpoint: endpoint,
      ),
    );
  }

  @override
  State<ChatSyncTabsSheet> createState() => _ChatSyncTabsSheetState();
}

class _ChatSyncTabsSheetState extends State<ChatSyncTabsSheet> {
  final ApiService _apiService = ApiService();
  late final Set<int> _selectedTabIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTabIds = Set.from(widget.initialTabIds);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _apiService.syncChatTabs(
        chatId: widget.chatId,
        tabIds: _selectedTabIds.toList(),
        type: widget.endpoint,
      );
      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
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

    final title = localizations?.translate('chat_folders') ?? 'Папки чата';
    final saveLabel = localizations?.translate('save') ?? 'Сохранить';

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
                          widget.chatName,
                          style: textStyles.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

            Flexible(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shrinkWrap: true,
                children: widget.allTabs.map((tab) {
                  final isChecked = _selectedTabIds.contains(tab.id);

                  return CheckboxListTile(
                    value: isChecked,
                    activeColor: colors.buttonPrimaryBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    secondary: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.buttonPrimaryBg.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        color: colors.buttonPrimaryBg,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      tab.name,
                      style: textStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (val == true) {
                          _selectedTabIds.add(tab.id);
                        } else {
                          _selectedTabIds.remove(tab.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButton(
                buttonText: saveLabel,
                isLoading: _isSaving,
                buttonColor: colors.buttonPrimaryBg,
                textColor: colors.buttonPrimaryFg,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
