
import 'package:crm_task_manager/bloc/project%20copy/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/project%20copy/statusName_state.dart';
import 'package:crm_task_manager/models/TaskStatusName_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class StatusList extends StatefulWidget {
  final String? selectedTaskStatus;
  final ValueChanged<String?> onChanged;

  StatusList({
    required this.selectedTaskStatus, 
    required this.onChanged
  });

  @override
  _TaskStatusListState createState() => _TaskStatusListState();
}

class _TaskStatusListState extends State<StatusList> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatusNameBloc, StatusNameState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];

        if (state is StatusNameLoading) {
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
        } else if (state is StatusNameLoaded) {
          dropdownItems = state.statusName.map<DropdownMenuItem<String>>((StatusName status) {
            return DropdownMenuItem<String>(
              value: status.id.toString(),
              child: Text(status.name),
            );
          }).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статус задачи',
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
                    .any((item) => item.value == widget.selectedTaskStatus)
                    ? widget.selectedTaskStatus
                    : null,
                hint: const Text(
                  'Выберите статус задачи',
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