import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealStatusRadioGroupWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(DealStatus) onSelectStatus;

  DealStatusRadioGroupWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
  }) : super(key: key);

  @override
  State<DealStatusRadioGroupWidget> createState() =>
      _DealStatusRadioGroupWidgetState();
}

class _DealStatusRadioGroupWidgetState extends State<DealStatusRadioGroupWidget> {
  List<DealStatus> statusList = [];
  DealStatus? selectedStatusData;

  @override
  void initState() {
    super.initState();

    final currentState = context.read<DealBloc>().state;
    if (currentState is DealLoaded) {
      setState(() {
        statusList = currentState.dealStatuses;
      });
      _updateSelectedStatus();
    } else {
      context.read<DealBloc>().add(FetchDealStatuses());
    }
  }

  @override
  void didUpdateWidget(DealStatusRadioGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedStatus != widget.selectedStatus) {
      _updateSelectedStatus();
    }
  }

  void _updateSelectedStatus() {
    if (widget.selectedStatus != null && statusList.isNotEmpty) {
      try {
        final foundStatus = statusList.firstWhere(
          (status) => status.id.toString() == widget.selectedStatus,
        );
        setState(() {
          selectedStatusData = foundStatus;
        });
      } catch (e) {
        setState(() {
          selectedStatusData = null;
        });
      }
    } else {
      if (widget.selectedStatus == null && selectedStatusData != null) {
        setState(() {
          selectedStatusData = null;
        });
      } else if (statusList.length == 1 &&
          selectedStatusData == null &&
          widget.selectedStatus == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onSelectStatus(statusList[0]);
          setState(() {
            selectedStatusData = statusList[0];
          });
        });
      }
    }
  }

  CustomDropdownDecoration _dropdownDecoration(
    AppThemeColors colors,
    TextStyle textStyle,
    TextStyle hintStyle,
  ) {
    return CustomDropdownDecoration(
      closedFillColor: colors.fieldBg,
      expandedFillColor: colors.fieldBg,
      closedBorder: Border.all(color: Colors.transparent, width: 1),
      closedBorderRadius: BorderRadius.circular(12),
      expandedBorder: Border.all(color: colors.fieldBorder, width: 1),
      expandedBorderRadius: BorderRadius.circular(12),
      hintStyle: hintStyle,
      headerStyle: textStyle,
      listItemStyle: textStyle,
      noResultFoundStyle: hintStyle,
      listItemDecoration: ListItemDecoration(
        selectedColor: colors.buttonPrimaryBg.withValues(alpha: 0.14),
        highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
        splashColor: Colors.transparent,
      ),
      searchFieldDecoration: SearchFieldDecoration(
        fillColor: colors.surfaceElevated,
        textStyle: textStyle,
        hintStyle: hintStyle,
        prefixIcon: Icon(Icons.search, color: colors.iconSecondary),
        suffixIcon: (onClear) => IconButton(
          onPressed: onClear,
          icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
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
    );
  }

  Widget _buildLoading(AppThemeColors colors) {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(colors.buttonPrimaryBg),
        ),
      ),
    );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('deal_statuses'),
          style: textStyle.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 4),
        BlocListener<DealBloc, DealState>(
          listener: (context, state) {
            if (state is DealLoaded) {
              setState(() {
                statusList = state.dealStatuses;
              });
              _updateSelectedStatus();
            }

            if (state is DealError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.translate(state.message),
                      style: textStyle.copyWith(color: colors.buttonPrimaryFg),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: colors.fieldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: 1,
                color: colors.fieldBorder,
              ),
            ),
            child: CustomDropdown<DealStatus>.search(
              key: ValueKey(selectedStatusData?.id ?? 'no_selection'),
              closeDropDownOnClearFilterSearch: true,
              items: statusList,
              searchHintText: AppLocalizations.of(context)!.translate('search'),
              overlayHeight: 400,
              decoration: _dropdownDecoration(colors, textStyle, hintStyle),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return Text(
                  item.title,
                  style: textStyle,
                );
              },
              headerBuilder: (context, selectedItem, enabled) {
                if (statusList.isEmpty) {
                  return _buildLoading(colors);
                }
                return Text(
                  selectedItem.title,
                  style: textStyle,
                );
              },
              hintBuilder: (context, hint, enabled) {
                if (statusList.isEmpty) {
                  return _buildLoading(colors);
                }
                return Text(
                  AppLocalizations.of(context)!.translate('select_status'),
                  style: hintStyle,
                );
              },
              excludeSelected: false,
              initialItem: statusList.contains(selectedStatusData)
                  ? selectedStatusData
                  : null,
              onChanged: (value) {
                if (value != null) {
                  widget.onSelectStatus(value);
                  setState(() {
                    selectedStatusData = value;
                  });
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
