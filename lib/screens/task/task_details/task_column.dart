import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_add_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_card.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TaskColumn extends StatefulWidget {
  final int statusId;
  final String name;
  final Function(int) onStatusId;
  final int? userId; // Добавляем параметр managerId
  final bool isTaskScreenTutorialCompleted;

  TaskColumn({
    required this.statusId,
    required this.name,
    required this.onStatusId,
    this.userId,
    required this.isTaskScreenTutorialCompleted,
  });

  @override
  _TaskColumnState createState() => _TaskColumnState();
}

class _TaskColumnState extends State<TaskColumn> {
  bool _hasPermissionToAddTask = false;
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  bool _scrollListenerAdded = false;
  bool _isInitialLoad = true; // Флаг первой загрузки

  List<TargetFocus> targets = [];

  final GlobalKey keyTaskCard = GlobalKey();
  final GlobalKey keyStatusDropdown = GlobalKey();
  final GlobalKey keyFloatingActionButton = GlobalKey();

  bool _isTaskCardTutorialShown = false;
  bool _isStatusTutorialShown = false;
  bool _isFabTutorialShown = false;
  bool _isFabTutorialInProgress = false;
  bool _isTutorialInProgress = false;

  @override
  void initState() {
    super.initState();
    // ОПТИМИЗАЦИЯ: Не создаем новый блок, используем существующий из контекста
    _isInitialLoad = true; // Устанавливаем флаг первой загрузки
    
    // Загружаем разрешения асинхронно
    Future.microtask(() {
      if (mounted) {
        _checkPermission();
        _loadFeatureState();
        
        // КРИТИЧНО: Проверяем есть ли уже данные для этого статуса
        final taskBloc = context.read<TaskBloc>();
        if (taskBloc.state is TaskDataLoaded) {
          final currentState = taskBloc.state as TaskDataLoaded;
          final hasTasksForStatus = currentState.tasks.any((task) => task.statusId == widget.statusId);
          if (hasTasksForStatus) {
            // Если данные уже есть, сбрасываем флаг загрузки
            setState(() {
              _isInitialLoad = false;
            });
          } else {
            // Если данных нет, загружаем их
            taskBloc.add(FetchTasks(widget.statusId));
          }
        } else if (taskBloc.state is! TaskLoading) {
          // Если состояние не загрузка и не данные, загружаем задачи
          taskBloc.add(FetchTasks(widget.statusId));
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _initTutorialTargets();
        });
      }
    });
  }

  void _initTutorialTargets() {
    targets.addAll([
      createTarget(
        identify: "TaskCard",
        keyTarget: keyTaskCard,
        title:
            AppLocalizations.of(context)!.translate('tutorial_task_card_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_task_card_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.below,
        contentPadding: EdgeInsets.only(top: 50),
      ),
      createTarget(
        identify: "TaskFloatingActionButton",
        keyTarget: keyFloatingActionButton,
        title: AppLocalizations.of(context)!
            .translate('tutorial_task_button_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_task_button_description'),
        align: ContentAlign.top,
        context: context,
      ),
      createTarget(
        identify: "TaskStatusDropdown",
        keyTarget: keyStatusDropdown,
        title: AppLocalizations.of(context)!
            .translate('tutorial_task_status_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_task_status_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.below,
        contentPadding: EdgeInsets.only(top: 30),
      ),
    ]);
  }

  Future<void> _loadFeatureState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isTaskCardTutorialShown =
          prefs.getBool('isTaskCardTutorialShow') ?? false;
      _isStatusTutorialShown =
          prefs.getBool('isStatusTaskTutorialShown') ?? false;
      _isFabTutorialShown = prefs.getBool('isFabTaskTutorialShow') ?? false;
    });
  }

  void showTutorial(String tutorialType) async {
    if (_isTutorialInProgress) {
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (widget.isTaskScreenTutorialCompleted &&
        tutorialType == "TaskCardAndStatusDropdown" &&
        !_isTaskCardTutorialShown &&
        !_isStatusTutorialShown) {
      _isTutorialInProgress = true;

      await Future.delayed(const Duration(milliseconds: 500));

      TutorialCoachMark(
        targets: [
          targets.firstWhere((t) => t.identify == "TaskCard"),
          targets.firstWhere((t) => t.identify == "TaskStatusDropdown"),
        ],
        textSkip: AppLocalizations.of(context)!.translate('skip'),
        textStyleSkip: TextStyle(
          color: Colors.white,
          fontFamily: 'Gilroy',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
            Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
            Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
            Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
          ],
        ),
        colorShadow: Color(0xff1E2E52),
        onSkip: () {
          prefs.setBool('isTaskCardTutorialShow', true);
          prefs.setBool('isStatusTaskTutorialShown', true);
          setState(() {
            _isTaskCardTutorialShown = true;
            _isStatusTutorialShown = true;
            _isTutorialInProgress = false;
          });
          return true;
        },
        onFinish: () {
          prefs.setBool('isTaskCardTutorialShow', true);
          prefs.setBool('isStatusTaskTutorialShown', true);
          setState(() {
            _isTaskCardTutorialShown = true;
            _isStatusTutorialShown = true;
            _isTutorialInProgress = false;
          });
        },
      ).show(context: context);
    } else if (widget.isTaskScreenTutorialCompleted &&
        tutorialType == "TaskFloatingActionButton" &&
        !_isFabTutorialShown &&
        !_isFabTutorialInProgress) {
      _isTutorialInProgress = true;
      await Future.delayed(const Duration(milliseconds: 500));

      _isFabTutorialInProgress = true;
      TutorialCoachMark(
        targets: [
          targets.firstWhere((t) => t.identify == "TaskFloatingActionButton")
        ],
        textSkip: AppLocalizations.of(context)!.translate('skip'),
        textStyleSkip: TextStyle(
          color: Colors.white,
          fontFamily: 'Gilroy',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
            Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
            Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
            Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
          ],
        ),
        colorShadow: Color(0xff1E2E52),
        onSkip: () {
          prefs.setBool('isFabTaskTutorialShow', true);
          setState(() {
            _isFabTutorialShown = true;
            _isTutorialInProgress = false;
          });
          _isFabTutorialInProgress = false;
          return true;
        },
        onFinish: () {
          prefs.setBool('isFabTaskTutorialShow', true);
          setState(() {
            _isFabTutorialShown = true;
            _isTutorialInProgress = false;
          });
          _isFabTutorialInProgress = false;
        },
      ).show(context: context);
    }
  }

  @override
  void didUpdateWidget(TaskColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusId != widget.statusId) {
      _scrollListenerAdded = false;
      _isInitialLoad = true; // Сбрасываем флаг при смене статуса
      // ОПТИМИЗАЦИЯ: Используем блок из контекста вместо локального
      if (mounted) {
        context.read<TaskBloc>().add(FetchTasks(widget.statusId));
      }
    }
  }

  @override
  void dispose() {
    // ОПТИМИЗАЦИЯ: Не закрываем блок, т.к. он принадлежит родителю
    _scrollController.dispose();
    super.dispose();
  }


Future<void> _checkPermission() async {
  try {
    // ОПТИМИЗАЦИЯ: Параллельно проверяем оба разрешения с timeout
    final results = await Future.wait([
      _apiService.hasPermission('task.create'),
      _apiService.hasPermission('task.createForMySelf'),
    ]).timeout(
      Duration(seconds: 5),
      onTimeout: () => [false, false],
    );

    // Устанавливаем _hasPermissionToAddTask в true, если есть хотя бы одно разрешение
    if (mounted) {
      setState(() {
        _hasPermissionToAddTask = results[0] || results[1];
      });
    }
  } catch (e) {
    // Обработка ошибок при запросе к API
    if (mounted) {
      setState(() {
        _hasPermissionToAddTask = false; // В случае ошибки отключаем кнопку
      });
    }
  }
}
  Future<void> _onRefresh() async {
    // ОПТИМИЗАЦИЯ: При обновлении заново загружаем задачи и статусы из единого блока
    if (mounted) {
      final taskBloc = context.read<TaskBloc>();
      taskBloc.add(FetchTaskStatuses());
      taskBloc.add(FetchTasks(widget.statusId));
    }
    return Future.delayed(Duration(milliseconds: 100));
  }

   @override
  Widget build(BuildContext context) {
    // ОПТИМИЗАЦИЯ: Используем существующий блок из контекста, не создаем новый
    return Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            // Получаем блок из контекста
            final taskBloc = context.read<TaskBloc>();
            
            // ОПТИМИЗАЦИЯ: Проверяем наличие данных для текущего статуса
            bool hasDataForStatus = false;
            if (state is TaskDataLoaded) {
              hasDataForStatus = state.tasks.any((task) => task.statusId == widget.statusId);
            }
            
            // ОПТИМИЗАЦИЯ: Показываем лоадер только при реальной загрузке БЕЗ данных
            if (state is TaskLoading && _isInitialLoad && !hasDataForStatus) {
              return const Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } 
            
            if (state is TaskDataLoaded) {
              final tasks = state.tasks.where((task) => task.statusId == widget.statusId).toList();
              
              // КРИТИЧНО: Сбрасываем флаг сразу, как только получаем состояние с данными
              if (_isInitialLoad) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _isInitialLoad = false;
                    });
                  }
                });
              }

              if (tasks.isNotEmpty) {
                // ОПТИМИЗАЦИЯ: Используем один ScrollController для всего виджета
                if (!_scrollListenerAdded) {
                  _scrollListenerAdded = true;
                  _scrollController.addListener(() {
                    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
                        !taskBloc.allTasksFetched) {
                      taskBloc.add(FetchMoreTasks(widget.statusId, state.currentPage));
                    }
                  });
                }

                return RefreshIndicator(
                  color: Color(0xff1E2E52),
                  backgroundColor: Colors.white,
                  onRefresh: _onRefresh,
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: AlwaysScrollableScrollPhysics(),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            
                            if (index > 0 && tasks[index].id == tasks[index - 1].id) {
                                return SizedBox.shrink(); 
                              }
                              
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: TaskCard(
                                key: index == 0 ? keyTaskCard : null,
                                dropdownStatusKey: index == 0 ? keyStatusDropdown : null,
                                task: tasks[index],
                                name: widget.name,
                                statusId: widget.statusId,
                                onStatusUpdated: () {
                                  if (mounted) {
                                    taskBloc.add(FetchTasks(widget.statusId));
                                  }
                                },
                                onStatusId: (StatusTaskId) {
                                  widget.onStatusId(StatusTaskId);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // ИСПРАВЛЕНО: Показываем "Нет задач" сразу, т.к. флаг уже сброшен выше
                return RefreshIndicator(
                  backgroundColor: Colors.white,
                  color: Color(0xff1E2E52),
                  onRefresh: _onRefresh,
                  child: ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.translate('no_tasks_for_selected_status'),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Gilroy'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            } else if (state is TaskLoaded) {
              // Когда загружены статусы, но еще не задачи - загружаем задачи для текущего статуса
              if (_isInitialLoad) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.read<TaskBloc>().add(FetchTasks(widget.statusId));
                  }
                });
              }
              // Показываем лоадер пока загружаем задачи
              return const Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } else if (state is TaskError) {
              // Сбрасываем флаг загрузки при ошибке
              if (_isInitialLoad) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _isInitialLoad = false;
                    });
                  }
                });
              }
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        AppLocalizations.of(context)!
                            .translate(state.message), // Локализация сообщения
                        style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 3),
                  ),
                );
              });
              
              // Показываем пустой список при ошибке
              return RefreshIndicator(
                onRefresh: _onRefresh,
                color: Color(0xff1E2E52),
                backgroundColor: Colors.white,
                child: ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.translate('no_tasks_for_selected_status'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Gilroy'),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Для всех остальных состояний показываем лоадер только при первой загрузке
            if (_isInitialLoad) {
              return const Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            }
            
            return Container();
          },
        ),
        floatingActionButton: _hasPermissionToAddTask
            ? FloatingActionButton(
                key: keyFloatingActionButton,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TaskAddScreen(statusId: widget.statusId),
                    ),
                  ).then((_) {
                    if (mounted) {
                      context.read<TaskBloc>().add(FetchTasks(widget.statusId));
                    }
                  });
                },
                backgroundColor: Color(0xff1E2E52),
                child: Image.asset('assets/icons/tabBar/add.png',
                    width: 24, height: 24),
              )
            : null,
      );
  }
}
