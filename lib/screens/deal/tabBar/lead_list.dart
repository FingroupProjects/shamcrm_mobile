import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/app/app_keys.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/models/lead/lead_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _LeadRefreshPhase { idle, requested, loading, done }

class LeadRadioGroupWidget extends StatefulWidget {
  final String? selectedLead;
  final Function(LeadData) onSelectLead;
  final bool showDebt;
  final bool alwaysRefreshFromServer;
  final bool clearCacheBeforeRefresh;
  final List<int> excludedLeadIds;
  final String? labelText;
  final String? hintText;
  final String? searchHintText;

  /// Лид, который уже известен экрану (например, из просмотра заказа).
  /// Показываем его сразу, не дожидаясь первой страницы списка.
  final LeadData? initialSelectedLead;

  const LeadRadioGroupWidget({
    super.key,
    required this.onSelectLead,
    this.selectedLead,
    this.showDebt = false,
    this.alwaysRefreshFromServer = false,
    this.clearCacheBeforeRefresh = false,
    this.excludedLeadIds = const [],
    this.labelText,
    this.hintText,
    this.searchHintText,
    this.initialSelectedLead,
  });

  @override
  State<LeadRadioGroupWidget> createState() => _LeadRadioGroupWidgetState();
}

class _LeadRadioGroupWidgetState extends State<LeadRadioGroupWidget>
    with RouteAware {
  final ApiService _apiService = ApiService();
  List<LeadData> leadsList = [];
  LeadData? selectedLeadData;
  bool _isInitialized = false;
  bool _initialLeadSet = false;
  int _listVersion = 0;
  _LeadRefreshPhase _refreshPhase = _LeadRefreshPhase.idle;

  bool _isExcluded(int leadId) => widget.excludedLeadIds.contains(leadId);

  bool _sameLeadId(LeadData lead, String? leadId) =>
      leadId != null && leadId.isNotEmpty && lead.id.toString() == leadId;

  /// Клиент, которого поле должно продолжать показывать.
  /// После выбора товаров список лидов перезагружается только первой страницей.
  /// Клиент из поиска на эту страницу часто не попадает, и раньше поле очищалось.
  LeadData? _pinnedLead() {
    final selectedId = widget.selectedLead;
    if (selectedId == null || selectedId.isEmpty) return null;

    if (selectedLeadData != null && _sameLeadId(selectedLeadData!, selectedId)) {
      return selectedLeadData;
    }

    for (final lead in leadsList) {
      if (_sameLeadId(lead, selectedId)) return lead;
    }

    final initial = widget.initialSelectedLead;
    if (initial != null && _sameLeadId(initial, selectedId)) return initial;

    return null;
  }

  /// В список дропдауна всегда кладём выбранного клиента,
  /// даже если свежая первая страница его не содержит.
  List<LeadData> _dropdownItems() {
    final pinned = _pinnedLead();
    if (pinned == null) return leadsList;
    if (leadsList.any((lead) => lead.id == pinned.id)) return leadsList;
    return [pinned, ...leadsList];
  }

  void _reloadLeads() {
    if (!mounted) return;
    setState(() {
      if (widget.alwaysRefreshFromServer) {
        // Не затираем выбранного клиента пустым списком:
        // иначе дропдаун пересоздаётся без значения.
        final pinned = _pinnedLead();
        if (pinned != null) {
          selectedLeadData = pinned;
        }
        leadsList = pinned == null ? <LeadData>[] : <LeadData>[pinned];
        _isInitialized = false;
        _refreshPhase = _LeadRefreshPhase.requested;
        _listVersion++;
        if (widget.selectedLead == null || widget.selectedLead!.isEmpty) {
          selectedLeadData = null;
          _initialLeadSet = true;
        } else {
          _initialLeadSet = selectedLeadData != null;
        }
      }
    });
    context.read<GetAllLeadBloc>().add(
          RefreshAllLeadEv(
            showDebt: widget.showDebt,
            clearOfflineCache:
                widget.alwaysRefreshFromServer || widget.clearCacheBeforeRefresh,
          ),
        );
  }

  bool _hasPhone(LeadData lead) => (lead.phone ?? '').trim().isNotEmpty;

  Widget _buildLeadInfo(
    LeadData lead, {
    double nameFontSize = 14,
    double phoneFontSize = 12,
  }) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lead.name,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: nameFontSize,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            height: 1.2,
          ),
        ),
        if (_hasPhone(lead))
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              lead.phone!.trim(),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: phoneFontSize,
                fontWeight: FontWeight.w400,
                fontFamily: 'Gilroy',
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSelectedLead;
    final hasSelectedId =
        widget.selectedLead != null && widget.selectedLead!.isNotEmpty;
    if (initial != null &&
        (!hasSelectedId || _sameLeadId(initial, widget.selectedLead))) {
      // Сразу показываем лида из заказа, до ответа сервера.
      selectedLeadData = initial;
      leadsList = [initial];
      _initialLeadSet = true;
    } else if (!hasSelectedId) {
      _initialLeadSet = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.alwaysRefreshFromServer) {
          _reloadLeads();
        } else {
          context.read<GetAllLeadBloc>().add(
                GetAllLeadEv(showDebt: widget.showDebt),
              );
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (widget.alwaysRefreshFromServer) {
      _reloadLeads();
    }
  }

  @override
  void didUpdateWidget(LeadRadioGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload when showDebt changes
    if (oldWidget.showDebt != widget.showDebt) {
      _reloadLeads();
    }

    // React to external selectedLead change
    if (oldWidget.selectedLead != widget.selectedLead) {
      _updateSelectedLeadData();
    }
  }

  void _updateSelectedLeadData() {
    final selectedId = widget.selectedLead;
    if (selectedId == null || selectedId.isEmpty) {
      selectedLeadData = null;
      _initialLeadSet = true;
      return;
    }

    for (final lead in leadsList) {
      if (_sameLeadId(lead, selectedId)) {
        selectedLeadData = lead;
        _initialLeadSet = true;
        return;
      }
    }

    // Клиента нет на текущей странице. Если он уже выбран — оставляем его.
    // Пустой список во время обновления тоже не должен сбрасывать поле.
    if (selectedLeadData != null && _sameLeadId(selectedLeadData!, selectedId)) {
      _initialLeadSet = true;
      return;
    }

    // В редактировании заказа лид уже есть в карточке, но может не попасть
    // на первую страницу списка. Показываем его из заказа, а не пустое поле.
    final initial = widget.initialSelectedLead;
    if (initial != null && _sameLeadId(initial, selectedId)) {
      selectedLeadData = initial;
      _initialLeadSet = true;
      return;
    }

    _initialLeadSet = true;
  }

  Future<CustomDropdownPaginatedResponse<LeadData>> _searchLeads(
    String query,
    int page,
  ) async {
    try {
      final response = await _apiService.getLeadPage(
        page,
        showDebt: widget.showDebt,
        search: query,
        bypassCache: widget.alwaysRefreshFromServer,
      );
      final items = (response.result ?? <LeadData>[])
          .where((lead) => !_isExcluded(lead.id))
          .toList();
      final pagination = response.pagination;

      return CustomDropdownPaginatedResponse<LeadData>(
        items: items,
        hasMore:
            (pagination?.currentPage ?? page) < (pagination?.totalPages ?? 1),
      );
    } catch (_) {
      return const CustomDropdownPaginatedResponse<LeadData>(
        items: <LeadData>[],
        hasMore: false,
      );
    }
  }

  @override

  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('lead'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllLeadBloc, GetAllLeadState>(
          builder: (context, state) {
            final isLoading = state is GetAllLeadLoading;
            final isInitial = state is GetAllLeadInitial;
            final errorMessage =
                state is GetAllLeadError ? state.message : null;

            if (isLoading || isInitial) {
              if (_refreshPhase == _LeadRefreshPhase.requested) {
                _refreshPhase = _LeadRefreshPhase.loading;
              }
            }

            if (state is GetAllLeadSuccess) {
              if (_refreshPhase != _LeadRefreshPhase.requested) {
                leadsList = (state.dataLead.result ?? [])
                    .where((lead) => !_isExcluded(lead.id))
                    .toList();
                _isInitialized = true;
                _refreshPhase = _LeadRefreshPhase.done;
                _updateSelectedLeadData();
              }
            } else if (state is GetAllLeadError) {
              _isInitialized = true;
              _refreshPhase = _LeadRefreshPhase.done;
              _updateSelectedLeadData();
            }

            final isStillLoading =
                _refreshPhase == _LeadRefreshPhase.requested ||
                    _refreshPhase == _LeadRefreshPhase.loading ||
                    ((isLoading || isInitial) && !_isInitialized);

            // Пока список грузится заново, выбранный клиент остаётся в поле.
            // Раньше на время загрузки сюда передавался null, и значение пропадало.
            final dropdownItems = _dropdownItems();
            final actualInitialItem = _pinnedLead();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomDropdown<LeadData>.searchRequestPaginated(
                  key: ValueKey(
                    'lead_field_${_listVersion}_${actualInitialItem?.id ?? 'none'}',
                  ),
                  paginatedRequest: _searchLeads,
                  futureRequestDelay: const Duration(milliseconds: 350),
                  closeDropDownOnClearFilterSearch: true,
                  items: dropdownItems,
                  searchHintText: widget.searchHintText ??
                      AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: !isStillLoading,
                  // Theme error (gold), not package default red.
                  decoration: AppFieldStyle.dropdownDecoration(context),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLeadInfo(item),
                        if (widget.showDebt &&
                            item.debt != null &&
                            item.debt != 0)
                          Padding(
                            padding: EdgeInsets.only(
                              top: _hasPhone(item) ? 4 : 2,
                            ),
                            child: Text(
                              'Долг: ${item.debt!.toStringAsFixed(2)}',
                              style: TextStyle(
                                color:
                                    item.debt! > 0 ? Colors.red : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    // Имя клиента показываем и во время обновления списка.
                    // Спиннер вместо имени выглядел так, будто поле «Клиент» сбросилось.
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLeadInfo(
                          selectedItem,
                          phoneFontSize: 11,
                        ),
                        if (widget.showDebt &&
                            selectedItem.debt != null &&
                            selectedItem.debt! != 0)
                          Text(
                            'Долг: ${selectedItem.debt!.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: selectedItem.debt! > 0
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                      ],
                    );
                  },
                  hintBuilder: (context, hint, enabled) {
                    if (isStillLoading) {
                      return Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.appColors.buttonPrimaryBg,
                            ),
                          ),
                        ),
                      );
                    }

                    return Text(
                      AppLocalizations.of(context)!.translate('select_lead'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: context.appColors.textPrimary,
                      ),
                    );
                  },
                  noResultFoundBuilder: (context, text) {
                    if (isStillLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xff1E2E52),
                            ),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          AppLocalizations.of(context)!.translate('no_results'),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                  excludeSelected: false,
                  initialItem: actualInitialItem,
                  validator: (_isInitialized && _initialLeadSet)
                      ? (value) {
                          if (value == null) {
                            return AppLocalizations.of(context)!
                                .translate('field_required');
                          }
                          return null;
                        }
                      : null,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onSelectLead(value);
                      setState(() {
                        selectedLeadData = value;
                      });
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
                if (errorMessage != null && leadsList.isEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          errorMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _reloadLeads,
                        child: Text(
                          AppLocalizations.of(context)!.translate('refresh'),
                          style: const TextStyle(
                            color: Color(0xFF4759FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
