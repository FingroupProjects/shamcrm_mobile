import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

class BranchesDropdown extends StatefulWidget {
  final String label;
  final List<Branch>? branches;
  final Branch? selectedBranch;
  final Function(Branch) onSelectBranch;

  const BranchesDropdown({
    Key? key,
    required this.label,
    this.branches,
    this.selectedBranch,
    required this.onSelectBranch,
  }) : super(key: key);

  @override
  _BranchesDropdownState createState() => _BranchesDropdownState();
}

class _BranchesDropdownState extends State<BranchesDropdown> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Фильтруем филиалы с isActive = 1
    final filteredBranches = widget.branches?.where((branch) => branch.isActive == 1).toList() ?? [];

    // Проверяем, что selectedBranch активен, иначе сбрасываем или выбираем первый активный
    Branch? effectiveSelectedBranch;
    if (widget.selectedBranch != null && filteredBranches.contains(widget.selectedBranch)) {
      effectiveSelectedBranch = widget.selectedBranch;
    } else if (filteredBranches.isNotEmpty) {
      effectiveSelectedBranch = filteredBranches[0]; // Выбираем первый активный филиал
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSelectBranch(filteredBranches[0]);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      
      children: [
        Text(
          widget.label,
          style:  TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        // Если список пуст, показываем сообщение
        filteredBranches.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.surfaceAccent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: 1,
                    color: colors.surfaceAccent,
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate('no_active_branches'),
                  style:  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                ),
              )
            : Container(
                child: CustomDropdown<Branch>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: filteredBranches,
                  searchHintText: AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: true,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: colors.fieldBg,
                      expandedFillColor: colors.surfacePrimary,
                      closedBorder: Border.all(
                        color: colors.fieldBg,
                        width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: colors.fieldBg,
                      width: 1,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                    errorStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: colors.error,
                      height: 1.0,
                    ),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    return Text(
                      selectedItem.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textPrimary,
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_branch'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                  ),
                  excludeSelected: false,
                  initialItem: effectiveSelectedBranch,
                  // validator: (value) {
                  //   if (value == null) {
                  //     return '    ${AppLocalizations.of(context)!.translate('field_required')}';
                  //   }
                  //   return null;
                  // },
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
