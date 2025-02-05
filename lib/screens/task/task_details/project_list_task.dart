import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_state.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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

  final TextStyle projectTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    context.read<GetTaskProjectBloc>().add(GetTaskProjectEv());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<GetTaskProjectBloc, GetTaskProjectState>(
          builder: (context, state) {
            // if (state is GetTaskProjectLoading) {
            //   return const Center(child: CircularProgressIndicator());
            // }

            if (state is GetTaskProjectError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.translate(state.message),
                      style: projectTextStyle.copyWith(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: const Duration(seconds: 2),
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

              return FormField<ProjectTask>(
                validator: (value) {
                  if (selectedProjectData == null) {
                    return AppLocalizations.of(context)!.translate('field_required_project');
                  }
                  return null;
                },
                builder: (FormFieldState<ProjectTask> field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.translate('projects'),
                        style: projectTextStyle.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 1,
                            color: field.hasError 
                                ? Colors.red 
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: CustomDropdown<ProjectTask>.search(
                          closeDropDownOnClearFilterSearch: true,
                          items: projectsList,
                          searchHintText: AppLocalizations.of(context)!.translate('search'),
                          overlayHeight: 400,
                          decoration: CustomDropdownDecoration(
                            closedFillColor: const Color(0xffF4F7FD),
                            expandedFillColor: Colors.white,
                            closedBorder: Border.all(
                              color: Colors.transparent,
                              width: 1,
                            ),
                            closedBorderRadius: BorderRadius.circular(12),
                            expandedBorder: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                            expandedBorderRadius: BorderRadius.circular(12),
                            // textPadding: const EdgeInsets.symmetric(
                            //   horizontal: 16,
                            //   vertical: 12,
                            // ),
                          ),
                          listItemBuilder: (context, item, isSelected, onItemSelect) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                item.name!,
                                style: projectTextStyle,
                              ),
                            );
                          },
                          headerBuilder: (context, selectedItem, enabled) {
                            return Text(
                              selectedItem?.name ?? 
                                  AppLocalizations.of(context)!.translate('select_project'),
                              style: projectTextStyle,
                            );
                          },
                          hintBuilder: (context, hint, enabled) => Text(
                            AppLocalizations.of(context)!.translate('select_project'),
                            style: projectTextStyle.copyWith(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          excludeSelected: false,
                          initialItem: selectedProjectData,
                          onChanged: (value) {
                            if (value != null) {
                              widget.onSelectProject(value);
                              setState(() {
                                selectedProjectData = value;
                              });
                              field.didChange(value);
                              FocusScope.of(context).unfocus();
                            }
                          },
                        ),
                      ),
                       if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 0),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        ),
                    ],
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }
}