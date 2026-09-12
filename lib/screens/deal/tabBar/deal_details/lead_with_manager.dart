import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/app/app_keys.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/models/lead/lead_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadWithManager extends StatefulWidget {
  final String? selectedLead;
  final Function(LeadData) onSelectLead;
  final bool alwaysRefreshFromServer;

  const LeadWithManager({
    super.key,
    required this.onSelectLead,
    this.selectedLead,
    this.alwaysRefreshFromServer = false,
  });

  @override
  State<LeadWithManager> createState() => _LeadWithManagerState();
}

class _LeadWithManagerState extends State<LeadWithManager> with RouteAware {
  final ApiService _apiService = ApiService();
  static const int _pageSize = 20;
  List<LeadData> leadsList = [];
  LeadData? selectedLeadData;
  int _listVersion = 0;
  bool _ignoreStaleSuccess = false;

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
            color: context.appColors.textPrimary,
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
                color: context.appColors.textSecondary,
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
    //print('LeadWithManager: initState started');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadLeads(forceRefresh: widget.alwaysRefreshFromServer);
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
      _loadLeads(forceRefresh: true);
    }
  }

  void _loadLeads({required bool forceRefresh}) {
    if (forceRefresh) {
      setState(() {
        leadsList = [];
        _ignoreStaleSuccess = true;
        _listVersion++;
      });
      context.read<GetAllLeadBloc>().add(
            RefreshAllLeadEv(clearOfflineCache: true),
          );
      return;
    }
    final state = context.read<GetAllLeadBloc>().state;
    if (state is GetAllLeadSuccess) {
      leadsList = state.dataLead.result ?? [];
      _updateSelectedLeadData();
    }
    if (state is! GetAllLeadSuccess) {
      context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    }
  }

  void _updateSelectedLeadData() {
    //print('LeadWithManager: Updating selected lead, prop selectedLead: ${widget.selectedLead}');
    if (widget.selectedLead != null && leadsList.isNotEmpty) {
      try {
        final newSelectedLead = leadsList.firstWhere(
          (lead) => lead.id.toString() == widget.selectedLead,
        );
        if (selectedLeadData?.id != newSelectedLead.id) {
          selectedLeadData = newSelectedLead;
          //print('LeadWithManager: Found lead: ${newSelectedLead.id}, managerId: ${newSelectedLead.managerId}');
          widget.onSelectLead(newSelectedLead);
        } else {
          //print('LeadWithManager: Lead ${newSelectedLead.id} already selected, skipping onSelectLead');
        }
      } catch (e) {
        //print('LeadWithManager: Lead not found for ID ${widget.selectedLead}: $e');
        selectedLeadData = null;
      }
    } else {
      //print('LeadWithManager: No selected lead or empty leads list');
      selectedLeadData = null;
    }
  }

  Future<CustomDropdownPaginatedResponse<LeadData>> _searchLeads(
    String query,
    int page,
  ) async {
    final response = await _apiService.getLeadPage(
      page,
      search: query,
      bypassCache: widget.alwaysRefreshFromServer,
    );
    final items = response.result ?? <LeadData>[];
    final pagination = response.pagination;

    return CustomDropdownPaginatedResponse<LeadData>(
      items: items,
      hasMore: (pagination?.currentPage ?? page) <
          (pagination?.totalPages ??
              (items.length >= _pageSize ? page + 1 : page)),
    );
  }

  @override
  Widget build(BuildContext context) {
    //print('LeadWithManager: Building with selectedLeadData: ${selectedLeadData?.id}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('lead'),
          style: context.appTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllLeadBloc, GetAllLeadState>(
          builder: (context, state) {
            //print('LeadWithManager: BlocBuilder state: $state');
            if (state is GetAllLeadLoading) {
              _ignoreStaleSuccess = false;
            } else if (state is GetAllLeadSuccess && !_ignoreStaleSuccess) {
              leadsList = state.dataLead.result ?? [];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateSelectedLeadData();
              });
            }

            return CustomDropdown<LeadData>.searchRequestPaginated(
              key: ValueKey('lead_manager_$_listVersion'),
              paginatedRequest: _searchLeads,
              futureRequestDelay: const Duration(milliseconds: 350),
              closeDropDownOnClearFilterSearch: true,
              items: leadsList,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 400,
              enabled: true,
              decoration: CustomDropdownDecoration(
                closedFillColor: context.appColors.fieldBackground,
                expandedFillColor: context.appColors.surfacePrimary,
                closedBorder: AppFieldStyle.dropdownBorder(context),
                closedErrorBorder: AppFieldStyle.dropdownBorder(
                  context,
                  hasError: true,
                ),
                closedBorderRadius: AppFieldStyle.radius,
                closedErrorBorderRadius: AppFieldStyle.radius,
                expandedBorder: AppFieldStyle.dropdownBorder(context),
                expandedBorderRadius: AppFieldStyle.radius,
                errorStyle: AppFieldStyle.errorTextStyle(context),
                searchFieldDecoration: SearchFieldDecoration(
                  fillColor: context.appColors.fieldBackground,
                  hintStyle: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textSecondary,
                  ),
                  textStyle: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: context.appColors.textSecondary,
                  ),
                  suffixIcon: (onClear) => IconButton(
                    onPressed: onClear,
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  border: AppFieldStyle.outline(context),
                  focusedBorder: AppFieldStyle.outline(context, focused: true),
                ),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return _buildLeadInfo(item);
              },
              headerBuilder: (context, selectedItem, enabled) {
                if (state is GetAllLeadLoading) {
                  return Text(
                    AppLocalizations.of(context)!.translate('select_client'),
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textSecondary,
                    ),
                  );
                }
                return _buildLeadInfo(
                  selectedItem,
                  phoneFontSize: 11,
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('select_client'),
                style: context.appTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textSecondary,
                ),
              ),
              excludeSelected: false,
              initialItem: leadsList.contains(selectedLeadData)
                  ? selectedLeadData
                  : null,
              validator: (value) {
                if (value == null) {
                  return AppLocalizations.of(context)!.translate('field_required');
                }
                return null;
              },
              onChanged: (value) {
                if (value != null) {
                  //print('LeadWithManager: User selected lead: ${value.id}, managerId: ${value.managerId}');
                  widget.onSelectLead(value);
                  setState(() {
                    selectedLeadData = value;
                    //print('LeadWithManager: Updated selectedLeadData to: ${value.id}');
                  });
                  FocusScope.of(context).unfocus();
                }
              },
            );
          },
        ),
      ],
    );
  }
}
