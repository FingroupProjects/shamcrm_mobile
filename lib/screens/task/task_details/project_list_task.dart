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
  final bool hasError; // Флаг для отображения ошибки

  ProjectTaskGroupWidget({
    super.key,
    required this.onSelectProject,
    this.selectedProject,
    this.hasError = false,
  });

  @override
  State<ProjectTaskGroupWidget> createState() => _ProjectTaskGroupWidgetState();
}

class _ProjectTaskGroupWidgetState extends State<ProjectTaskGroupWidget> {
  List<ProjectTask> projectsList = [];
  ProjectTask? selectedProjectData;
  bool _hasAutoSelected = false;
  bool _isLoadingMore = false;

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

  void _loadAllRemainingPages(GetTaskProjectSuccess initialState) async {
    // Загружаем все оставшиеся страницы последовательно, пока не достигнем конца
    if (initialState.hasReachedMax || _isLoadingMore) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    int nextPage = initialState.currentPage + 1;
    int totalPages = initialState.totalPages;

    // Загружаем все страницы последовательно
    while (nextPage <= totalPages && mounted) {
      try {
        // Ждем немного между запросами, чтобы не перегружать сервер
        await Future.delayed(const Duration(milliseconds: 100));

        context.read<GetTaskProjectBloc>().add(
          GetTaskProjectMoreEv(page: nextPage),
        );

        // Ждем обновления состояния (максимум 5 секунд на запрос)
        GetTaskProjectSuccess? updatedState;
        try {
          updatedState = await context.read<GetTaskProjectBloc>().stream
              .where((newState) => newState is GetTaskProjectSuccess)
              .map((newState) => newState as GetTaskProjectSuccess)
              .first
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          // При таймауте или ошибке прекращаем загрузку
          break;
        }

        if (!mounted) {
          break;
        }

        // Проверяем, достигли ли мы конца
        if (updatedState.hasReachedMax) {
          break;
        }

        // Обновляем счетчики для следующей итерации
        nextPage = updatedState.currentPage + 1;
        totalPages = updatedState.totalPages;
      } catch (e) {
        // При ошибке прекращаем загрузку
        break;
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _handleProjectSelection(List<ProjectTask> projects) {
    // Избегаем повторного автоматического выбора
    if (_hasAutoSelected) return;

    // Автоматический выбор, если только один проект
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
              (projectTask) => projectTask.id.toString() == widget.selectedProject,
        );
        if (selectedProjectData != foundProject) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedProjectData = foundProject;
            });
          });
        }
      } catch (e) {
        if (selectedProjectData != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedProjectData = null;
            });
          });
        }
      }
    }
  }

  // Метод для проверки, содержится ли selectedProjectData в текущем списке
  ProjectTask? _getValidInitialItem(List<ProjectTask> projects) {
    if (selectedProjectData == null) return null;

    // Проверяем, содержится ли selectedProjectData в текущем списке проектов
    try {
      return projects.firstWhere((project) => project.id == selectedProjectData!.id);
    } catch (e) {
      // Если не найден, возвращаем null
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: widget.hasError ? 2 : (field.hasError ? 1 : 1),
                  color: widget.hasError ? Colors.red : (field.hasError ? Colors.red : Colors.white),
                ),
              ),
              child: BlocConsumer<GetTaskProjectBloc, GetTaskProjectState>(
                listener: (context, state) {
                  if (state is GetTaskProjectSuccess) {
                    // Загружаем все оставшиеся страницы сразу после первой загрузки
                    if (state.currentPage == 1 && !state.hasReachedMax && !_isLoadingMore) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _loadAllRemainingPages(state);
                      });
                    }
                  }
                },
                builder: (context, state) {
                  if (state is GetTaskProjectSuccess) {
                    projectsList = state.dataProject.result ?? [];

                    // Обрабатываем выбор проекта после завершения build
                    _handleProjectSelection(projectsList);
                  }

                  return CustomDropdown<ProjectTask>.search(
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
                      style: projectTextStyle.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF1E2E52),
                      ),
                    ),
                    excludeSelected: false,
                    initialItem: _getValidInitialItem(projectsList),
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
                  );
                },
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            // Не показываем дубль сообщения об ошибке:
            // если сработал validator (field.hasError) — он уже показал errorText.
            if (widget.hasError && !field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Text(
                  AppLocalizations.of(context)!.translate('field_required_project'),
                  style: const TextStyle(
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
}