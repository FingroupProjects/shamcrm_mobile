import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
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

  @override
  void initState() {
    super.initState();
    // context.read<GetAllClientBloc>().add(GetAllClientEv());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllClientBloc, GetAllClientState>(
          builder: (context, state) {
            if (state is GetAllClientLoading) {
              return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)),);
            }

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
                  const Text(
                    'Пользователи',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xfff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(width: 1, color: Color(0xFFF4F7FD)),
                    ),
                    child: CustomDropdown<UserData>.multiSelectSearch(
                      items: usersList,
                      initialItems: selectedUsersData,
                      searchHintText: 'Поиск',
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
                                        color: Color(0xff1E2E52), width: 1),
                                    color: isSelected
                                        ? Color(0xff1E2E52)
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Icon(Icons.check,
                                          color: Colors.white, size: 16)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                // Wrap the Text widget in a Flexible
                                Flexible(
                                  child: Text(item.name!,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Gilroy',
                                        color: Color(0xff1E2E52),
                                      )),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => onItemSelect(),
                        );
                      },
                      headerListBuilder: (context, hint, enabled) {
                        int selectedUsersCount = selectedUsersData.length;

                        return Text(
                          selectedUsersCount == 0
                              ? 'Выберите пользователей'
                              : 'Выбрано пользователей: $selectedUsersCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        );
                      },

                      hintBuilder: (context, hint, enabled) =>
                          Text('Выберите пользователей',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              )),
                      onListChanged: (values) {
                        widget.onSelectUsers(values);
                        setState(() {
                          selectedUsersData = values;
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
}
