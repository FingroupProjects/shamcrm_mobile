import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/income_category_list/income_category_list_bloc.dart';
import 'package:crm_task_manager/bloc/income_category_list/income_category_list_event.dart';
import 'package:crm_task_manager/bloc/income_category_list/income_category_list_state.dart';
import 'package:crm_task_manager/models/income_category_data.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IncomeRadioGroupWidget extends StatefulWidget {
  final int? selectedIncomeCategoryId;
  final Function(IncomeCategoryData) onSelectIncomeCategory;
  final String? title;

  const IncomeRadioGroupWidget({
    super.key,
    required this.onSelectIncomeCategory,
    this.selectedIncomeCategoryId,
    this.title,
  });

  @override
  State<IncomeRadioGroupWidget> createState() => _IncomeRadioGroupWidgetState();
}

class _IncomeRadioGroupWidgetState extends State<IncomeRadioGroupWidget> {
  List<IncomeCategoryData> incomeCategoriesList = [];
  IncomeCategoryData? selectedIncomeCategoryData;
  String? _autoSelectedIncomeCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<GetAllIncomeCategoryBloc>().state;
        if (state is GetAllIncomeCategorySuccess) {
          incomeCategoriesList = state.dataIncomeCategories.result ?? [];
          _updateSelectedIncomeCategoryData();
        }
        if (state is! GetAllIncomeCategorySuccess) {
          context.read<GetAllIncomeCategoryBloc>().add(GetAllIncomeCategoryEv());
        }
      }
    });
  }

  void _updateSelectedIncomeCategoryData() {
    if (widget.selectedIncomeCategoryId != null && incomeCategoriesList.isNotEmpty) {
      try {
        selectedIncomeCategoryData = incomeCategoriesList.firstWhere(
              (category) => category.id.toString() == widget.selectedIncomeCategoryId.toString(),
        );
        // Убираем автоматический вызов callback - это вызывает setState during build
        // if (selectedIncomeCategoryData?.id != null) {
        //   widget.onSelectIncomeCategory(selectedIncomeCategoryData!);
        // }
      } catch (e) {
        // selectedIncomeCategoryData = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title ?? AppLocalizations.of(context)!.translate('income_category'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllIncomeCategoryBloc, GetAllIncomeCategoryState>(
          builder: (context, state) {
            if (state is GetAllIncomeCategorySuccess) {
              incomeCategoriesList = state.dataIncomeCategories.result ?? [];
              _updateSelectedIncomeCategoryData();

              if (incomeCategoriesList.length == 1 &&
                  (widget.selectedIncomeCategoryId == null ||
                      selectedIncomeCategoryData == null) &&
                  _autoSelectedIncomeCategoryId != incomeCategoriesList.first.id.toString()) {
                final singleCategory = incomeCategoriesList.first;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  widget.onSelectIncomeCategory(singleCategory);
                  setState(() {
                    selectedIncomeCategoryData = singleCategory;
                    _autoSelectedIncomeCategoryId = singleCategory.id.toString();
                  });
                });
              }
            }

            return CustomDropdown<IncomeCategoryData>.search(
          closeDropDownOnClearFilterSearch: true,
          items: incomeCategoriesList,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 400,
          enabled: true,
          decoration: CustomDropdownDecoration(
            closedFillColor: const Color(0xffF4F7FD),
            expandedFillColor: Colors.white,
            closedBorder: Border.all(
              color: const Color(0xffF4F7FD),
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: const Color(0xffF4F7FD),
              width: 1,
            ),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item.name,
              style: const TextStyle(
                color: Color(0xff1E2E52),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            if (state is GetAllIncomeCategoryLoading) {
              return Text(
                AppLocalizations.of(context)!.translate('select_income_category'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              );
            }
            return Text(
              selectedItem.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_income_category'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          excludeSelected: false,
          initialItem: incomeCategoriesList.contains(selectedIncomeCategoryData)
              ? selectedIncomeCategoryData
              : null,
          validator: (value) {
            if (value == null) {
              return AppLocalizations.of(context)!.translate('field_required_project');
            }
            return null;
          },
          onChanged: (value) {
            if (value != null) {
              widget.onSelectIncomeCategory(value);
              setState(() {
                selectedIncomeCategoryData = value;
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
