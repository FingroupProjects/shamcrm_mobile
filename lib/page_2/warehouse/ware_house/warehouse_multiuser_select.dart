import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WarehouseMultiUser extends StatefulWidget {
  final List<String>? selectedUsers;
  final Function(List<UserData>) onSelectUsers;

  WarehouseMultiUser({
    super.key,
    required this.onSelectUsers,
    this.selectedUsers,
  });

  @override
  State<WarehouseMultiUser> createState() => _WarehouseMultiUserState();
}

class _WarehouseMultiUserState extends State<WarehouseMultiUser> {
  List<UserData> usersList = [];
  List<UserData> selectedUsersData = [];
  bool allSelected = false;

  final TextStyle userTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  // Sentinel for "Select All" - a dummy UserData
  static final UserData selectAllSentinel = UserData(
    id: -1,
    name: 'SELECT_ALL',
    lastname: '',
  );

  @override
  void initState() {
    super.initState();
    context.read<GetAllClientBloc>().add(GetAllClientEv());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-selection can be updated here if needed, but we'll handle it after fetch
  }

  // Function to toggle select all
  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      if (allSelected) {
        selectedUsersData =
            List.from(usersList.where((user) => user != selectAllSentinel));
      } else {
        selectedUsersData = [];
      }
      widget.onSelectUsers(selectedUsersData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<UserData>>(
      validator: (value) {
        if (selectedUsersData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<UserData>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('assignees_list'),
              style: userTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? Colors.red : const Color(0xFFE5E7EB),
                ),
              ),
              child: BlocBuilder<GetAllClientBloc, GetAllClientState>(
                builder: (context, state) {
                  if (state is GetAllClientLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is GetAllClientError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (state is GetAllClientSuccess) {
                    final fetchedUsers = state.dataUser.result ?? [];
                    if (usersList.isEmpty ||
                        fetchedUsers.length != usersList.length - 1) {
                      usersList = [selectAllSentinel, ...fetchedUsers];
                      // Apply pre-selection only on first load or data change
                      if (widget.selectedUsers != null) {
                        selectedUsersData = fetchedUsers
                            .where((user) => widget.selectedUsers!
                                .contains(user.id.toString()))
                            .toList();
                        allSelected =
                            selectedUsersData.length == fetchedUsers.length;
                      }
                    }
                    return CustomDropdown<UserData>.multiSelectSearch(
                      items: usersList,
                      initialItems: selectedUsersData,
                      searchHintText:
                          AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: MediaQuery.of(context).size.height *
                          0.5, // Dynamic height
                      decoration: CustomDropdownDecoration(
                        closedFillColor: const Color(0xffF4F7FD),
                        expandedFillColor: Colors.white,
                        closedBorder: Border.all(
                          color: Colors.transparent,
                          width: 1,
                        ),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        expandedBorderRadius: BorderRadius.circular(12),
                      ),
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        if (item == selectAllSentinel) {
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
                                              color: const Color(0xff1E2E52),
                                              width: 1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          color: allSelected
                                              ? const Color(0xff1E2E52)
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
                                          style: userTextStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 20,
                                color: Color(0xFFE5E7EB),
                              ), // Divider
                            ],
                          );
                        }
                        // Regular items
                        return _buildListItem(item, isSelected, onItemSelect);
                      },
                      headerListBuilder: (context, hint, enabled) {
                        String selectedUsersNames = selectedUsersData.isEmpty
                            ? AppLocalizations.of(context)!
                                .translate('select_assignees_list')
                            : selectedUsersData
                                    .take(3) // Limit to 3 for performance
                                    .map((e) =>
                                        '${e.name ?? 'Unknown'} ${e.lastname ?? ''}')
                                    .join(', ') +
                                (selectedUsersData.length > 3
                                    ? ' +${selectedUsersData.length - 3} more'
                                    : '');
                        return Text(
                          selectedUsersNames,
                          style: userTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!
                            .translate('select_assignees_list'),
                        style: userTextStyle.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      onListChanged: (values) {
                        // Filter out sentinel if somehow selected
                        final filteredValues = values
                            .where((v) => v != selectAllSentinel)
                            .toList();
                        widget.onSelectUsers(filteredValues);
                        setState(() {
                          selectedUsersData = filteredValues;
                          allSelected =
                              filteredValues.length == (usersList.length - 1);
                        });
                        field.didChange(filteredValues);
                      },
                    );
                  }
                  return const SizedBox.shrink(); // Fallback
                },
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildListItem(
      UserData item, bool isSelected, Function() onItemSelect) {
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
                  color: const Color(0xff1E2E52),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color:
                    isSelected ? const Color(0xff1E2E52) : Colors.transparent,
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
                '${item.name ?? 'Unknown'} ${item.lastname ?? ''}',
                style: userTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
