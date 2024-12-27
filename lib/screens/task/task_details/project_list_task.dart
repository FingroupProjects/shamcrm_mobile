import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_state.dart';
import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectTaskGroupWidget extends StatefulWidget {
  final String? selectedProject;
  final Function(ProjectTask) onSelectProject;

  ProjectTaskGroupWidget(
      {super.key, required this.onSelectProject, this.selectedProject});

  @override
  State<ProjectTaskGroupWidget> createState() =>
      _ProjectTaskGroupWidgetState();
}

class _ProjectTaskGroupWidgetState extends State<ProjectTaskGroupWidget> {
  List<ProjectTask> projectsList = [];
  ProjectTask? selectedProjectData;

  @override
  void initState() {
    super.initState();
    context.read<GetTaskProjectBloc>().add(GetTaskProjectEv());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetTaskProjectBloc, GetTaskProjectState>(
          builder: (context, state) {
            if (state is GetTaskProjectLoading) {
              // return Center(child: CircularProgressIndicator());
            }

            if (state is GetTaskProjectError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${state.message}',
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
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 2),
                  ),
                );
              });
            }

            if (state is GetTaskProjectSuccess) {
              projectsList = state.dataProject.result ?? [];
              if (widget.selectedProject != null && projectsList.isNotEmpty) {
                try {
                  selectedProjectData = projectsList.firstWhere(
                    (projectTask) =>
                        projectTask.id.toString() == widget.selectedProject,
                  );
                } catch (e) {
                  selectedProjectData = null;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Проекты',
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
                    child: CustomDropdown<ProjectTask>.search(
                      closeDropDownOnClearFilterSearch: true,
                      items: projectsList,
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
                        return Text(item.name!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                              color: Color(0xff1E2E52),
                            ));
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem.name ?? 'Выберите проект',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) =>
                          Text('Выберите проект',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              )),
                      excludeSelected: false,
                      initialItem: selectedProjectData,
                      validator: (value) {
                        if (value == null) {
                          return 'Поле обязательно для заполнения';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value != null) {
                          widget.onSelectProject(value);
                          setState(() {
                            selectedProjectData = value;
                          });
                          FocusScope.of(context).unfocus();
                        }
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
