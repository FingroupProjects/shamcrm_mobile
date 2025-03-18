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
  bool _isFetchingMore = false;
  final ApiService _apiService = ApiService();
  late TaskBloc _taskBloc;
  final ScrollController _scrollController = ScrollController();

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
    _taskBloc = TaskBloc(_apiService)..add(FetchTasks(widget.statusId));
    _checkPermission();
    _scrollController.addListener(_onScroll);

    _loadFeatureState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _initTutorialTargets();
      });
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
      // Если изменился статус, сбрасываем флаг пагинации и загружаем новые задачи
      _isFetchingMore = false;
      _taskBloc.add(FetchTasks(widget.statusId));
    }
  }

  @override
  void dispose() {
    _taskBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Если до конца списка осталось меньше 50 пикселей и пагинация не запущена
    if (_scrollController.position.extentAfter < 50) {
      final currentState = _taskBloc.state;
      if (currentState is TaskDataLoaded &&
          !currentState.allTasksFetched &&
          !_isFetchingMore) {
        _isFetchingMore = true;
        _taskBloc
            .add(FetchMoreTasks(widget.statusId, currentState.currentPage));
      }
    }
  }

  Future<void> _checkPermission() async {
    bool hasPermission = await _apiService.hasPermission('task.create');
    setState(() {
      _hasPermissionToAddTask = hasPermission;
    });
  }

  Future<void> _onRefresh() async {
    // При обновлении заново загружаем задачи и статусы
    BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses());
    _taskBloc.add(FetchTasks(widget.statusId));
    return Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _taskBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state is TaskLoading) {
              return const Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } else if (state is TaskDataLoaded) {
              final tasks = state.tasks
                  .where((task) => task.statusId == widget.statusId)
                  .toList();

              // Показываем подсказку для кнопки добавления, если карточек нет
              if (tasks.isEmpty &&
                  !_isFabTutorialShown &&
                  !_isTutorialInProgress) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showTutorial("TaskFloatingActionButton");
                });
              }

              // Показываем подсказку для карточки и статуса, если карточки есть
              if (tasks.isNotEmpty &&
                  !_isTaskCardTutorialShown &&
                  !_isStatusTutorialShown &&
                  !_isTutorialInProgress) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showTutorial("TaskCardAndStatusDropdown");
                });
              }

              if (tasks.isEmpty) {
                return RefreshIndicator(
                  backgroundColor: Colors.white,
                  color: Color(0xff1E2E52),
                  onRefresh: _onRefresh,
                  child: ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4),
                      Center(
                          child: Text(AppLocalizations.of(context)!
                              .translate('no_tasks_for_selected_status'))),
                    ],
                  ),
                );
              }

// if (!_isTaskCardTutorialShown && !_isStatusTutorialShown && !_isTutorialInProgress) {
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     showTutorial("TaskCardAndStatusDropdown");
//   });
// }

              return RefreshIndicator(
                color: Color(0xff1E2E52),
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                child: Column(
                  children: [
                    SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: TaskCard(
                              key: index == 0 ? keyTaskCard : null,
                              dropdownStatusKey:
                                  index == 0 ? keyStatusDropdown : null,
                              task: tasks[index],
                              name: widget.name,
                              statusId: widget.statusId,
                              onStatusUpdated: () {
                                _taskBloc.add(FetchTasks(widget.statusId));
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
            } else if (state is TaskError) {
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
                  ).then((_) => _taskBloc.add(FetchTasks(widget.statusId)));
                },
                backgroundColor: Color(0xff1E2E52),
                child: Image.asset('assets/icons/tabBar/add.png',
                    width: 24, height: 24),
              )
            : null,
      ),
    );
  }
}
