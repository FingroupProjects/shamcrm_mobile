import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_bloc.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_event.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/models/LeadStatusForFilter.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealLeadStatusMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedLeadStatuses;
  final Function(List<LeadStatusForFilter>) onSelectStatuses;

  const DealLeadStatusMultiSelectWidget({
    super.key,
    required this.onSelectStatuses,
    this.selectedLeadStatuses,
  });

  @override
  State<DealLeadStatusMultiSelectWidget> createState() =>
      _DealLeadStatusMultiSelectWidgetState();
}

class _DealLeadStatusMultiSelectWidgetState
    extends State<DealLeadStatusMultiSelectWidget> {
  List<LeadStatusForFilter> statusList = [];
  List<LeadStatusForFilter> selectedStatusesData = [];
  bool allSelected = false;

  @override
  void initState() {
    super.initState();
    context.read<LeadStatusForFilterBloc>().add(FetchLeadStatusForFilter());
  }

  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      selectedStatusesData = allSelected ? List.from(statusList) : [];
      widget.onSelectStatuses(selectedStatusesData);
    });
  }

  CustomDropdownDecoration _dropdownDecoration(
    AppThemeColors colors,
    TextStyle textStyle,
    TextStyle hintStyle,
  ) {
    return CustomDropdownDecoration(
      closedFillColor: colors.fieldBg,
      expandedFillColor: colors.fieldBg,
      closedBorder: Border.all(color: Colors.transparent, width: 1),
      closedBorderRadius: BorderRadius.circular(12),
      expandedBorder: Border.all(color: colors.fieldBorder, width: 1),
      expandedBorderRadius: BorderRadius.circular(12),
      hintStyle: hintStyle,
      headerStyle: textStyle,
      listItemStyle: textStyle,
      noResultFoundStyle: hintStyle,
      listItemDecoration: ListItemDecoration(
        selectedColor: colors.buttonPrimaryBg.withValues(alpha: 0.14),
        highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
        splashColor: Colors.transparent,
      ),
      searchFieldDecoration: SearchFieldDecoration(
        fillColor: colors.surfaceElevated,
        textStyle: textStyle,
        hintStyle: hintStyle,
        prefixIcon: Icon(Icons.search, color: colors.iconSecondary),
        suffixIcon: (onClear) => IconButton(
          onPressed: onClear,
          icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: colors.textPrimary,
    );
    final hintStyle = textStyle.copyWith(
      fontSize: 14,
      color: colors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('lead_statuses'),
          style: textStyle.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: colors.fieldBorder,
            ),
          ),
          child: BlocBuilder<LeadStatusForFilterBloc, LeadStatusForFilterState>(
            builder: (context, state) {
              if (state is LeadStatusForFilterLoaded) {
                statusList = state.leadStatusForFilter;
                if (widget.selectedLeadStatuses != null &&
                    statusList.isNotEmpty) {
                  selectedStatusesData = statusList
                      .where(
                        (status) => widget.selectedLeadStatuses!
                            .contains(status.id.toString()),
                      )
                      .toList();
                  allSelected =
                      selectedStatusesData.length == statusList.length;
                }
              }

              return CustomDropdown<LeadStatusForFilter>.multiSelectSearch(
                items: statusList,
                initialItems: selectedStatusesData,
                searchHintText:
                    AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 400,
                decoration: _dropdownDecoration(colors, textStyle, hintStyle),
                listItemBuilder: (context, item, isSelected, onItemSelect) {
                  if (statusList.indexOf(item) == 0) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: GestureDetector(
                            onTap: _toggleSelectAll,
                            child: Row(
                              children: [
                                _buildCheckbox(allSelected, colors),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .translate('select_all'),
                                    style: textStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 20, color: colors.borderSubtle),
                        _buildListItem(
                          item,
                          isSelected,
                          onItemSelect,
                          textStyle,
                          colors,
                        ),
                      ],
                    );
                  }
                  return _buildListItem(
                    item,
                    isSelected,
                    onItemSelect,
                    textStyle,
                    colors,
                  );
                },
                headerListBuilder: (context, hint, enabled) {
                  final selectedStatusesNames = selectedStatusesData.isEmpty
                      ? AppLocalizations.of(context)!.translate('select_status')
                      : selectedStatusesData.map((e) => e.title).join(', ');
                  return Text(
                    selectedStatusesNames,
                    style: selectedStatusesData.isEmpty ? hintStyle : textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                  AppLocalizations.of(context)!.translate('select_status'),
                  style: hintStyle,
                ),
                onListChanged: (values) {
                  widget.onSelectStatuses(values);
                  setState(() {
                    selectedStatusesData = values;
                    allSelected = values.length == statusList.length;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox(bool isChecked, AppThemeColors colors) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(color: colors.textPrimary, width: 1),
        borderRadius: BorderRadius.circular(4),
        color: isChecked ? colors.buttonPrimaryBg : Colors.transparent,
      ),
      child: isChecked
          ? Icon(
              Icons.check,
              color: colors.buttonPrimaryFg,
              size: 14,
            )
          : null,
    );
  }

  Widget _buildListItem(
    LeadStatusForFilter item,
    bool isSelected,
    Function() onItemSelect,
    TextStyle textStyle,
    AppThemeColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
          children: [
            _buildCheckbox(isSelected, colors),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
