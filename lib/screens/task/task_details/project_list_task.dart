import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectTaskGroupWidget extends StatefulWidget {
  final String? selectedProject;
  final Function(ProjectTask) onSelectProject;
  final String? errorText;

  const ProjectTaskGroupWidget({
    super.key,
    required this.onSelectProject,
    this.selectedProject,
    this.errorText,
  });

  @override
  State<ProjectTaskGroupWidget> createState() => _ProjectTaskGroupWidgetState();
}

class _ProjectTaskGroupWidgetState extends State<ProjectTaskGroupWidget> {
  static const int _pageSize = 20;
  final ApiService _apiService = ApiService();
  List<ProjectTask> projectsList = [];
  ProjectTask? selectedProjectData;
  bool _hasAutoSelected = false;

  @override
  void initState() {
    super.initState();
    context.read<GetTaskProjectBloc>().add(GetTaskProjectEv());
  }

  void _handleProjectSelection(List<ProjectTask> projects) {
    if (_hasAutoSelected) return;

    if (projects.length == 1 && selectedProjectData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          selectedProjectData = projects.first;
          _hasAutoSelected = true;
        });
        widget.onSelectProject(projects.first);
      });
    } else if (widget.selectedProject != null && projects.isNotEmpty) {
      try {
        final foundProject = projects.firstWhere(
          (p) => p.id.toString() == widget.selectedProject,
        );
        if (selectedProjectData != foundProject) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => selectedProjectData = foundProject);
          });
        }
      } catch (e) {
        if (selectedProjectData != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => selectedProjectData = null);
          });
        }
      }
    }
  }

  ProjectTask? _getValidInitialItem(List<ProjectTask> projects) {
    if (selectedProjectData == null) return null;
    try {
      return projects
          .firstWhere((p) => p.id == selectedProjectData!.id);
    } catch (e) {
      return null;
    }
  }

  Future<CustomDropdownPaginatedResponse<ProjectTask>> _searchProjects(
    String query,
    int page,
  ) async {
    final response = await _apiService.getTaskProject(
      page: page,
      perPage: _pageSize,
      search: query,
    );
    final items = response.result ?? <ProjectTask>[];

    return CustomDropdownPaginatedResponse<ProjectTask>(
      items: items,
      hasMore: (response.pagination?.currentPage ?? page) <
          (response.pagination?.totalPages ??
              (items.length >= _pageSize ? page + 1 : page)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    final hintStyle = projectTextStyle.copyWith(
      fontSize: 14,
      color: context.appColors.textSecondary,
    );

    return FormField<ProjectTask>(
      validator: (value) {
        if (selectedProjectData == null) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
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
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.appColors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: widget.errorText != null
                      ? context.appColors.error
                      : context.appColors.borderSubtle,
                ),
              ),
              child: BlocBuilder<GetTaskProjectBloc, GetTaskProjectState>(
                builder: (context, state) {
                  if (state is GetTaskProjectSuccess) {
                    projectsList = state.dataProject.result ?? [];
                    _handleProjectSelection(projectsList);
                  }

                  return CustomDropdown<ProjectTask>.searchRequestPaginated(
                    paginatedRequest: _searchProjects,
                    futureRequestDelay: const Duration(milliseconds: 350),
                    closeDropDownOnClearFilterSearch: true,
                    items: projectsList,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: context.appColors.fieldBg,
                      expandedFillColor: context.appColors.surfacePrimary,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: context.appColors.borderSubtle,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                      hintStyle: hintStyle,
                      headerStyle: projectTextStyle,
                      listItemStyle: projectTextStyle,
                      listItemDecoration: ListItemDecoration(
                        selectedColor: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.14),
                        highlightColor: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.08),
                        splashColor: Colors.transparent,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: context.appColors.backgroundPrimary,
                        textStyle: projectTextStyle,
                        hintStyle: hintStyle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.appColors.borderSubtle,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.appColors.buttonPrimaryBg,
                          ),
                        ),
                      ),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          item.name,
                          style: projectTextStyle,
                        ),
                      );
                    },
                    headerBuilder: (context, selectedItem, enabled) {
                      return Text(
                        selectedItem.name,
                        style: projectTextStyle,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_project'),
                      style: hintStyle,
                    ),
                    excludeSelected: false,
                    initialItem: _getValidInitialItem(projectsList),
                    onChanged: (value) {
                      if (value != null) {
                        widget.onSelectProject(value);
                        setState(() => selectedProjectData = value);
                        field.didChange(value);
                        FocusScope.of(context).unfocus();
                      }
                    },
                  );
                },
              ),
            ),
            if (widget.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.errorText!,
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}