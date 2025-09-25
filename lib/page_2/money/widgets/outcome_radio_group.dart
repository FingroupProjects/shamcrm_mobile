import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/outcome_category_list/outcome_category_list_bloc.dart';
import 'package:crm_task_manager/bloc/outcome_category_list/outcome_category_list_event.dart';
import 'package:crm_task_manager/bloc/outcome_category_list/outcome_category_list_state.dart';
import 'package:crm_task_manager/models/outcome_category_data.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OutcomeRadioGroupWidget extends StatefulWidget {
  final int? selectedOutcomeCategoryId;
  final Function(OutcomeCategoryData) onSelectOutcomeCategory;
  final String? title;

  const OutcomeRadioGroupWidget({
    super.key,
    required this.onSelectOutcomeCategory,
    this.selectedOutcomeCategoryId,
    this.title,
  });

  @override
  State<OutcomeRadioGroupWidget> createState() => _OutcomeRadioGroupWidgetState();
}

class _OutcomeRadioGroupWidgetState extends State<OutcomeRadioGroupWidget> {
  List<OutcomeCategoryData> outcomeCategoriesList = [];
  OutcomeCategoryData? selectedOutcomeCategoryData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<GetAllOutcomeCategoryBloc>().state;
        if (state is GetAllOutcomeCategorySuccess) {
          outcomeCategoriesList = state.dataOutcomeCategories.result ?? [];
          _updateSelectedOutcomeCategoryData();
        }
        if (state is! GetAllOutcomeCategorySuccess) {
          context.read<GetAllOutcomeCategoryBloc>().add(GetAllOutcomeCategoryEv());
        }
      }
    });
  }

  void _updateSelectedOutcomeCategoryData() {
    if (widget.selectedOutcomeCategoryId != null && outcomeCategoriesList.isNotEmpty) {
      try {
        selectedOutcomeCategoryData = outcomeCategoriesList.firstWhere(
              (category) => category.id.toString() == widget.selectedOutcomeCategoryId.toString(),
        );
        // Убираем автоматический вызов callback - это вызывает setState during build
        // if (selectedOutcomeCategoryData?.id != null) {
        //   widget.onSelectOutcomeCategory(selectedOutcomeCategoryData!);
        // }
      } catch (e) {
        // selectedOutcomeCategoryData = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title ?? AppLocalizations.of(context)!.translate('outcome_category'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        BlocBuilder<GetAllOutcomeCategoryBloc, GetAllOutcomeCategoryState>(
          builder: (context, state) {
            if (state is GetAllOutcomeCategorySuccess) {
              outcomeCategoriesList = state.dataOutcomeCategories.result ?? [];
              _updateSelectedOutcomeCategoryData();
            }

            return CustomDropdown<OutcomeCategoryData>.search(
          closeDropDownOnClearFilterSearch: true,
          items: outcomeCategoriesList,
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
            if (state is GetAllOutcomeCategoryLoading) {
              return Text(
                AppLocalizations.of(context)!.translate('select_outcome_category'),
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
            AppLocalizations.of(context)!.translate('select_outcome_category'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          excludeSelected: false,
          initialItem: outcomeCategoriesList.contains(selectedOutcomeCategoryData)
              ? selectedOutcomeCategoryData
              : null,
          validator: (value) {
            if (value == null) {
              return AppLocalizations.of(context)!.translate('field_required_project');
            }
            return null;
          },
          onChanged: (value) {
            if (value != null) {
              widget.onSelectOutcomeCategory(value);
              setState(() {
                selectedOutcomeCategoryData = value;
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
