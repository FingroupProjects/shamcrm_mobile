import 'dart:async';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/core/theme/widgets/channel_source_icon.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_channel_list.dart';
import 'package:crm_task_manager/models/chat/chat_tab_model.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/offline/repositories/chat_offline_repository.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chat_folder_select_chats_sheet.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';

class ChatFolderFormSheet extends StatefulWidget {
  final ChatTab? initialTab;
  final int? currentSalesFunnelId;
  final List<Chats>? initialAvailableChats;
  final Set<int>? preselectedChatIds;
  final String endpoint;

  const ChatFolderFormSheet({
    super.key,
    this.initialTab,
    this.currentSalesFunnelId,
    this.initialAvailableChats,
    this.preselectedChatIds,
    this.endpoint = 'lead',
  });

  static Future<dynamic> show(
    BuildContext context, {
    ChatTab? initialTab,
    int? currentSalesFunnelId,
    List<Chats>? initialAvailableChats,
    Set<int>? preselectedChatIds,
    String endpoint = 'lead',
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatFolderFormSheet(
        initialTab: initialTab,
        currentSalesFunnelId: currentSalesFunnelId,
        initialAvailableChats: initialAvailableChats,
        preselectedChatIds: preselectedChatIds,
        endpoint: endpoint,
      ),
    );
  }

  @override
  State<ChatFolderFormSheet> createState() => _ChatFolderFormSheetState();
}

class _ChatFolderFormSheetState extends State<ChatFolderFormSheet> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();

  bool _isForAll = true;
  final Set<int> _selectedChatIds = {};
  final Map<int, Chats> _knownChats = {};

  String? _autoAssignType; // 'all_incoming', 'advertising', 'integrations'
  List<int> _selectedIntegrationIds = [];
  bool _assignExistingChats = true;

  bool _isSaving = false;
  String? _nameError;

  bool get _isEditing => widget.initialTab != null;

  @override
  void initState() {
    super.initState();

    if (widget.initialTab != null) {
      _nameController.text = widget.initialTab!.name;
      _isForAll = widget.initialTab!.isForAll;
      _selectedChatIds.addAll(widget.initialTab!.chatIds);
      _autoAssignType = widget.initialTab!.autoAssignType;
      _selectedIntegrationIds = List.from(widget.initialTab!.integrationIds);
      _assignExistingChats = widget.initialTab!.assignExistingChats ?? true;
    }

    if (widget.preselectedChatIds != null) {
      _selectedChatIds.addAll(widget.preselectedChatIds!);
    }

    if (widget.initialAvailableChats != null) {
      for (final c in widget.initialAvailableChats!) {
        _knownChats[c.id] = c;
      }
    }

    _loadCachedChats();
  }

  Future<void> _loadCachedChats() async {
    try {
      final offlineRepo = ChatOfflineRepository.fromRuntime(_apiService);
      final cached = await offlineRepo.readCachedChats(
        endPoint: widget.endpoint,
        page: 1,
        tabId: null,
      );
      if (cached != null && cached.data.isNotEmpty && mounted) {
        setState(() {
          for (final c in cached.data) {
            _knownChats[c.id] = c;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openAddChatsSheet() async {
    final result = await ChatFolderSelectChatsSheet.show(
      context,
      endpoint: widget.endpoint,
      currentSalesFunnelId: widget.currentSalesFunnelId,
      initialSelectedChatIds: _selectedChatIds,
      initialAvailableChats: widget.initialAvailableChats,
      preloadedChats: _knownChats,
    );

    if (result != null && mounted) {
      setState(() {
        _selectedChatIds.clear();
        _selectedChatIds.addAll(result.selectedChatIds);
        for (final chat in result.selectedChats) {
          _knownChats[chat.id] = chat;
        }
      });
    }
  }

  String _cleanMessagePreview(String raw) {
    if (raw.isEmpty) return '';
    String cleaned = raw
        .replaceAll(RegExp(r'</p>\s*<p>|<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .replaceAll('&nbsp;', ' ');
    if (cleaned.contains('<') && cleaned.contains('>')) {
      cleaned = stripHtmlTags(cleaned);
    }
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  ChatItem _toCleanChatItem(Chats chat) {
    final baseItem = chat.toChatItem();
    final cleanMsg = _cleanMessagePreview(chat.lastMessage);
    return ChatItem(
      baseItem.name,
      cleanMsg,
      baseItem.time,
      baseItem.avatar,
      baseItem.icon,
      baseItem.unreadCount,
      isGroup: baseItem.isGroup,
      chatId: chat.id,
      labels: baseItem.labels,
    );
  }

  Future<void> _saveFolder() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = AppLocalizations.of(context)?.translate('field_required') ??
            'Введите название';
      });
      return;
    }

    if ((_autoAssignType == 'integrations' ||
            _autoAssignType == 'advertising') &&
        _selectedIntegrationIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)
                    ?.translate('folder_at_least_one_integration') ??
                'Выберите хотя бы одну интеграцию',
          ),
          backgroundColor: context.appColors.error,
        ),
      );
      return;
    }

    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        final tabId = widget.initialTab!.id;
        try {
          await _apiService.updateChatTab(
            tabId: tabId,
            name: name,
            isForAll: _isForAll,
            salesFunnelId: widget.endpoint == 'lead'
                ? widget.currentSalesFunnelId
                : null,
            type: widget.endpoint,
            autoAssignType: _autoAssignType,
            integrationIds: (_autoAssignType == 'integrations' ||
                    _autoAssignType == 'advertising')
                ? _selectedIntegrationIds
                : null,
            assignExistingChats:
                _autoAssignType != null ? _assignExistingChats : null,
          );
        } catch (e) {
          debugPrint('ChatFolderFormSheet updateChatTab error: $e');
        }

        final oldChatIds = widget.initialTab!.chatIds.toSet();
        final toAttach = _selectedChatIds.difference(oldChatIds).toList();
        final toDetach = oldChatIds.difference(_selectedChatIds).toList();

        if (toAttach.isNotEmpty) {
          await _apiService.attachChatsToTab(
            tabId: tabId,
            chatIds: toAttach,
            type: widget.endpoint,
          );
        }
        if (toDetach.isNotEmpty) {
          await _apiService.detachChatsFromTab(
            tabId: tabId,
            chatIds: toDetach,
            type: widget.endpoint,
          );
        }

        if (mounted) {
          HapticFeedback.lightImpact();
          final updatedTab = widget.initialTab!.copyWith(
            name: name,
            isForAll: _isForAll,
            autoAssignType: _autoAssignType,
            integrationIds: _selectedIntegrationIds,
            assignExistingChats: _assignExistingChats,
          );
          Navigator.of(context).pop(updatedTab);
          return;
        }
      } else {
        final newTab = await _apiService.createChatTab(
          name: name,
          isForAll: _isForAll,
          salesFunnelId: widget.endpoint == 'lead'
              ? widget.currentSalesFunnelId
              : null,
          type: widget.endpoint,
          autoAssignType: _autoAssignType,
          integrationIds: (_autoAssignType == 'integrations' ||
                  _autoAssignType == 'advertising')
              ? _selectedIntegrationIds
              : null,
          assignExistingChats:
              _autoAssignType != null ? _assignExistingChats : null,
        );

        final targetId = newTab.id > 0 ? newTab.id : null;
        if (targetId != null && _selectedChatIds.isNotEmpty) {
          await _apiService.attachChatsToTab(
            tabId: targetId,
            chatIds: _selectedChatIds.toList(),
            type: widget.endpoint,
          );
        }

        if (mounted) {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop(newTab);
          return;
        }
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

  CustomDropdownDecoration _buildDropdownDecoration(
    AppThemeColors colors,
    AppThemeTextStyles textStyles,
  ) {
    return CustomDropdownDecoration(
      closedFillColor: colors.backgroundSecondary.withValues(alpha: 0.5),
      expandedFillColor: colors.surfacePrimary,
      closedBorder: Border.all(color: colors.borderSubtle),
      closedBorderRadius: BorderRadius.circular(12),
      expandedBorder: Border.all(color: colors.borderSubtle),
      expandedBorderRadius: BorderRadius.circular(12),
      hintStyle: textStyles.bodySm.copyWith(
        color: colors.textSecondary,
        fontSize: 13.0,
      ),
      headerStyle: textStyles.bodyMd.copyWith(
        color: colors.textPrimary,
        fontSize: 13.0,
        fontWeight: FontWeight.w500,
      ),
      listItemStyle: textStyles.bodyMd.copyWith(
        color: colors.textPrimary,
        fontSize: 13.0,
      ),
      closedSuffixIcon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: colors.textSecondary,
        size: 18.0,
      ),
      expandedSuffixIcon: Icon(
        Icons.keyboard_arrow_up_rounded,
        color: colors.textSecondary,
        size: 18.0,
      ),
      listItemDecoration: ListItemDecoration(
        selectedColor: colors.buttonPrimaryBg.withValues(alpha: 0.14),
        highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
        splashColor: Colors.transparent,
      ),
    );
  }

  Widget _buildFormCheckbox(bool isSelected, AppThemeColors colors) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? colors.buttonPrimaryBg : colors.borderSubtle,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(5),
        color: isSelected ? colors.buttonPrimaryBg : Colors.transparent,
      ),
      child: isSelected
          ? Icon(
              Icons.check,
              color: colors.buttonPrimaryFg,
              size: 13,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final localizations = AppLocalizations.of(context);

    final title = _isEditing
        ? (localizations?.translate('folder_edit') ?? 'Редактировать папку')
        : (localizations?.translate('folder_new') ?? 'Новая папка');

    final folderNameLabel =
        localizations?.translate('folder_title') ?? 'Название';
    final forAllLabel =
        localizations?.translate('folder_for_all') ?? 'Для всех сотрудников';
    final saveLabel = _isEditing
        ? (localizations?.translate('save') ?? 'Сохранить')
        : (localizations?.translate('create') ?? 'Создать');

    final autoAssignLeadHeader =
        (localizations?.translate('folder_auto_assign_lead') ??
                'ПОСТУПЛЕНИЕ ЛИДА В ТАБ')
            .toUpperCase();
    final autoAssignChooseHint =
        localizations?.translate('folder_auto_assign_choose') ??
            'Выберите условие поступления';

    final labelAllIncoming =
        localizations?.translate('folder_auto_all_incoming') ?? 'Все входящие';
    final labelAdvertising =
        localizations?.translate('folder_auto_advertising') ??
            'Из рекламных кампаний';
    final labelIntegrations =
        localizations?.translate('folder_auto_integrations') ??
            'Выбор интеграции';

    final autoAssignOptions = [
      labelAllIncoming,
      labelAdvertising,
      labelIntegrations,
    ];

    String? currentAutoAssignLabel;
    if (_autoAssignType == 'all_incoming') {
      currentAutoAssignLabel = labelAllIncoming;
    } else if (_autoAssignType == 'advertising') {
      currentAutoAssignLabel = labelAdvertising;
    } else if (_autoAssignType == 'integrations') {
      currentAutoAssignLabel = labelIntegrations;
    }

    final integrationsTitle =
        (localizations?.translate('folder_integrations_title') ??
                'ИНТЕГРАЦИИ')
            .toUpperCase();
    final integrationsHint =
        localizations?.translate('folder_integrations_hint') ??
            'Выберите интеграции';

    final moveExistingChatsLabel =
        localizations?.translate('folder_move_existing_chats') ??
            'Переместить старые чаты с таким фильтром';

    final selectedChatsHeader =
        (localizations?.translate('folder_selected_chats') ??
                'ВЫБРАННЫЕ ЧАТЫ')
            .toUpperCase();
    final addChatsBtnLabel =
        localizations?.translate('folder_add_chats') ?? 'Добавить чаты';
    final chatsHintLabel =
        localizations?.translate('folder_chats_hint') ??
            'Выберите чаты, которые нужно показывать в этой папке.';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Container(
              width: 36,
              height: 3.5,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.textSecondary,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textStyles.titleMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontSize: 17,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: _isSaving ? null : _saveFolder,
                  icon: Icon(
                    Icons.check_rounded,
                    color: colors.buttonPrimaryBg,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Section: НАЗВАНИЕ ПАПКИ
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      folderNameLabel.toUpperCase(),
                      style: textStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                        fontSize: 11.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameController,
                          onChanged: (_) {
                            if (_nameError != null) {
                              setState(() => _nameError = null);
                            }
                          },
                          style: textStyles.bodyMd.copyWith(
                            color: colors.textPrimary,
                            fontSize: 13.5,
                          ),
                          decoration: InputDecoration(
                            isDense: false,
                            hintText: folderNameLabel,
                            hintStyle: textStyles.bodySm.copyWith(
                              color: colors.textSecondary,
                              fontSize: 13.5,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            filled: true,
                            fillColor: colors.backgroundSecondary
                                .withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _nameError != null
                                    ? colors.error
                                    : colors.borderSubtle,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _nameError != null
                                    ? colors.error
                                    : colors.borderSubtle,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _nameError != null
                                    ? colors.error
                                    : colors.buttonPrimaryBg,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        if (_nameError != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 2),
                            child: Text(
                              _nameError!,
                              style: textStyles.caption.copyWith(
                                color: colors.error,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // "Для всех сотрудников" switch
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            colors.backgroundSecondary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            color: colors.buttonPrimaryBg,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              forAllLabel,
                              style: textStyles.bodySm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.72,
                            child: Switch.adaptive(
                              value: _isForAll,
                              activeTrackColor: colors.buttonPrimaryBg,
                              onChanged: (val) {
                                setState(() => _isForAll = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (widget.endpoint == 'lead') ...[
                    const SizedBox(height: 10),

                    // Поступление лида в таб (no "Сбросить" button)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            autoAssignLeadHeader,
                            style: textStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                              fontSize: 11.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          CustomDropdown<String>(
                            key: ValueKey(
                                'auto_assign_dropdown_$_autoAssignType'),
                            hintText: autoAssignChooseHint,
                            items: autoAssignOptions,
                            initialItem: currentAutoAssignLabel,
                            decoration:
                                _buildDropdownDecoration(colors, textStyles),
                            overlayHeight: 200,
                            onChanged: (val) {
                              setState(() {
                                if (val == labelAllIncoming) {
                                  final prevType = _autoAssignType;
                                  _autoAssignType = 'all_incoming';
                                  if (prevType == null) {
                                    _assignExistingChats = true;
                                  }
                                  _selectedIntegrationIds.clear();
                                } else if (val == labelAdvertising) {
                                  final prevType = _autoAssignType;
                                  _autoAssignType = 'advertising';
                                  if (prevType == null) {
                                    _assignExistingChats = true;
                                  }
                                } else if (val == labelIntegrations) {
                                  final prevType = _autoAssignType;
                                  _autoAssignType = 'integrations';
                                  if (prevType == null) {
                                    _assignExistingChats = true;
                                  }
                                } else {
                                  _autoAssignType = null;
                                  _selectedIntegrationIds.clear();
                                  _assignExistingChats = false;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Поле Интеграции
                    if (_autoAssignType == 'integrations' ||
                        _autoAssignType == 'advertising') ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ChannelsMultiSelectWidget(
                          title: integrationsTitle,
                          hintText: integrationsHint,
                          titleSpacing: 4,
                          closedFillColor: colors.backgroundSecondary
                              .withValues(alpha: 0.5),
                          headerStyle: textStyles.bodyMd.copyWith(
                            color: colors.textPrimary,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                          ),
                          hintStyle: textStyles.bodySm.copyWith(
                            color: colors.textSecondary,
                            fontSize: 13.0,
                          ),
                          selectedChannels: _selectedIntegrationIds
                              .map((id) => id.toString())
                              .toList(),
                          onSelectChannels: (selectedChannels) {
                            setState(() {
                              _selectedIntegrationIds =
                                  selectedChannels.map((c) => c.id).toList();
                            });
                          },
                        ),
                      ),
                    ],

                    // Галочка "Переместить старые чаты с таким фильтром"
                    if (_autoAssignType != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() =>
                                _assignExistingChats = !_assignExistingChats);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: colors.backgroundSecondary
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.borderSubtle,
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildFormCheckbox(
                                    _assignExistingChats, colors),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    moveExistingChatsLabel,
                                    style: textStyles.bodySm.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colors.textPrimary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 14),

                  // Section: ВЫБРАННЫЕ ЧАТЫ (Telegram Style)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedChatsHeader,
                          style: textStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                            fontSize: 11.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (_selectedChatIds.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.buttonPrimaryBg
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_selectedChatIds.length}',
                              style: textStyles.caption.copyWith(
                                color: colors.buttonPrimaryBg,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Telegram-style Card for chats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            colors.backgroundSecondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          // "+ Добавить чаты" button row
                          InkWell(
                            onTap: _openAddChatsSheet,
                            borderRadius: _selectedChatIds.isEmpty
                                ? BorderRadius.circular(14)
                                : const BorderRadius.vertical(
                                    top: Radius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 11),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: colors.buttonPrimaryBg
                                          .withValues(alpha: 0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: colors.buttonPrimaryBg,
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      addChatsBtnLabel,
                                      style: textStyles.bodyMd.copyWith(
                                        color: colors.buttonPrimaryBg,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: colors.textSecondary
                                        .withValues(alpha: 0.6),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // List of selected chats
                          if (_selectedChatIds.isNotEmpty) ...[
                            Divider(
                              height: 1,
                              color: colors.borderSubtle.withValues(alpha: 0.7),
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _selectedChatIds.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                indent: 52,
                                color: colors.borderSubtle
                                    .withValues(alpha: 0.5),
                              ),
                              itemBuilder: (context, index) {
                                final chatId =
                                    _selectedChatIds.elementAt(index);
                                final chat = _knownChats[chatId];
                                final chatItem = chat != null ? _toCleanChatItem(chat) : null;
                                final chatName = chatItem?.name ?? (chat?.displayName ?? 'Чат #$chatId');
                                final lastMsg = chatItem?.message ??
                                    (chat != null
                                        ? _cleanMessagePreview(chat.lastMessage)
                                        : '');

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      _buildChatAvatar(chatItem, chat, chatName, colors),
                                      const SizedBox(width: 10),
                                      // Name & preview
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              chatName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  textStyles.bodySm.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: colors.textPrimary,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (lastMsg.isNotEmpty)
                                              Text(
                                                lastMsg,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style:
                                                    textStyles.caption.copyWith(
                                                  color: colors.textSecondary,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Remove button
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 28, minHeight: 28),
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _selectedChatIds.remove(chatId);
                                          });
                                        },
                                        icon: Icon(
                                          Icons.remove_circle_rounded,
                                          color: colors.error
                                              .withValues(alpha: 0.8),
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Helper Subtitle
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 16, top: 6),
                    child: Text(
                      chatsHintLabel,
                      style: textStyles.caption.copyWith(
                        color: colors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              border: Border(
                top: BorderSide(
                    color: colors.borderSubtle.withValues(alpha: 0.6)),
              ),
            ),
            child: CustomButton(
              buttonText: _selectedChatIds.isNotEmpty
                  ? '$saveLabel (${_selectedChatIds.length})'
                  : saveLabel,
              isLoading: _isSaving,
              buttonColor: colors.buttonPrimaryBg,
              textColor: colors.buttonPrimaryFg,
              onPressed: _isSaving ? null : _saveFolder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatAvatar(
    ChatItem? item,
    Chats? chat,
    String displayName,
    AppThemeColors colors,
  ) {
    const double size = 36.0;

    // 1. Channel icon (WhatsApp, Instagram, Telegram, site, etc.)
    final iconName = (item?.icon != null && item!.icon.isNotEmpty)
        ? item.icon
        : (chat != null && chat.channel.isNotEmpty ? chat.channel : '');

    final kind = resolveChannelSourceKind(iconName);
    if (kind != ChannelSourceKind.unknown) {
      final isSite = kind == ChannelSourceKind.site;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.backgroundSecondary,
          border: Border.all(
            color: colors.borderSubtle,
            width: 1,
          ),
        ),
        child: Center(
          child: ChannelSourceIcon(
            sourceName: isSite ? 'site' : iconName,
            size: isSite ? 20.0 : size,
            background: colors.backgroundSecondary,
          ),
        ),
      );
    }

    // 2. Custom photo (if not default AvatarChat / AvatarTask)
    final avatarUrl = item?.avatar ?? chat?.image;
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl != 'assets/images/AvatarChat.png' &&
        avatarUrl != 'assets/images/AvatarTask.png') {
      if (avatarUrl.startsWith('assets/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.asset(
            avatarUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _buildInitialsAvatar(displayName, colors, size: size),
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.network(
            avatarUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _buildInitialsAvatar(displayName, colors, size: size),
          ),
        );
      }
    }

    return _buildInitialsAvatar(displayName, colors, size: size);
  }

  Widget _buildInitialsAvatar(
    String displayName,
    AppThemeColors colors, {
    double size = 32.0,
  }) {
    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.buttonPrimaryBg.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: colors.buttonPrimaryBg,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
