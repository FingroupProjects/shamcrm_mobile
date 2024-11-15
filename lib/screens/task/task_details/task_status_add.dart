import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_event.dart';
import 'package:crm_task_manager/bloc/role/role_bloc.dart';
import 'package:crm_task_manager/bloc/role/role_event.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/task/task_details/task_status_list.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list.dart';
import 'package:crm_task_manager/screens/task/task_details/role_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateStatusDialog extends StatefulWidget {
  CreateStatusDialog({Key? key}) : super(key: key);

  @override
  _CreateStatusDialogState createState() => _CreateStatusDialogState();
}

class _CreateStatusDialogState extends State<CreateStatusDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;
  String? selectedProject;
  String? selectedTaskStatusName;
    String? selectedTaskStatus;

  String? selectedRole;
  bool hasAccess = false;
  bool isFinalStage = false;

  @override
  void initState() {
    super.initState();
    context.read<RoleBloc>().add(FetchRoles());
    context.read<ProjectBloc>().add(FetchProjects());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        'Добавить статуса',
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E2E52),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
           const SizedBox(height: 16),
StatusList(
  selectedTaskStatus: selectedTaskStatus,
  onChanged: (String? newValue) {
    setState(() {
      selectedTaskStatus = newValue;
    });
  },
),
            const SizedBox(height: 16),
            ProjectWidget(
              selectedProject: selectedProject,
              onChanged: (String? newValue) {
                setState(() {
                  selectedProject = newValue;
                });
              },
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      checkboxTheme: CheckboxThemeData(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        fillColor: MaterialStateProperty.all(Colors.transparent), // Прозрачный фон
                        checkColor: MaterialStateProperty.all(Color(0xFF1E2E52)), // Темно-синяя галочка
                        side: BorderSide(color: Color(0xFF1E2E52), width: 2), // Рамка темно-синего цвета
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        'С доступом',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      value: hasAccess,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool? value) {
                        setState(() {
                          hasAccess = value ?? false;
                          if (!hasAccess) {
                            selectedRole = null;
                          }
                        });
                      },
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      checkboxTheme: CheckboxThemeData(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4
                          ),
                        ),
                        fillColor: MaterialStateProperty.all(Colors.transparent),
                        checkColor: MaterialStateProperty.all(Color(0xFF1E2E52)),
                        side: BorderSide(color: Color(0xFF1E2E52), width: 2),
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        'Завершающий этап',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      value: isFinalStage,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool? value) {
                        setState(() {
                          isFinalStage = value ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (hasAccess) ...[
              const SizedBox(height: 2),
              RoleWidget(
                selectedRole: selectedRole,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedRole = newValue;
                  });
                },
              ),
            ],
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  buttonText: 'Отмена',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  buttonColor: Colors.red,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  buttonText: 'Добавить',
                  onPressed: () {
                    final name = _controller.text;
                    if (selectedTaskStatusName != null && selectedProject != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                      context.read<TaskBloc>().add(
                            CreateTaskStatus(
                              name: selectedTaskStatusName!,
                              color: '#000000',
                              hasAccess: hasAccess,
                              isFinalStage: isFinalStage,
                              roleId: hasAccess ? selectedRole : null,
                            ),
                          );
                      Navigator.of(context).pop();
                    } else {
                      setState(() {
                        _errorMessage = 'Заполните обязательные поля';
                      });
                    }
                  },
                  buttonColor: Color(0xFF1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
