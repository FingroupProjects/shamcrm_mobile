import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_list_bloc.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_list_event.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_lists_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/models/deal_name_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealNamesMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedDealNames;
  final Function(List<DealNameData>) onSelectDealNames;

  DealNamesMultiSelectWidget({
    super.key,
    required this.onSelectDealNames,
    this.selectedDealNames,
  });

  @override
  State<DealNamesMultiSelectWidget> createState() =>
      _DealNamesMultiSelectWidgetState();
}

class _DealNamesMultiSelectWidgetState extends State<DealNamesMultiSelectWidget> {
  List<DealNameData> dealNameList = [];
  List<DealNameData> selectedDealNamesData = [];
  bool allSelected = false;

  @override
  void initState() {
    super.initState();
    context.read<GetAllDealNameBloc>().add(GetAllDealNameEv());
  }

  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      if (allSelected) {
        selectedDealNamesData = List.from(dealNameList);
      } else {
        selectedDealNamesData = [];
      }
      widget.onSelectDealNames(selectedDealNamesData);
    });
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

    return FormField<List<DealNameData>>(
      validator: (value) {
        if (selectedDealNamesData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<DealNameData>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('deal_name'),
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
                  color: field.hasError ? colors.error : colors.fieldBorder,
                ),
              ),
              child: BlocBuilder<GetAllDealNameBloc, GetAllDealNameState>(
                builder: (context, state) {
                  if (state is GetAllDealNameSuccess) {
                    dealNameList = state.dataDealName.result ?? [];
                    if (widget.selectedDealNames != null &&
                        dealNameList.isNotEmpty) {
                      selectedDealNamesData = dealNameList
                          .where((dealName) => widget.selectedDealNames!
                              .contains(dealName.title))
                          .toList();
                      allSelected =
                          selectedDealNamesData.length == dealNameList.length;
                    }
                  }

                  return CustomDropdown<DealNameData>.multiSelectSearch(
                    items: dealNameList,
                    initialItems: selectedDealNamesData,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: colors.fieldBg,
                      expandedFillColor: colors.fieldBg,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: colors.fieldBorder,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                      hintStyle: hintStyle,
                      headerStyle: textStyle,
                      listItemStyle: textStyle,
                      listItemDecoration: ListItemDecoration(
                        selectedColor:
                            colors.buttonPrimaryBg.withValues(alpha: 0.14),
                        highlightColor:
                            colors.buttonPrimaryBg.withValues(alpha: 0.08),
                        splashColor: Colors.transparent,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: colors.surfaceElevated,
                        textStyle: textStyle,
                        hintStyle: hintStyle,
                        prefixIcon:
                            Icon(Icons.search, color: colors.iconSecondary),
                        suffixIcon: (onClear) => IconButton(
                          onPressed: onClear,
                          icon: Icon(
                            Icons.close_rounded,
                            color: colors.iconSecondary,
                          ),
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
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      if (dealNameList.indexOf(item) == 0) {
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
                            Divider(
                              height: 20,
                              color: colors.borderSubtle,
                            ),
                            _buildListItem(
                                item, isSelected, onItemSelect, textStyle, colors),
                          ],
                        );
                      }
                      return _buildListItem(
                          item, isSelected, onItemSelect, textStyle, colors);
                    },
                    headerListBuilder: (context, hint, enabled) {
                      final selectedDealNamesText =
                          selectedDealNamesData.isEmpty
                              ? AppLocalizations.of(context)!
                                  .translate('select_deal_name')
                              : selectedDealNamesData
                                  .map((e) => e.title)
                                  .join(', ');
                      return Text(
                        selectedDealNamesText,
                        style: selectedDealNamesData.isEmpty
                            ? hintStyle
                            : textStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!
                          .translate('select_deal_name'),
                      style: hintStyle,
                    ),
                    onListChanged: (values) {
                      widget.onSelectDealNames(values);
                      setState(() {
                        selectedDealNamesData = values;
                        allSelected = values.length == dealNameList.length;
                      });
                      field.didChange(values);
                    },
                  );
                },
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Text(
                  field.errorText!,
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCheckbox(bool isChecked, AppThemeColors colors) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(
          color: colors.textPrimary,
          width: 1,
        ),
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
    DealNameData item,
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
