import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_state.dart';
import 'package:crm_task_manager/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserWidget extends StatefulWidget {
  final String? selectedUser;
  final ValueChanged<String?> onChanged;

  UserWidget({required this.selectedUser, required this.onChanged});

  @override
  _UserWidgetState createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserTaskBloc, UserTaskState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];

        if (state is UserTaskLoading) {
          dropdownItems = [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Загрузка...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ];
        } else if (state is UserTaskLoaded) {
          print('Список пользователей: ${state.users}');
          dropdownItems =
              state.users.map<DropdownMenuItem<String>>((UserTask users) {
            return DropdownMenuItem<String>(
              value: users.id.toString(),
              child: Text(users.name),
            );
          }).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Пользователь',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<String>(
                value: dropdownItems
                        .any((item) => item.value == widget.selectedUser)
                    ? widget.selectedUser
                    : null,
                hint: const Text(
                  'Выберите пользователя',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                items: dropdownItems,
                onChanged: widget.onChanged,
                validator: (value) {
                  if (value == null) {
                    return 'Поле обязательно для заполнения';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: Colors.white,
                icon: Image.asset(
                  'assets/icons/tabBar/dropdown.png',
                  width: 16,
                  height: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
/*import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_state.dart';
import 'package:crm_task_manager/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserWidget extends StatefulWidget {
  final List<String> selectedUserIds;
  final Function(List<String>) onUsersChanged;

  const UserWidget({
    Key? key,
    required this.selectedUserIds,
    required this.onUsersChanged,
  }) : super(key: key);

  @override
  _UserWidgetState createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  List<String> _selectedUserIds = [];
  bool isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedUserIds = List.from(widget.selectedUserIds);
  }

  void _onUserSelected(bool? selected, UserTask user) {
    setState(() {
      if (selected == true) {
        _selectedUserIds.add(user.id.toString());
      } else {
        _selectedUserIds.remove(user.id.toString());
      }
      widget.onUsersChanged(_selectedUserIds);
    });
  }

  String _getSelectedUsersText(List<UserTask> users) {
    if (_selectedUserIds.isEmpty) return 'Выберите пользователей';

    return users
        .where((user) => _selectedUserIds.contains(user.id.toString()))
        .map((user) => user.name)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserTaskBloc, UserTaskState>(
      builder: (context, state) {
        List<Widget> userCheckboxes = [];

        if (state is UserTaskLoading) {
          return Center(
            child: Text(
              'Загрузка...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
          );
        } else if (state is UserTaskLoaded) {
          userCheckboxes.addAll(
            state.users.map<Widget>((UserTask user) {
              return CheckboxListTile(
                title: Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                value: _selectedUserIds.contains(user.id.toString()),
                onChanged: (bool? selected) => _onUserSelected(selected, user),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Color(0xff1E2E52),
                checkColor: Colors.white,
                tileColor: Colors.transparent,
              );
            }).toList(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Пользователь',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  isDropdownOpen = !isDropdownOpen;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFF4F7FD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFF4F7FD)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        state is UserTaskLoaded
                            ? _getSelectedUsersText(state.users)
                            : 'Выберите пользователей',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Image.asset(
                      'assets/icons/tabBar/dropdown.png',
                      width: 16,
                      height: 16,
                    ),
                  ],
                ),
              ),
            ),
            if (isDropdownOpen)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xff1E2E52).withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: userCheckboxes,
                ),
              ),
          ],
        );
      },
    );
  }
}*/