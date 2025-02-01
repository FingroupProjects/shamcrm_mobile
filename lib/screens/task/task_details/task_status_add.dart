import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_event.dart';
import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_event.dart';
import 'package:crm_task_manager/bloc/role/role_bloc.dart';
import 'package:crm_task_manager/bloc/role/role_event.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task_status_add/task_bloc.dart'
    as task_status_add;
import 'package:crm_task_manager/bloc/task_status_add/task_event.dart'
    as task_status_add;
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list_task.dart';
import 'package:crm_task_manager/screens/task/task_details/role_list.dart';
import 'package:crm_task_manager/screens/task/task_details/task_status_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateStatusDialog extends StatefulWidget {
  
  const CreateStatusDialog({Key? key}) : super(key: key);

  @override
  _CreateStatusDialogState createState() => _CreateStatusDialogState();
}

class _CreateStatusDialogState extends State<CreateStatusDialog> {
  int? selectedStatusNameId;
  String? selectedProjectId;
  List<int> selectedRoleIds = [];
  bool needsPermission = false;
  bool isFinalStage = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    context.read<TaskStatusNameBloc>().add(FetchStatusNames());
    context.read<GetAllProjectBloc>().add(GetAllProjectEv());
    context.read<RoleBloc>().add(FetchRoles());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        AppLocalizations.of(context)!.translate('add_status'),
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
              selectedTaskStatus:
                  selectedStatusNameId?.toString(), // Передаем строку
              onChanged: (String? statusName, int? statusId) {
                setState(() {
                  selectedStatusNameId = statusId; // Обновляем статус
                });
              },
            ),
            const SizedBox(height: 16),
            ProjectTaskGroupWidget(
              selectedProject: selectedProjectId,
              onSelectProject: (ProjectTask selectedProjectData) {
                setState(() {
                  selectedProjectId = selectedProjectData.id.toString();
                });
              },
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('with_access'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Switch(
                          value: needsPermission,
                          onChanged: (value) {
                            setState(() {
                              needsPermission = value;
                              if (!value) {
                                selectedRoleIds.clear();
                              }
                            });
                          },
                          activeColor: const Color.fromARGB(255, 255, 255, 255),
                          inactiveTrackColor:
                              const Color.fromARGB(255, 179, 179, 179)
                                  .withOpacity(0.5),
                          activeTrackColor:
                              const Color.fromARGB(255, 51, 65, 98)
                                  .withOpacity(0.5),
                          inactiveThumbColor:
                              const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('final_stage_add'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Switch(
                          value: isFinalStage,
                          onChanged: (value) {
                            setState(() {
                              isFinalStage = value;
                            });
                          },
                          activeColor: const Color.fromARGB(255, 255, 255, 255),
                          inactiveTrackColor:
                              const Color.fromARGB(255, 179, 179, 179)
                                  .withOpacity(0.5),
                          activeTrackColor:
                              const Color.fromARGB(255, 51, 65, 98)
                                  .withOpacity(0.5),
                          inactiveThumbColor:
                              const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (needsPermission) ...[
              const SizedBox(height: 2),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: RoleSelectionWidget(
                  selectedRoleIds: selectedRoleIds,
                  onRolesChanged: (roleIds) {
                    setState(() {
                      selectedRoleIds = roleIds;
                    });
                  },
                ),
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
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('cancel'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _createStatus,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Color(0xFF1E2E52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                   AppLocalizations.of(context)!.translate('add'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _createStatus() {
    if (selectedStatusNameId == null || selectedProjectId == null) {
      setState(() {
        _errorMessage =  AppLocalizations.of(context)!.translate('fill_required_fields');
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    // Создаем новый статус
    context.read<task_status_add.TaskStatusBloc>().add(
          task_status_add.CreateTaskStatusAdd(
            taskStatusNameId: selectedStatusNameId!,
            projectId: int.tryParse(selectedProjectId!) ?? 0,
            needsPermission: needsPermission,
            roleIds: needsPermission ? selectedRoleIds : null,
            finalStep: isFinalStage,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.translate('status_created_successfully'),
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.green,
        elevation: 3,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        duration: Duration(seconds: 3),
      ),
    );
    Navigator.pop(context, true);

    Future.delayed(Duration(milliseconds: 0), () {
      context.read<TaskBloc>().add(FetchTaskStatuses());
    });
  }
}
