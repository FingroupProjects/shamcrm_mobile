import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_list_bloc.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_list_event.dart';
import 'package:crm_task_manager/bloc/deal_name_list_bloc/deal_name_lists_state.dart';
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

  final TextStyle dealNameTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

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
              style: dealNameTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError
                      ? Colors.red
                      : const Color(0xFFE5E7EB),
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
                      closedFillColor: const Color(0xffF4F7FD),
                      expandedFillColor: Colors.white,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
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
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: const Color(0xff1E2E52),
                                            width: 1),
                                        borderRadius: BorderRadius.circular(4),
                                        color: allSelected
                                            ? const Color(0xff1E2E52)
                                            : Colors.transparent,
                                      ),
                                      child: allSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('select_all'),
                                        style: dealNameTextStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              height: 20,
                              color: const Color(0xFFE5E7EB),
                            ),
                            _buildListItem(item, isSelected, onItemSelect),
                          ],
                        );
                      }
                      return _buildListItem(item, isSelected, onItemSelect);
                    },
                    headerListBuilder: (context, hint, enabled) {
                      String selectedDealNamesText =
                          selectedDealNamesData.isEmpty
                              ? AppLocalizations.of(context)!
                                  .translate('select_deal_name')
                              : selectedDealNamesData
                                  .map((e) => e.title)
                                  .join(', ');
                      return Text(
                        selectedDealNamesText,
                        style: dealNameTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_deal_name'),
                      style: dealNameTextStyle.copyWith(
                        fontSize: 14,
                      ),
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
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildListItem(
      DealNameData item, bool isSelected, Function() onItemSelect) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xff1E2E52),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: dealNameTextStyle,
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