import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_event.dart';
import 'package:crm_task_manager/bloc/project/project_state.dart';
import 'package:crm_task_manager/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectRadioGroupWidget extends StatefulWidget {
  final String? selectedProject;
  final Function(Project) onSelectProject;

  ProjectRadioGroupWidget(
      {super.key, required this.onSelectProject, this.selectedProject});

  @override
  State<ProjectRadioGroupWidget> createState() =>
      _ProjectRadioGroupWidgetState();
}

class _ProjectRadioGroupWidgetState extends State<ProjectRadioGroupWidget> {
  List<Project> projectsList = [];
  Project? selectedProjectData;

  @override
  void initState() {
    super.initState();
    context.read<GetAllProjectBloc>().add(GetAllProjectEv());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllProjectBloc, GetAllProjectState>(
          builder: (context, state) {
            if (state is GetAllProjectLoading) {
              // return Center(child: CircularProgressIndicator());
            }

            if (state is GetAllProjectError) {
              return Text(state.message);
            }
            if (state is GetAllProjectSuccess) {
              projectsList = state.dataProject.result ?? [];
              if (widget.selectedProject != null && projectsList.isNotEmpty) {
                try {
                  selectedProjectData = projectsList.firstWhere(
                    (project) =>
                        project.id.toString() == widget.selectedProject,
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
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(width: 1, color: Color(0xFFF4F7FD)),
                    ),
                    child: CustomDropdown<Project>.search(
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
                        return Text(item.name!);
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem.name ?? 'Выберите проект',
                          style: TextStyle(
                            fontSize: 14,
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
