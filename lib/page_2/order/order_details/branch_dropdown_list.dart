import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_state.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BranchRadioGroupWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(Branch) onSelectStatus;

  BranchRadioGroupWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
  }) : super(key: key);

  @override
  State<BranchRadioGroupWidget> createState() => _BranchRadioGroupWidgetState();
}

class _BranchRadioGroupWidgetState extends State<BranchRadioGroupWidget> {
  List<Branch> statusList = [];
  Branch? selectedStatusData;
  bool _hasInitialized = false;

  final TextStyle statusTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    debugPrint('BranchRadioGroupWidget initState - selectedStatus: ${widget.selectedStatus}');
    context.read<BranchBloc>().add(FetchBranches());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<BranchBloc, BranchState>(
          builder: (context, state) {
            if (state is BranchLoading) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('branches'),
                    style: statusTextStyle.copyWith(fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1,
                        color: const Color(0xFFF4F7FD),
                      ),
                    ),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                      ),
                    ),
                  ),
                ],
              );
            }
            if (state is BranchError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.translate(state.message),
                      style: statusTextStyle.copyWith(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
              return const SizedBox();
            }

            if (state is BranchLoaded) {
              // Print all branches with their details
              debugPrint('=== BranchRadioGroupWidget - BranchLoaded ===');
              debugPrint('Total branches: ${state.branches.length}');
              for (var branch in state.branches) {
                debugPrint('Branch: id=${branch.id}, name=${branch.name}, isActive=${branch.isActive}');
              }
              debugPrint('Looking for selectedStatus: ${widget.selectedStatus}');
              debugPrint('_hasInitialized: $_hasInitialized');
              debugPrint('Current selectedStatusData: ${selectedStatusData?.id} - ${selectedStatusData?.name}');

              // Filter branches with isActive = 1
              statusList = state.branches.where((branch) => branch.isActive == 1).toList();
              debugPrint('Active branches count: ${statusList.length}');

              // If no active branches available
              if (statusList.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('branches'),
                      style: statusTextStyle.copyWith(fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E7EB),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  AppLocalizations.of(context)!.translate('no_data'),
                                  style: statusTextStyle.copyWith(
                                    color: const Color(0xff9CA3AF),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 1,
                            color: const Color(0xFFF4F7FD),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.translate('select_branch'),
                              style: statusTextStyle.copyWith(
                                color: const Color(0xff9CA3AF),
                                fontSize: 14,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xff9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Initialize selected branch only once when data is first loaded
              if (!_hasInitialized) {
                debugPrint('Initializing branch selection...');
                _hasInitialized = true;

                if (widget.selectedStatus != null) {
                  debugPrint('Searching for branch with ID: ${widget.selectedStatus}');

                  // Try to find the branch by ID
                  try {
                    selectedStatusData = statusList.firstWhere(
                          (branch) {
                        debugPrint('Comparing: branch.id=${branch.id} with selectedStatus=${widget.selectedStatus}');
                        return branch.id.toString() == widget.selectedStatus;
                      },
                    );

                    debugPrint('✅ Found branch: ${selectedStatusData?.id} - ${selectedStatusData?.name}');

                    // Notify parent about the selected branch
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (selectedStatusData != null) {
                        debugPrint('Notifying parent with branch: ${selectedStatusData!.id}');
                        widget.onSelectStatus(selectedStatusData!);
                      }
                    });
                  } catch (e) {
                    // If branch not found, don't select anything
                    debugPrint('❌ Branch not found: $e');
                    selectedStatusData = null;
                  }
                } else if (statusList.length == 1) {
                  // If only one branch and nothing selected, auto-select it
                  debugPrint('Auto-selecting single branch: ${statusList[0].id} - ${statusList[0].name}');
                  selectedStatusData = statusList[0];

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.onSelectStatus(statusList[0]);
                  });
                } else {
                  debugPrint('No selectedStatus provided and multiple branches available');
                }
              }

              debugPrint('Final selectedStatusData for dropdown: ${selectedStatusData?.id} - ${selectedStatusData?.name}');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('branches'),
                    style: statusTextStyle.copyWith(fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1,
                        color: const Color(0xFFF4F7FD),
                      ),
                    ),
                    child: CustomDropdown<Branch>.search(
                      closeDropDownOnClearFilterSearch: true,
                      items: statusList,
                      searchHintText: AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
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
                          style: statusTextStyle,
                        );
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_branch'),
                          style: statusTextStyle,
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!.translate('select_branch'),
                        style: statusTextStyle.copyWith(fontSize: 14),
                      ),
                      excludeSelected: false,
                      initialItem: selectedStatusData,
                      onChanged: (value) {
                        if (value != null) {
                          debugPrint('User selected branch: ${value.id} - ${value.name}');
                          setState(() {
                            selectedStatusData = value;
                          });
                          widget.onSelectStatus(value);
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }
}