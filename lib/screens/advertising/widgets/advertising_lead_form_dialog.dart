import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/lead/lead_model.dart';
import 'package:crm_task_manager/models/lead/manager_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class AdvertisingLeadFormDialog extends StatefulWidget {
  final String formId;
  final String formTitle;
  final int adsCount;
  final Map<String, dynamic>? sampleQuestions;
  final int? initialStatusId;
  final List<int>? initialManagerIds;

  const AdvertisingLeadFormDialog({
    super.key,
    required this.formId,
    required this.formTitle,
    this.adsCount = 1,
    this.sampleQuestions,
    this.initialStatusId,
    this.initialManagerIds,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String formId,
    required String formTitle,
    int adsCount = 1,
    Map<String, dynamic>? sampleQuestions,
    int? initialStatusId,
    List<int>? initialManagerIds,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdvertisingLeadFormDialog(
        formId: formId,
        formTitle: formTitle,
        adsCount: adsCount,
        sampleQuestions: sampleQuestions,
        initialStatusId: initialStatusId,
        initialManagerIds: initialManagerIds,
      ),
    );
  }

  @override
  State<AdvertisingLeadFormDialog> createState() =>
      _AdvertisingLeadFormDialogState();
}

class _AdvertisingLeadFormDialogState extends State<AdvertisingLeadFormDialog>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _canUpdate = false;
  bool _appendAnswers = true;

  List<LeadStatus> _statuses = [];
  List<ManagerData> _managers = [];

  int? _selectedStatusId;
  final List<int> _selectedManagerIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedStatusId = widget.initialStatusId;
    if (widget.initialManagerIds != null) {
      _selectedManagerIds.addAll(widget.initialManagerIds!);
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final canUpdate =
          await _apiService.hasPermission('advertisingCampaigns.update');
      final statuses = await _apiService.getLeadStatuses();
      final managersResp = await _apiService.getAllManager();

      if (mounted) {
        setState(() {
          _canUpdate = canUpdate;
          _statuses = statuses;
          _managers = managersResp.result ?? [];
          if (_selectedStatusId == null && _statuses.isNotEmpty) {
            _selectedStatusId = _statuses.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_selectedStatusId == null) return;
    setState(() => _isSaving = true);

    try {
      final success = await _apiService.saveLeadFormSettings(
        formId: widget.formId,
        leadStatusId: _selectedStatusId!,
        managerIds: _selectedManagerIds,
        appendAnswers: _appendAnswers,
      );

      if (mounted) {
        Navigator.pop(context, success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.backgroundPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: colors.iconPrimary,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.translate('lead_form_settings'),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                          Text(
                            widget.formTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Эта форма у ${widget.adsCount} объявлений — настройка общая для всех них и для будущих',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Warning Container matching Screenshot 8
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: colors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.translate('form_not_configured_warning'),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textPrimary,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.borderSubtle),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: colors.buttonPrimaryBg,
                  labelColor: colors.textPrimary,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: t.translate('tab_main')),
                    Tab(text: t.translate('tab_extra_desc')),
                    Tab(text: t.translate('tab_extra_fields')),
                  ],
                ),
              ),

              // Tab contents
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colors.buttonPrimaryBg,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMainTab(context, scrollController),
                          _buildPlaceholderTab(context, 'Дополнительное описание'),
                          _buildPlaceholderTab(context, 'Дополнительные поля'),
                        ],
                      ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfacePrimary,
                  border: Border(
                    top: BorderSide(color: colors.borderSubtle),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _appendAnswers,
                          activeColor: colors.buttonPrimaryBg,
                          onChanged: (val) {
                            setState(() => _appendAnswers = val ?? true);
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _appendAnswers = !_appendAnswers);
                            },
                            child: Text(
                              t.translate('append_answers_to_existing_leads'),
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textPrimary,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: colors.borderSubtle),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              t.translate('cancel'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.buttonPrimaryBg,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _canUpdate && !_isSaving
                                ? _saveSettings
                                : null,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.save_outlined,
                                          size: 18, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        t.translate('save'),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontFamily: 'Gilroy',
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainTab(BuildContext context, ScrollController scrollController) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Lead Status field
        Text(
          t.translate('lead_status'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Gilroy',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.surfacePrimary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedStatusId,
              isExpanded: true,
              dropdownColor: colors.surfacePrimary,
              icon: Icon(Icons.expand_more, color: colors.iconSecondary),
              items: _statuses.map((status) {
                return DropdownMenuItem<int>(
                  value: status.id,
                  child: Text(
                    status.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textPrimary,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedStatusId = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'В этот статус попадает новый лид и тот, кто оставил заявку повторно.',
          style: TextStyle(
            fontSize: 11,
            color: colors.textMuted,
            fontFamily: 'Gilroy',
          ),
        ),

        const SizedBox(height: 18),

        // Managers Multi-select field
        Text(
          t.translate('managers'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Gilroy',
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _openManagersSelector(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedManagerIds.isEmpty
                        ? t.translate('select_managers')
                        : 'Выбрано менеджеров: ${_selectedManagerIds.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedManagerIds.isEmpty
                          ? colors.textSecondary
                          : colors.textPrimary,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
                Icon(Icons.expand_more, color: colors.iconSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          t.translate('leads_without_manager_distributed'),
          style: TextStyle(
            fontSize: 11,
            color: colors.textMuted,
            fontFamily: 'Gilroy',
          ),
        ),

        const SizedBox(height: 24),

        // Questions and Answers preview
        Text(
          t.translate('form_questions_and_last_answer'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Gilroy',
          ),
        ),
        const SizedBox(height: 8),

        _buildQuestionsPreview(context),
      ],
    );
  }

  Widget _buildQuestionsPreview(BuildContext context) {
    final colors = context.appColors;

    // Use passed sampleQuestions or typical meta form questions fallback
    final questions = widget.sampleQuestions ?? {
      'Намуди бизнеси шумо': 'дигар бизнес дорам',
      'Миқдори кормандон дар бизнес': 'зиёда аз 50 нафар',
      'Рақами телефонатонро гузоред': '900140491',
      'Полное имя': 'Фазлиддин Мудинов',
      'Номер телефона': '+992938979791',
      'Город': 'Dushanbe',
    };

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: questions.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.borderSubtle.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.value?.toString() ?? '—',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlaceholderTab(BuildContext context, String title) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '$title настраивается автоматически при получении ответов формы',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
            fontFamily: 'Gilroy',
          ),
        ),
      ),
    );
  }

  void _openManagersSelector(BuildContext context) {
    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: colors.backgroundPrimary,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Выберите менеджеров',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Готово',
                            style: TextStyle(
                              color: colors.buttonPrimaryBg,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _managers.length,
                      itemBuilder: (context, index) {
                        final mgr = _managers[index];
                        final isSelected =
                            _selectedManagerIds.contains(mgr.id);

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: colors.buttonPrimaryBg,
                          title: Text(
                            mgr.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textPrimary,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                _selectedManagerIds.add(mgr.id);
                              } else {
                                _selectedManagerIds.remove(mgr.id);
                              }
                            });
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
