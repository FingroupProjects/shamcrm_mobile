import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/lead/manager_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManagerMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedManagers;
  final Function(List<ManagerData>) onSelectManagers;

  const ManagerMultiSelectWidget({
    super.key,
    required this.onSelectManagers,
    this.selectedManagers,
  });

  @override
  State<ManagerMultiSelectWidget> createState() =>
      _ManagersMultiSelectWidgetState();
}

class _ManagersMultiSelectWidgetState extends State<ManagerMultiSelectWidget> {
  List<ManagerData> managersList = [];
  List<ManagerData> selectedManagersData = [];
  bool allSelected = false; // Added: Flag for "Select All" functionality
  final ManagerData systemManager = ManagerData(
    id: 0,
    name: "Система",
    lastname: "",
  );

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(
        GetAllManagerEv()); // Simplified: Removed redundant _loadManagers check
  }

  // Added: Function to toggle select all managers
  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      if (allSelected) {
        selectedManagersData = List.from(managersList); // Select all
      } else {
        selectedManagersData = []; // Deselect all
      }
      widget.onSelectManagers(selectedManagersData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final managerTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    final hintStyle = managerTextStyle.copyWith(
      fontSize: 14,
      color: context.appColors.textSecondary,
    );
    final borderColor = context.appColors.borderSubtle;
    return FormField<List<ManagerData>>(
      // Changed: Wrapped in FormField for validation
      validator: (value) {
        if (selectedManagersData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<ManagerData>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('managers'),
              style: managerTextStyle.copyWith(
                // Changed: Use managerTextStyle with lighter weight
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(
                height:
                    8), // Changed: Increased spacing to match AuthorMultiSelectWidget
            Container(
              decoration: BoxDecoration(
                // Added: Border styling with error handling
                color: context.appColors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError
                      ? context.appColors.error
                      : context.appColors.borderSubtle,
                ),
              ),
              child: BlocBuilder<GetAllManagerBloc, GetAllManagerState>(
                builder: (context, state) {
                  if (state is GetAllManagerSuccess) {
                    managersList = [
                      systemManager,
                      ...state.dataManager.result ?? [],
                    ];
                    if (widget.selectedManagers != null &&
                        managersList.isNotEmpty) {
                      selectedManagersData = managersList
                          .where((manager) => widget.selectedManagers!
                              .contains(manager.id.toString()))
                          .toList();
                      allSelected = selectedManagersData.length ==
                          managersList
                              .length; // Added: Update allSelected state
                    }
                  }

                  return CustomDropdown<ManagerData>.multiSelectSearch(
                    items: managersList,
                    initialItems: selectedManagersData,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      // Changed: Unified decoration to match AuthorMultiSelectWidget
                      closedFillColor: context.appColors.fieldBg,
                      expandedFillColor: context.appColors.surfacePrimary,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: context.appColors.borderSubtle,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                      hintStyle: hintStyle,
                      headerStyle: managerTextStyle,
                      listItemStyle: managerTextStyle,
                      listItemDecoration: ListItemDecoration(
                        selectedColor:
                            context.appColors.buttonPrimaryBg.withValues(alpha: 0.14),
                        highlightColor:
                            context.appColors.buttonPrimaryBg.withValues(alpha: 0.08),
                        splashColor: Colors.transparent,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: context.appColors.backgroundPrimary,
                        textStyle: managerTextStyle,
                        hintStyle: hintStyle,
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
                      // Added: "Select All" option as first item
                      if (managersList.indexOf(item) == 0) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: GestureDetector(
                                onTap: _toggleSelectAll,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color:
                                                context.appColors.textPrimary,
                                            width: 1),
                                        borderRadius: BorderRadius.circular(4),
                                        color: allSelected
                                            ? context.appColors.buttonPrimaryBg
                                            : Colors.transparent,
                                      ),
                                      child: allSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('select_all'),
                                        style: managerTextStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                                height: 20,
                                color: context.appColors
                                    .borderSubtle), // Added: Divider for "Select All"
                            _buildListItem(item, isSelected, onItemSelect),
                          ],
                        );
                      }
                      return _buildListItem(item, isSelected,
                          onItemSelect); // Changed: Use custom _buildListItem
                    },
                    headerListBuilder: (context, hint, enabled) {
                      String selectedManagersNames =
                          selectedManagersData.isEmpty
                              ? AppLocalizations.of(context)!
                                  .translate('select_manager')
                              : selectedManagersData
                                  .map((e) => e.id == 0
                                      ? e.name
                                      : '${e.name} ${e.lastname}')
                                  .join(', ');
                      return Text(
                        selectedManagersNames,
                        style:
                            managerTextStyle, // Changed: Use managerTextStyle
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_manager'),
                      style: hintStyle,
                    ),
                    onListChanged: (values) {
                      widget.onSelectManagers(values);
                      setState(() {
                        selectedManagersData = values;
                        allSelected = values.length ==
                            managersList.length; // Added: Update allSelected
                      });
                      field.didChange(values); // Added: Update FormField state
                    },
                  );
                },
              ),
            ),
            if (field.hasError) // Added: Error text display
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Text(
                  field.errorText!,
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Added: Custom list item builder to match AuthorMultiSelectWidget
  Widget _buildListItem(
      ManagerData item, bool isSelected, Function() onItemSelect) {
    final managerTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.appColors.textPrimary,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected
                    ? context.appColors.buttonPrimaryBg
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.id == 0 ? item.name : '${item.name} ${item.lastname}',
                style: managerTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
