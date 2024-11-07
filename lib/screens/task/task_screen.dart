import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_status_add.dart';
import 'package:crm_task_manager/screens/task/task_details/task_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';

class TaskScreen extends StatefulWidget {
  final int? initialStatusId;

  TaskScreen({this.initialStatusId});
  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> _tabTitles = [];
  int _currentTabIndex = 0; // Track the current tab index

  @override
  void initState() {
    super.initState();
    final taskBloc = BlocProvider.of<TaskBloc>(context);
    taskBloc.add(FetchTaskStatuses());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 15),
          _buildCustomTabBar(),
          Expanded(child: _buildTabBarView()),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return _tabTitles.isNotEmpty
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...List.generate(_tabTitles.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildTabButton(index),
                  );
                }),
                IconButton(
                  icon: Image.asset('assets/icons/tabBar/add_black.png',
                      width: 24, height: 24),
                  onPressed: _addNewTab,
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  void _addNewTab() async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => CreateStatusDialog(),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _tabTitles.add(result);
      });
    }
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        decoration: TaskStyles.tabButtonDecoration(isActive),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Center(
          child: Text(
            _tabTitles[index],
            style: TaskStyles.tabTextStyle.copyWith(
              color:
                  isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskLoaded) {
          setState(() {
            _tabTitles =
                state.taskStatuses.map((status) => status.taskStatus.name).toList();
            _tabController =
                TabController(length: _tabTitles.length, vsync: this);
            _tabController.addListener(() {
              setState(() {
                _currentTabIndex = _tabController.index;
              });
            });

            int initialIndex = state.taskStatuses
                .indexWhere((status) => status.id == widget.initialStatusId);
            if (initialIndex != -1) {
              _tabController.index = initialIndex;
              _currentTabIndex = initialIndex;
            } else {
              _tabController.index = _currentTabIndex;
            }
          });
        }
      },
      child: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xff1E2E52)));
          } else if (state is TaskLoaded) {
            return _tabTitles.isNotEmpty
                ? TabBarView(
                    controller: _tabController,
                    children: List.generate(_tabTitles.length, (index) {
                      final taskStatus = state.taskStatuses[index];
                      final statusId = taskStatus.id;
                      final name = taskStatus.taskStatus.name;

                      return TaskColumn(statusId: statusId, name: name);
                    }),
                  )
                : const Center(child: Text('Нет статусов для отображения'));
          } else if (state is TaskError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
    );
  }
}
