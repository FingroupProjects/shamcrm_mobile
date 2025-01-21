import 'package:crm_task_manager/bloc/role/role_bloc.dart';
import 'package:crm_task_manager/bloc/role/role_state.dart';
import 'package:crm_task_manager/models/role_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoleSelectionWidget extends StatefulWidget {
  final List<int> selectedRoleIds;
  final Function(List<int>) onRolesChanged;

  const RoleSelectionWidget({
    Key? key,
    required this.selectedRoleIds,
    required this.onRolesChanged,
  }) : super(key: key);

  @override
  _RoleSelectionWidgetState createState() => _RoleSelectionWidgetState();
}

class _RoleSelectionWidgetState extends State<RoleSelectionWidget> {
  List<int> _selectedRoleIds = [];
  bool isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedRoleIds = List.from(widget.selectedRoleIds);
  }

  void _onRoleSelected(bool? selected, Role role) {
    setState(() {
      if (selected == true) {
        _selectedRoleIds.add(role.id);
      } else {
        _selectedRoleIds.remove(role.id);
      }
      widget.onRolesChanged(_selectedRoleIds);
    });
  }

  void _onSelectAll(bool? selected, List<Role> roles) {
    setState(() {
      if (selected == true) {
        _selectedRoleIds = roles.map((role) => role.id).toList();
      } else {
        _selectedRoleIds.clear();
      }
      widget.onRolesChanged(_selectedRoleIds);
    });
  }

  bool _areAllSelected(List<Role> roles) {
    return roles.every((role) => _selectedRoleIds.contains(role.id));
  }

  String _getSelectedRolesText(List<Role> roles) {
    if (_selectedRoleIds.isEmpty) return AppLocalizations.of(context)!.translate('select_roles');

    return roles
        .where((role) => _selectedRoleIds.contains(role.id))
        .map((role) => role.name)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoleBloc, RoleState>(
      builder: (context, state) {
        List<Widget> roleCheckboxes = [];

        if (state is RoleLoading) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.translate('loading'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
          );
        } else if (state is RoleLoaded) {
          // Добавляем чекбокс "Все"
          roleCheckboxes.add(
            CheckboxListTile(
              title: Text(
                AppLocalizations.of(context)!.translate('all'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              value: _areAllSelected(state.roles),
              onChanged: (selected) => _onSelectAll(selected, state.roles),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Color(0xff1E2E52),
              checkColor: Colors.white,
              tileColor: Colors.transparent,
            ),
          );

          // Добавляем разделитель после чекбокса "Все"
          roleCheckboxes.add(
            Divider(
              color: Color(0xff1E2E52).withOpacity(0.2),
              height: 1,
              thickness: 1,
            ),
          );

          // Добавляем остальные роли
          roleCheckboxes.addAll(
            state.roles.map<Widget>((Role role) {
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
                value: _selectedRoleIds.contains(role.id),
                onChanged: (bool? selected) => _onRoleSelected(selected, role),
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
            Text(
              AppLocalizations.of(context)!.translate('role'), 
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
                        state is RoleLoaded
                            ? _getSelectedRolesText(state.roles)
                            : AppLocalizations.of(context)!.translate('select_roles'),
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
                  border: Border.all(color: Color(0xff1E2E52).withOpacity(0.2)),
                  // Убрана тень, чтобы исключить её влияние
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: roleCheckboxes,
                ),
              ),
          ],
        );
      },
    );
  }
}
