import 'package:crm_task_manager/bloc/role/role_bloc.dart';
import 'package:crm_task_manager/bloc/role/role_state.dart';
import 'package:crm_task_manager/models/role_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoleWidget extends StatefulWidget {
  final String? selectedRole;
  final ValueChanged<String?> onChanged;

  RoleWidget({required this.selectedRole, required this.onChanged});

  @override
  _RoleWidgetState createState() => _RoleWidgetState();
}

class _RoleWidgetState extends State<RoleWidget> {
  List<String> selectedRoles = [];
  bool isDropdownOpen = false;

  void _onRoleSelected(bool? selected, String roleName) {
    setState(() {
      if (selected == true) {
        selectedRoles.add(roleName);
      } else {
        selectedRoles.remove(roleName);
      }
      widget.onChanged(selectedRoles.join(', '));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoleBloc, RoleState>(
      builder: (context, state) {
        List<Widget> roleCheckboxes = [];

        if (state is RoleLoading) {
          roleCheckboxes = [
            Center(
              child: Text(
                'Загрузка...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ];
        } else if (state is RoleLoaded) {
          roleCheckboxes = state.roles.map<Widget>((Role role) {
            return CheckboxListTile(
              title: Text(
                role.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              value: selectedRoles.contains(role.name),
              onChanged: (bool? selected) {
                _onRoleSelected(selected, role.name);
              },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Color(0xff1E2E52), // темно-синий цвет для галочек
              checkColor: Colors.white, // цвет галочки
              tileColor: Colors.transparent, // прозрачный фон для плитки
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Color(0xff1E2E52), width: 1), // темно-синяя рамка
              ),
            );
          }).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Роль',
              style: TextStyle(
                fontSize: 18,
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
                        selectedRoles.isNotEmpty
                            ? selectedRoles.join(', ')
                            : 'Выберите роли',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      isDropdownOpen
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: Color(0xff1E2E52),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: roleCheckboxes,
                ),
              ),
          ],
        );
      },
    );
  }
}
