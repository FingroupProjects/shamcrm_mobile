import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedUsers;
  final Function(List<UserData>) onSelectUsers;

  UserMultiSelectWidget({
    super.key,
    required this.onSelectUsers,
    this.selectedUsers,
  });

  @override
  State<UserMultiSelectWidget> createState() => _UserMultiSelectWidgetState();
}

class _UserMultiSelectWidgetState extends State<UserMultiSelectWidget> {
  List<UserData> usersList = [];
  List<UserData> selectedUsersData = [];
  bool allSelected = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllClientBloc, GetAllClientState>(
          builder: (context, state) {
            if (state is GetAllClientError) {
              return Text(state.message);
            }
            if (state is GetAllClientSuccess) {
              usersList = state.dataUser.result ?? [];
              if (widget.selectedUsers != null && usersList.isNotEmpty) {
                selectedUsersData = usersList
                    .where((user) =>
                        widget.selectedUsers!.contains(user.id.toString()))
                    .toList();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('assignees_list'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    child: CustomDropdown<UserData>.multiSelectSearch(
                      items: usersList,
                      initialItems: selectedUsersData,
                      searchHintText:
                          AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
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
                      ),
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        // Добавляем "Выделить всех" как первый элемент
                        if (usersList.indexOf(item) == 0) {
                          return Column(
                            children: [
                              ListTile(
                                minTileHeight: 1,
                                minVerticalPadding: 2,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                                dense: true,
                                title: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Color(0xff1E2E52),
                                            width: 1),
                                        color: allSelected
                                            ? Color(0xff1E2E52)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: allSelected
                                          ? Icon(Icons.check,
                                              color: Colors.white, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('select_all'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Gilroy',
                                          color: Color(0xff1E2E52),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    allSelected = !allSelected;
                                    if (allSelected) {
                                      selectedUsersData = List.from(usersList);
                                    } else {
                                      selectedUsersData = [];
                                    }
                                    widget.onSelectUsers(selectedUsersData);
                                  });
                                },
                              ),
                              Divider(
                                  height: 20,
                                  color: Color(0xffF4F7FD)), // Разделитель
                              _buildUserTile(item, isSelected, onItemSelect),
                            ],
                          );
                        }
                        // Обычные элементы списка
                        return _buildUserTile(item, isSelected, onItemSelect);
                      },
                      headerListBuilder: (context, hint, enabled) {
                        int selectedUsersCount = selectedUsersData.length;
                        return Text(
                          selectedUsersCount == 0
                              ? AppLocalizations.of(context)!
                                  .translate('select_assignees_list')
                              : '${AppLocalizations.of(context)!.translate('selected_assignees_list')} $selectedUsersCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!
                            .translate('select_assignees_list'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      onListChanged: (values) {
                        widget.onSelectUsers(values);
                        setState(() {
                          selectedUsersData = values;
                          allSelected = values.length == usersList.length;
                        });
                      },
                    ),
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

  Widget _buildUserTile(
      UserData item, bool isSelected, VoidCallback onItemSelect) {
    return ListTile(
      minTileHeight: 1,
      minVerticalPadding: 2,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
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
                border: Border.all(color: Color(0xff1E2E52), width: 1),
                color: isSelected ? Color(0xff1E2E52) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${item.name} ${item.lastname}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        onItemSelect();
        FocusScope.of(context).unfocus();
      },
    );
  }
}