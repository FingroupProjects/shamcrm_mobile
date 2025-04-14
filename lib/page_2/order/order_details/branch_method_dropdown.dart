import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_state.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void initState() {
    super.initState();
    selectedBranch = widget.selectedBranch;
    // Запрашиваем филиалы
    context.read<BranchBloc>().add(FetchBranches());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BranchBloc, BranchState>(
      builder: (context, state) {
        List<Branch> branches = [];
        bool isLoading = false;
        String? errorMessage;

        if (state is BranchLoading) {
          isLoading = true;
        } else if (state is BranchLoaded) {
          branches = state.branches;
          // Проверяем, содержится ли selectedBranch в новом списке
          if (selectedBranch != null && !branches.any((b) => b.id == selectedBranch!.id)) {
            selectedBranch = null;
          }
        } else if (state is BranchError) {
          errorMessage = state.message;
        }

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
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      )
                    : CustomDropdown<Branch>.search(
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
      },
    );
  }
}