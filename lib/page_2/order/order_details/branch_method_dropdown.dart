import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

// Класс для представления филиала
class Branch {
  final String name;
  final String address;

  Branch({required this.name, required this.address});

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Branch &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          address == other.address;

  @override
  int get hashCode => name.hashCode ^ address.hashCode;
}

class BranchesDropdown extends StatefulWidget {
  final Branch? selectedBranch;
  final Function(Branch) onSelectBranch;

  const BranchesDropdown({
    super.key,
    required this.onSelectBranch,
    this.selectedBranch,
  });

  @override
  State<BranchesDropdown> createState() => _BranchesDropdownState();
}

class _BranchesDropdownState extends State<BranchesDropdown> {
  Branch? selectedBranch;
  final List<Branch> branches = [
    Branch(name: 'Центральный офис', address: 'ул. Ленина, 10, Москва'),
    Branch(name: 'Северный филиал', address: 'пр. Мира, 25, Санкт-Петербург'),
    Branch(name: 'Южный филиал', address: 'ул. Солнечная, 5, Ростов-на-Дону'),
  ];

  @override
  void initState() {
    super.initState();
    // Проверяем, содержится ли widget.selectedBranch в списке branches
    if (widget.selectedBranch != null && branches.contains(widget.selectedBranch)) {
      selectedBranch = widget.selectedBranch;
    } else {
      selectedBranch = null; // Сбрасываем, если не найден
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('branches'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<Branch>.search(
          closeDropDownOnClearFilterSearch: true,
          items: branches,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 400,
          enabled: true,
          decoration: CustomDropdownDecoration(
            closedFillColor: const Color(0xffF4F7FD),
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
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                ),
                Text(
                  item.address,
                  style: const TextStyle(
                    color: Color(0xff6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            return Text(
              selectedItem.name.isNotEmpty
                  ? selectedItem.name
                  : AppLocalizations.of(context)!.translate('select_branch'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_branch'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          excludeSelected: false,
          initialItem: selectedBranch,
          onChanged: (value) {
            if (value != null) {
              widget.onSelectBranch(value);
              setState(() {
                selectedBranch = value;
              });
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }
}