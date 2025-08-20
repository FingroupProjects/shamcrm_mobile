import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_state.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedProjects;
  final Function(List<ProjectTask>) onSelectProjects;

  const ProjectMultiSelectWidget({
    super.key,
    required this.selectedProjects,
    required this.onSelectProjects,
  });

  @override
  State<ProjectMultiSelectWidget> createState() => _ProjectMultiSelectWidgetState();
}

class _ProjectMultiSelectWidgetState extends State<ProjectMultiSelectWidget> {
  List<ProjectTask> projectsList = [];
  List<ProjectTask> selectedProjectsData = [];

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
            if (state is GetTaskProjectError) {
              return Text(state.message);
            }
            if (state is GetTaskProjectSuccess) {
              projectsList = state.dataProject.result ?? [];
              if (widget.selectedProjects != null && projectsList.isNotEmpty) {
                selectedProjectsData = projectsList
                    .where((project) => widget.selectedProjects!.contains(project.id.toString()))
                    .toList();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('projects'),
                    style: projectTextStyle,
                  ),
                  const SizedBox(height: 4),
                  CustomDropdown<ProjectTask>.multiSelectSearch(
                    items: projectsList,
                    initialItems: selectedProjectsData,
                    searchHintText: AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: const Color(0xffF4F7FD),
                      expandedFillColor: Colors.white,
                      closedBorder: Border.all(
                        color: const Color(0xffF4F7FD),
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: const Color(0xffF4F7FD),
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      return ListTile(
                        minTileHeight: 1,
                        minVerticalPadding: 2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16), // Добавляем отступы
                        dense: true,
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xff1E2E52),
                                  width: 1,
                                ),
                                color: isSelected
                                    ? const Color(0xff1E2E52)
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.name,
                                style: projectTextStyle,
                                overflow: TextOverflow.ellipsis, // Обрезаем длинный текст
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          onItemSelect();
                          FocusScope.of(context).unfocus();
                        },
                      );
                    },
                    headerListBuilder: (context, hint, enabled) {
                      final selectProjectsCount = selectedProjectsData.length;
                      return Text(
                        selectProjectsCount == 0
                            ? AppLocalizations.of(context)!.translate('select_project')
                            : '${AppLocalizations.of(context)!.translate('select_project')} $selectProjectsCount',
                        style: projectTextStyle,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_project'),
                      style: projectTextStyle.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    onListChanged: (values) {
                      widget.onSelectProjects(values);
                      setState(() {
                        selectedProjectsData = values;
                      });
                    },
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }
}