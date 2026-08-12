import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/lead/manager_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EventManagerMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedManagers;
  final Function(List<ManagerData>) onSelectManagers;

  const EventManagerMultiSelectWidget({
    super.key,
    required this.onSelectManagers,
    this.selectedManagers,
  });

  @override
  State<EventManagerMultiSelectWidget> createState() =>
      _EventManagersMultiSelectWidgetState();
}

class _EventManagersMultiSelectWidgetState
    extends State<EventManagerMultiSelectWidget> {
  List<ManagerData> managersList = [];
  List<ManagerData> selectedManagersData = [];

  // @override
  // void initState() {
  //   super.initState();
  //   context.read<GetAllManagerBloc>().add(GetAllManagerEv());
  // }

  @override
  Widget build(BuildContext context) {
    final managerTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    final hintStyle = managerTextStyle.copyWith(
      color: context.appColors.textSecondary,
    );
    final borderColor = context.appColors.borderSubtle.withValues(alpha: 0.7);

    return Column(
      children: [
        BlocBuilder<GetAllManagerBloc, GetAllManagerState>(
          builder: (context, state) {
            if (state is GetAllManagerLoading) {
              // return Center(child: CircularProgressIndicator());
            }
            if (state is GetAllManagerError) {
              return Text(state.message);
            }
            if (state is GetAllManagerSuccess) {
              managersList = state.dataManager.result ?? [];
              if (widget.selectedManagers != null && managersList.isNotEmpty) {
                selectedManagersData = managersList
                    .where((manager) => widget.selectedManagers!
                        .contains(manager.id.toString()))
                    .toList();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('managers'),
                    style: managerTextStyle,
                  ),
                  const SizedBox(height: 4),
                  CustomDropdown<ManagerData>.multiSelectSearch(
                    items: managersList,
                    initialItems: selectedManagersData,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: context.appColors.fieldBg,
                      expandedFillColor: context.appColors.surfacePrimary,
                      closedBorder: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                      hintStyle: hintStyle,
                      headerStyle: managerTextStyle,
                      listItemStyle: managerTextStyle,
                      listItemDecoration: ListItemDecoration(
                        selectedColor: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.14),
                        highlightColor: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.08),
                        splashColor: Colors.transparent,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: context.appColors.fieldBg,
                        textStyle: managerTextStyle,
                        hintStyle: hintStyle,
                        prefixIcon: Icon(
                          Icons.search,
                          color: context.appColors.textMuted,
                        ),
                        suffixIcon: (onClear) => IconButton(
                          onPressed: onClear,
                          icon: Icon(
                            Icons.close,
                            color: context.appColors.textMuted,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.appColors.buttonPrimaryBg,
                          ),
                        ),
                      ),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      return ListTile(
                        minTileHeight: 1,
                        minVerticalPadding: 2,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Padding(
                          padding: EdgeInsets.zero,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: context.appColors.borderPrimary,
                                    width: 1,
                                  ),
                                  color: isSelected
                                      ? context.appColors.buttonPrimaryBg
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: context.appColors.textInverse,
                                        size: 16,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${item.name} ${item.lastname}',
                                style: managerTextStyle,
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          onItemSelect();
                          FocusScope.of(context).unfocus();
                        },
                      );
                    },
                    headerListBuilder: (context, hint, enabled) {
                      int selectedManagersCount = selectedManagersData.length;

                      return Text(
                        selectedManagersCount == 0
                            ? AppLocalizations.of(context)!
                                .translate('select_manager')
                            : '${AppLocalizations.of(context)!.translate('select_manager')} $selectedManagersCount',
                        style: managerTextStyle,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!
                            .translate('select_manager'),
                        style: hintStyle),
                    onListChanged: (values) {
                      widget.onSelectManagers(values);
                      setState(() {
                        selectedManagersData = values;
                      });
                    },
                  ),
                ],
              );
            }
            return SizedBox();
          },
        ),
      ],
    );
  }
}
