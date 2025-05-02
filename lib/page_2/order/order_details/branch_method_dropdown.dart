import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class BranchesDropdown extends StatefulWidget {
  final String label;
  final List<Branch> branches;
  final Branch? selectedBranch;
  final Function(Branch) onSelectBranch;

  const BranchesDropdown({
    Key? key,
    required this.label,
    required this.branches,
    this.selectedBranch,
    required this.onSelectBranch,
  }) : super(key: key);
  
  @override
  _BranchesDropdownState createState() => _BranchesDropdownState();
}

class _BranchesDropdownState extends State<BranchesDropdown> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          child: CustomDropdown<Branch>.search(
            closeDropDownOnClearFilterSearch: true,
            items: widget.branches,
            searchHintText: AppLocalizations.of(context)!.translate('search'),
            overlayHeight: 400,
            enabled: true,
            decoration: CustomDropdownDecoration(
              closedFillColor: Color(0xffF4F7FD),
              expandedFillColor: Colors.white,
              closedBorder: Border.all(
                color: Color(0xffF4F7FD),
                width: 1,
              ),
              closedBorderRadius: BorderRadius.circular(12),
              expandedBorder: Border.all(
                color: Color(0xffF4F7FD),
                width: 1,
              ),
              expandedBorderRadius: BorderRadius.circular(12),
              errorStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.red,
                height: 1.0, // Увеличивает высоту строки, создавая визуальный отступ сверху
              ),
            ),
            listItemBuilder: (context, item, isSelected, onItemSelect) {
              return Text(
                item.name,
                style: TextStyle(
                  color: Color(0xff1E2E52),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                ),
              );
            },
            headerBuilder: (context, selectedItem, enabled) {
              return Text(
                selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_branch'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              );
            },
            hintBuilder: (context, hint, enabled) => Text(
              AppLocalizations.of(context)!.translate('select_branch'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            excludeSelected: false,
            initialItem: widget.selectedBranch,
            validator: (value) {
              if (value == null) {
                return '    ${AppLocalizations.of(context)!.translate('field_required')}';
              }
              return null;
            },
            onChanged: (value) {
              if (value != null) {
                widget.onSelectBranch(value);
                FocusScope.of(context).unfocus();
              }
            },
          ),
        ),
      ],
    );
  }
}