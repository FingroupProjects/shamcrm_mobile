import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_state.dart';
import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectWidget extends StatefulWidget {
  final String? selectedProject;
  final ValueChanged<String?> onChanged;

  ProjectWidget({required this.selectedProject, required this.onChanged});

  @override
  _ProjectWidgetState createState() => _ProjectWidgetState();
}

class _ProjectWidgetState extends State<ProjectWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];

        if (state is ProjectLoading) {
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
        } else if (state is ProjectLoaded) {
          print('Список проектов: ${state.projects}');
          dropdownItems =
              state.projects.map<DropdownMenuItem<String>>((Project project) {
            return DropdownMenuItem<String>(
              value: project.id.toString(),
              child: Text(project.name),
            );
          }).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Проект',
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
                        .any((item) => item.value == widget.selectedProject)
                    ? widget.selectedProject
                    : null,
                hint: const Text(
                  'Выберите проекта',
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
