import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_state.dart';

class UserFilterPopup extends StatefulWidget {
  final Function(List<dynamic>)? onUserSelected;

  const UserFilterPopup({
    Key? key,
    this.onUserSelected,
  }) : super(key: key);

  @override
  _UserFilterPopupState createState() => _UserFilterPopupState();
}

class _UserFilterPopupState extends State<UserFilterPopup> {
  Set<dynamic> selectedUsers = {};
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  void updateSelection(dynamic user) {
    setState(() {
      if (selectedUsers.contains(user)) {
        selectedUsers.remove(user);
      } else {
        selectedUsers.add(user);
      }
    });
    _notifySelectionChanged();
  }

  void _notifySelectionChanged() {
    if (widget.onUserSelected != null) {
      final userIds = selectedUsers.map((user) => user.id).toList();
      widget.onUserSelected!(userIds);
    }
  }

  void toggleSelectAll(List<dynamic> users) {
    setState(() {
      if (selectedUsers.length == users.length) {
        selectedUsers.clear();
      } else {
        selectedUsers = Set.from(users);
      }
    });
    _notifySelectionChanged();
  }

  List<dynamic> filterUsers(List<dynamic> users) {
    if (searchQuery.isEmpty) return users;
    return users.where((user) {
      final name = user.name?.toString().toLowerCase() ?? '';
      final lastname = user.lastname?.toString().toLowerCase() ?? '';
      final fullName = '$name $lastname';
      return fullName.contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      constraints: BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<UserTaskBloc, UserTaskState>(
            builder: (context, state) {
              final allUsers = state is UserTaskLoaded ? state.users : [];
              final isAllSelected = allUsers.isNotEmpty && 
                  selectedUsers.length == allUsers.length;

              return Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => toggleSelectAll(allUsers),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isAllSelected ? Color(0xFF4339F2) : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isAllSelected ? Color(0xFF4339F2) : Color(0xFFCCCCCC),
                              width: 1,
                            ),
                          ),
                          child: isAllSelected
                              ? Icon(Icons.check, size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск',
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF1E2E52)),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<UserTaskBloc, UserTaskState>(
              builder: (context, state) {
                if (state is UserTaskLoading) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: Color(0xff1E2E52)),
                    ),
                  );
                } else if (state is UserTaskError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        state.message,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                } else if (state is UserTaskLoaded) {
                  final filteredUsers = filterUsers(state.users);
                  
                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Нет доступных пользователей',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final name = user.name ?? 'Без имени';
                      final isSelected = selectedUsers.contains(user);

                      return InkWell(
                        onTap: () => updateSelection(user),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFEEEEEE),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Color(0xFF4339F2) : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isSelected ? Color(0xFF4339F2) : Color(0xFFCCCCCC),
                                    width: 1,
                                  ),
                                ),
                                child: isSelected 
                                    ? Icon(Icons.check, size: 18, color: Colors.white)
                                    : null,
                              ),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 14,
                                    color: Color(0xFF1E2E52),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return Container();
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: () {
                _notifySelectionChanged();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4339F2),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Применить',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}