import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedProjects;
  final Function(List<ProjectTask>) onSelectProjects;

  const ProjectMultiSelectWidget({
    super.key,
    required this.onSelectProjects,
    this.selectedProjects,
  });

  @override
  State<ProjectMultiSelectWidget> createState() =>
      _ProjectMultiSelectWidgetState();
}

class _ProjectMultiSelectWidgetState extends State<ProjectMultiSelectWidget> {
  List<ProjectTask> projectsList = [];
  List<ProjectTask> selectedProjectsData = [];
  bool allSelected = false;

  @override
  void initState() {
    super.initState();
    context.read<GetTaskProjectBloc>().add(GetTaskProjectEv());
  }

  // Функция для выделения/снятия выделения всех проектов
  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      if (allSelected) {
        selectedProjectsData = List.from(projectsList); // Выбираем всех
      } else {
        selectedProjectsData = []; // Снимаем выделение
      }
      widget.onSelectProjects(selectedProjectsData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final projectTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: colors.textPrimary,
    );
    return FormField<List<ProjectTask>>(
      validator: (value) {
        if (selectedProjectsData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<ProjectTask>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('projects'),
              style: projectTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? colors.error : colors.fieldBorder,
                ),
              ),
              child: BlocBuilder<GetTaskProjectBloc, GetTaskProjectState>(
                builder: (context, state) {
                  if (state is GetTaskProjectSuccess) {
                    projectsList = state.dataProject.result ?? [];
                    if (widget.selectedProjects != null &&
                        projectsList.isNotEmpty) {
                      selectedProjectsData = projectsList
                          .where((project) => widget.selectedProjects!
                              .contains(project.id.toString()))
                          .toList();
                      allSelected =
                          selectedProjectsData.length == projectsList.length;
                    }
                  }

                  return CustomDropdown<ProjectTask>.multiSelectSearch(
                    items: projectsList,
                    initialItems: selectedProjectsData,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: colors.fieldBg,
                      expandedFillColor: colors.surfacePrimary,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: colors.fieldBorder,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                      hintStyle: projectTextStyle.copyWith(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                      headerStyle: projectTextStyle,
                      listItemStyle: projectTextStyle,
                      listItemDecoration: ListItemDecoration(
                        selectedColor:
                            colors.buttonPrimaryBg.withValues(alpha: 0.14),
                        highlightColor:
                            colors.buttonPrimaryBg.withValues(alpha: 0.08),
                        splashColor: Colors.transparent,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: colors.fieldBg,
                        textStyle: projectTextStyle.copyWith(fontSize: 14),
                        hintStyle: projectTextStyle.copyWith(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                        prefixIcon:
                            Icon(Icons.search, color: colors.iconSecondary),
                        suffixIcon: (onClear) => IconButton(
                          onPressed: onClear,
                          icon: Icon(Icons.close_rounded,
                              color: colors.iconSecondary),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.buttonPrimaryBg),
                        ),
                      ),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      // Добавляем "Выделить всех" как первый элемент
                      if (projectsList.indexOf(item) == 0) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: GestureDetector(
                                onTap: _toggleSelectAll,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: colors.buttonPrimaryBg,
                                            width: 1),
                                        borderRadius: BorderRadius.circular(4),
                                        color: allSelected
                                            ? colors.buttonPrimaryBg
                                            : Colors.transparent,
                                      ),
                                      child: allSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('select_all'),
                                        style: projectTextStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                                height: 20,
                                color: colors.fieldBorder), // Разделитель
                            _buildListItem(item, isSelected, onItemSelect),
                          ],
                        );
                      }
                      // Обычные элементы списка
                      return _buildListItem(item, isSelected, onItemSelect);
                    },
                    headerListBuilder: (context, hint, enabled) {
                      String selectedProjectsNames = selectedProjectsData
                              .isEmpty
                          ? AppLocalizations.of(context)!
                              .translate('select_project')
                          : selectedProjectsData.map((e) => e.name).join(', ');
                      return Text(
                        selectedProjectsNames,
                        style: projectTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        allSelected = values.length == projectsList.length;
                      });
                      field.didChange(values);
                    },
                  );
                },
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    color: colors.error,
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

  Widget _buildListItem(
      ProjectTask item, bool isSelected, Function() onItemSelect) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.buttonPrimaryBg,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? colors.buttonPrimaryBg : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
