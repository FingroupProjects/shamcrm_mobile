import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_multi_list/lead_multi_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadMultiSelectWidget extends StatefulWidget {
  final List<dynamic>? selectedLeads;
  final Function(List<LeadData>) onSelectLeads;
  final bool useSecondaryBackground;

  const LeadMultiSelectWidget({
    super.key,
    required this.onSelectLeads,
    this.selectedLeads,
    this.useSecondaryBackground = false,
  });

  @override
  State<LeadMultiSelectWidget> createState() => _LeadsMultiSelectWidgetState();
}

class _LeadsMultiSelectWidgetState extends State<LeadMultiSelectWidget> {
  final ApiService _apiService = ApiService();
  List<LeadData> leadsList = [];
  List<LeadData> selectedLeadsData = [];

  Set<int> _selectedLeadIds() {
    return (widget.selectedLeads ?? const <dynamic>[])
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toSet();
  }

  Future<List<LeadData>> _searchLeads(String query) async {
    final response = await _apiService.getAllLeadMulti(
      search: query,
    );
    final result = response.result ?? <LeadData>[];

    if (!mounted) {
      return result;
    }

    setState(() {
      leadsList = result;
      if (widget.selectedLeads != null && leadsList.isNotEmpty) {
        final selectedIds = _selectedLeadIds();
        final selectedBySearch =
            leadsList.where((lead) => selectedIds.contains(lead.id)).toList();

        for (final lead in selectedLeadsData) {
          if (!selectedBySearch.any((item) => item.id == lead.id)) {
            selectedBySearch.add(lead);
          }
        }

        selectedLeadsData = selectedBySearch;
      }
    });

    return result;
  }

  @override
  void initState() {
    super.initState();
    context.read<GetAllLeadMultiBloc>().add(GetAllLeadEv());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final dropdownBackground = widget.useSecondaryBackground
        ? colors.backgroundSecondary
        : colors.fieldBg;
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('lead'),
              style: textStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            BlocListener<GetAllLeadMultiBloc, GetAllLeadState>(
              listener: (context, state) {
                if (state is GetAllLeadSuccess) {
                  setState(() {
                    leadsList = state.dataLead.result ?? [];
                    if (widget.selectedLeads != null && leadsList.isNotEmpty) {
                      final selectedIds = _selectedLeadIds();
                      selectedLeadsData = leadsList
                          .where((lead) => selectedIds.contains(lead.id))
                          .toList();
                    }
                  });
                }
              },
              child: CustomDropdown<LeadData>.multiSelectSearchRequest(
                futureRequest: _searchLeads,
                futureRequestDelay: const Duration(milliseconds: 350),
                closeDropDownOnClearFilterSearch: true,
                items: leadsList,
                initialItems: selectedLeadsData,
                searchHintText:
                    AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 400,
                decoration: CustomDropdownDecoration(
                  closedFillColor: dropdownBackground,
                  expandedFillColor: dropdownBackground,
                  closedBorder: Border.all(
                    color: colors.fieldBorder,
                    width: 1,
                  ),
                  closedBorderRadius: BorderRadius.circular(12),
                  expandedBorder: Border.all(
                    color: colors.fieldBorder,
                    width: 1,
                  ),
                  expandedBorderRadius: BorderRadius.circular(12),
                  searchFieldDecoration: SearchFieldDecoration(
                    fillColor: colors.surfaceElevated,
                    textStyle:
                        textStyles.bodyMd.copyWith(color: colors.textPrimary),
                    hintStyle:
                        textStyles.bodyMd.copyWith(color: colors.textSecondary),
                    prefixIcon: Icon(Icons.search, color: colors.iconSecondary),
                    suffixIcon: (onClear) => IconButton(
                      onPressed: onClear,
                      icon: Icon(Icons.close_rounded,
                          color: colors.iconSecondary),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.fieldBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.buttonPrimaryBg),
                    ),
                  ),
                  listItemDecoration: ListItemDecoration(
                    selectedColor:
                        colors.buttonPrimaryBg.withValues(alpha: 0.14),
                    highlightColor:
                        colors.buttonPrimaryBg.withValues(alpha: 0.08),
                    splashColor: Colors.transparent,
                  ),
                ),
                listItemBuilder: (context, item, isSelected, onItemSelect) {
                  return ListTile(
                    minTileHeight: 1,
                    minVerticalPadding: 2,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Padding(
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: colors.buttonPrimaryBg, width: 1),
                              borderRadius: BorderRadius.circular(4),
                              color: isSelected
                                  ? colors.buttonPrimaryBg
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? Icon(Icons.check,
                                    color: colors.buttonPrimaryFg, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${item.name} ${item.lastname}',
                              style: textStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      onItemSelect();
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
                headerListBuilder: (context, hint, enabled) {
                  int selectedLeadsCount = selectedLeadsData.length;
                  return Text(
                    selectedLeadsCount == 0
                        ? AppLocalizations.of(context)!.translate('select_lead')
                        : '${AppLocalizations.of(context)!.translate('select_leads')} $selectedLeadsCount',
                    style: textStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_leads'),
                    style: textStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    )),
                onListChanged: (values) {
                  widget.onSelectLeads(values);
                  setState(() {
                    selectedLeadsData = values;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
