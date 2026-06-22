import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  });

  @override
  State<LeadRadioGroupWidget> createState() => _LeadRadioGroupWidgetState();
}

class _LeadRadioGroupWidgetState extends State<LeadRadioGroupWidget> {
  final ApiService _apiService = ApiService();
  List<LeadData> leadsList = [];
  LeadData? selectedLeadData;
  bool _isInitialized = false;
  bool _initialLeadSet = false;

  bool _isExcluded(int leadId) => widget.excludedLeadIds.contains(leadId);

  void _reloadLeads() {
    if (widget.alwaysRefreshFromServer && mounted) {
      setState(() {
        leadsList = [];
        selectedLeadData = null;
        _isInitialized = false;
        _initialLeadSet = false;
      });
    }
    context.read<GetAllLeadBloc>().add(
          RefreshAllLeadEv(
            showDebt: widget.showDebt,
            clearOfflineCache: widget.clearCacheBeforeRefresh,
          ),
        );
  }

  bool _hasPhone(LeadData lead) => (lead.phone ?? '').trim().isNotEmpty;

  Widget _buildLeadInfo(
    LeadData lead, {
    double nameFontSize = 14,
    double phoneFontSize = 12,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lead.name,
          style: TextStyle(
            color: const Color(0xff1E2E52),
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
                color: const Color(0xff99A4BA),
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
    if (widget.selectedLead == null || widget.selectedLead!.isEmpty) {
      selectedLeadData = null;
      _initialLeadSet = true;
      return;
    }

    if (leadsList.isEmpty) {
      selectedLeadData = null;
      _initialLeadSet = true;
      return;
    }

    if (widget.selectedLead != null && leadsList.isNotEmpty) {
      try {
        selectedLeadData = leadsList.firstWhere(
          (lead) => lead.id.toString() == widget.selectedLead,
        );
        _initialLeadSet = true;
      } catch (e) {
        selectedLeadData = null;
        _initialLeadSet = true; // Processed even if not found
      }
    } else {
      selectedLeadData = null;
      _initialLeadSet = leadsList.isNotEmpty;
    }
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
          widget.labelText ?? AppLocalizations.of(context)!.translate('lead'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllLeadBloc, GetAllLeadState>(
          builder: (context, state) {
            final isLoading = state is GetAllLeadLoading;
            final isInitial = state is GetAllLeadInitial;
            final errorMessage =
                state is GetAllLeadError ? state.message : null;

            // SUCCESS → fresh data
            if (state is GetAllLeadSuccess) {
              leadsList = (state.dataLead.result ?? [])
                  .where((lead) => !_isExcluded(lead.id))
                  .toList();
              _isInitialized = true;
              _updateSelectedLeadData();
            }
            // ERROR → stop infinite loading and keep last known data if any
            else if (state is GetAllLeadError) {
              _isInitialized = true;
              _updateSelectedLeadData();
            }

            final isStillLoading =
                ((isLoading || isInitial) && !_isInitialized) ||
                    !_initialLeadSet;

            final actualInitialItem = isStillLoading
                ? null
                : (selectedLeadData != null &&
                        leadsList.contains(selectedLeadData))
                    ? selectedLeadData
                    : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomDropdown<LeadData>.searchRequestPaginated(
                  key: ValueKey(selectedLeadData
                      ?.id), // ← Forces rebuild when pre-selected lead changes
                  paginatedRequest: _searchLeads,
                  futureRequestDelay: const Duration(milliseconds: 350),
                  closeDropDownOnClearFilterSearch: true,
                  items: leadsList,
                  searchHintText: widget.searchHintText ??
                      AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: !isStillLoading,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: const Color(0xffF4F7FD),
                    expandedFillColor: Colors.white,
                    closedBorder:
                        Border.all(color: const Color(0xffF4F7FD), width: 1),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder:
                        Border.all(color: const Color(0xffF4F7FD), width: 1),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
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
                    if (isStillLoading) {
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xff1E2E52),
                            ),
                          ),
                        ),
                      );
                    }

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
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xff1E2E52),
                            ),
                          ),
                        ),
                      );
                    }

                    return Text(
                      widget.hintText ??
                          AppLocalizations.of(context)!
                              .translate('select_lead'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
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
                                .translate('field_required_project');
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
                            color: Color(0xffEF4444),
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
                            color: Color(0xff4759FF),
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
