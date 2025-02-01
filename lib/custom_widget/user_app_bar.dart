import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_state.dart';

class UserFilterPopup extends StatefulWidget {
  final Function(List<dynamic>)? onUsersSelected;

  const UserFilterPopup({
    Key? key,
    this.onUsersSelected,
  }) : super(key: key);

  @override
  _UserFilterPopupState createState() => _UserFilterPopupState();
}

class _UserFilterPopupState extends State<UserFilterPopup> {
  List<dynamic> _selectedUsers = [];
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  void toggleSelectAll(List<dynamic> users) {
    setState(() {
      if (_selectedUsers.length == users.length) {
        _selectedUsers.clear();
      } else {
        _selectedUsers = List.from(users);
      }
    });
  }

  List<dynamic> filterUsers(List<dynamic> users) {
    if (searchQuery.isEmpty) return users;
    return users.where((user) {
      final name = user.name?.toString().toLowerCase() ?? '';
      final lastname = user.lastname?.toString().toLowerCase() ?? '';
      return name.contains(searchQuery.toLowerCase()) || lastname.contains(searchQuery.toLowerCase());
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
                  _selectedUsers.length == allUsers.length;
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
                            color: isAllSelected
                                ? Color(0xFF4339F2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isAllSelected
                                  ? Color(0xFF4339F2)
                                  : Color(0xFFCCCCCC),
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
                          hintText:
                              AppLocalizations.of(context)!.translate('search'),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                      child:
                          CircularProgressIndicator(color: Color(0xff1E2E52)),
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
                  final users = state.users;
                  if (users == null) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate('no_any_users'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                    );
                  }

                  final filteredUsers = filterUsers(users);

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final name = user.name ?? 'Без имени';
                      final lastname = user.lastname ?? 'Без фамилии';
                      final isSelected = _selectedUsers.contains(user);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUsers.remove(user);
                            } else {
                              _selectedUsers.add(user);
                            }
                          });
                        },
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
                                  color: isSelected
                                      ? Color(0xFF4339F2)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isSelected
                                        ? Color(0xFF4339F2)
                                        : Color(0xFFCCCCCC),
                                    width: 1,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(Icons.check,
                                        size: 18, color: Colors.white)
                                    : null,
                              ),
                              Expanded(
                                child: Text(
                                  '$name $lastname',
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
                if (widget.onUsersSelected != null) {
                  widget.onUsersSelected!(_selectedUsers);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4339F2),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('selected'),
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
