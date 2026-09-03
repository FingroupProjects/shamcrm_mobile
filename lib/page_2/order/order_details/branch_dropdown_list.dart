import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_state.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

class BranchRadioGroupWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(Branch) onSelectStatus;

  const BranchRadioGroupWidget({
    super.key,
    required this.onSelectStatus,
    this.selectedStatus,
  });

  @override
  State<BranchRadioGroupWidget> createState() => _BranchRadioGroupWidgetState();
}

class _BranchRadioGroupWidgetState extends State<BranchRadioGroupWidget> {
  final ApiService _apiService = ApiService();
  List<Branch> statusList = [];
  Branch? selectedStatusData;
  bool _hasInitialized = false;

  final TextStyle statusTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    // color: colors.textPrimary,
  );

  @override
  void initState() {
    super.initState();
    debugPrint(
        'BranchRadioGroupWidget initState - selectedStatus: ${widget.selectedStatus}');
    context.read<BranchBloc>().add(FetchBranches());
  }

  @override
  void didUpdateWidget(BranchRadioGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedStatus != oldWidget.selectedStatus &&
        widget.selectedStatus != null &&
        statusList.isNotEmpty) {
      try {
        final match = statusList.firstWhere(
          (branch) => branch.id.toString() == widget.selectedStatus,
        );
        if (selectedStatusData?.id != match.id) {
          setState(() {
            selectedStatusData = match;
          });
        }
      } catch (_) {}
    }
  }

  Future<List<Branch>> _searchBranches(String query) async {
    final branches = await _apiService.getBranches(search: query);
    return branches.where((branch) => branch.isActive == 1).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
                      style:
                          statusTextStyle.copyWith(fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.fieldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 1,
                          color: colors.fieldBorder,
                        ),
                      ),
                    child:  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.textPrimary),
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
                      style: statusTextStyle.copyWith(color: colors.textInverse),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: colors.error,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
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
                debugPrint(
                    'Branch: id=${branch.id}, name=${branch.name}, isActive=${branch.isActive}');
              }
              debugPrint(
                  'Looking for selectedStatus: ${widget.selectedStatus}');
              debugPrint('_hasInitialized: $_hasInitialized');
              debugPrint(
                  'Current selectedStatusData: ${selectedStatusData?.id} - ${selectedStatusData?.name}');

              // Filter branches with isActive = 1
              statusList = state.branches
                  .where((branch) => branch.isActive == 1)
                  .toList();
              debugPrint('Active branches count: ${statusList.length}');

              // If no active branches available
              if (statusList.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('branches'),
                      style:
                          statusTextStyle.copyWith(fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            decoration:  BoxDecoration(
                              color: colors.surfacePrimary,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colors.borderSubtle,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  AppLocalizations.of(context)!
                                      .translate('no_data'),
                                  style: statusTextStyle.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: colors.fieldBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 1,
                            color: colors.fieldBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .translate('select_branch'),
                              style: statusTextStyle.copyWith(
                                color: colors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (!_hasInitialized ||
                  (selectedStatusData == null && statusList.length == 1)) {
                _hasInitialized = true;

                if (widget.selectedStatus != null) {
                  try {
                    selectedStatusData = statusList.firstWhere(
                      (branch) =>
                          branch.id.toString() == widget.selectedStatus,
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (selectedStatusData != null) {
                        widget.onSelectStatus(selectedStatusData!);
                      }
                    });
                  } catch (e) {
                    selectedStatusData = null;
                  }
                }

                if (selectedStatusData == null && statusList.length == 1) {
                  selectedStatusData = statusList[0];
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      widget.onSelectStatus(statusList[0]);
                    }
                  });
                }
              }

              debugPrint(
                  'Final selectedStatusData for dropdown: ${selectedStatusData?.id} - ${selectedStatusData?.name}');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('branches'),
                    style:
                        statusTextStyle.copyWith(fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 4),
                  CustomDropdown<Branch>.searchRequest(
                      key: ValueKey(
                          'branch_${selectedStatusData?.id ?? 'none'}'),
                      futureRequest: _searchBranches,
                      futureRequestDelay: const Duration(milliseconds: 350),
                      closeDropDownOnClearFilterSearch: true,
                      items: statusList,
                      searchHintText:
                          AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: colors.fieldBg,
                        expandedFillColor: colors.surfacePrimary,
                        closedBorder: Border.all(
                          color: colors.fieldBorder,
                          width: 1,
                        ),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(
                          color: colors.fieldBorder,
                          width: 1,
                        ),
                        expandedBorderRadius: BorderRadius.circular(12),
                      ),
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        return Text(
                          item.name,
                          style: statusTextStyle,
                        );
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem.name,
                          style: statusTextStyle,
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!
                            .translate('select_branch'),
                        style: statusTextStyle.copyWith(fontSize: 14),
                      ),
                      excludeSelected: false,
                      initialItem: selectedStatusData,
                      onChanged: (value) {
                        if (value != null) {
                          debugPrint(
                              'User selected branch: ${value.id} - ${value.name}');
                          setState(() {
                            selectedStatusData = value;
                          });
                          widget.onSelectStatus(value);
                          FocusScope.of(context).unfocus();
                        }
                      },
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
