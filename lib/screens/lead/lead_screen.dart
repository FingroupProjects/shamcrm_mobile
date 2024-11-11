import 'package:crm_task_manager/screens/lead/lead_status_delete.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_column.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_status_add.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';

class LeadScreen extends StatefulWidget {
  final int? initialStatusId;

  LeadScreen({this.initialStatusId});
  @override
  _LeadScreenState createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _tabTitles = []; // Store both ID and title

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    final leadBloc = BlocProvider.of<LeadBloc>(context);
    leadBloc.add(FetchLeadStatuses());
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
    return SingleChildScrollView(
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
            icon: Image.asset('assets/icons/tabBar/add_black.png', width: 24, height: 24),
            onPressed: _addNewTab,
          ),
        ],
      ),
    );
  }

  void _addNewTab() async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => CreateStatusDialog(),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _tabTitles.add({'id': _tabTitles.length + 1, 'title': result}); // Example: Add status with an ID
      });
    }
  }

  Widget _buildTabButton(int index) {
    bool isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      onLongPress: () {
        _showDeleteDialog(index);
      },
      child: Container(
        decoration: TaskStyles.tabButtonDecoration(isActive),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Center(
          child: Text(
            _tabTitles[index]['title'],
            style: TaskStyles.tabTextStyle.copyWith(
              color: isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(int index) async {
  final leadStatusId = _tabTitles[index]['id']; // Получаем ID удаляемого статуса

  final result = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return DeleteLeadStatusDialog(leadStatusId: leadStatusId); // Передаем ID в диалог
    },
  );

  if (result != null && result) {
    setState(() {
      _tabTitles.removeAt(index); // Удаляем статус из списка
      _tabController = TabController(length: _tabTitles.length, vsync: this); // Пересоздаем TabController
      _currentTabIndex = 0; // Возвращаемся к первому табу или вы можете установить другой индекс
    });
  }
}


  Widget _buildTabBarView() {
  return BlocListener<LeadBloc, LeadState>(
    listener: (context, state) {
      if (state is LeadLoaded) {
        setState(() {
          // Update the tab titles and reset the tab controller
          _tabTitles = state.leadStatuses
              .map((status) => {'id': status.id, 'title': status.title})
              .toList();

          // Reinitialize the tab controller only if the list is not empty
          if (_tabTitles.isNotEmpty) {
            _tabController = TabController(length: _tabTitles.length, vsync: this);
            _tabController.addListener(() {
              setState(() {
                _currentTabIndex = _tabController.index;
              });
            });

            int initialIndex = state.leadStatuses
                .indexWhere((status) => status.id == widget.initialStatusId);
            if (initialIndex != -1) {
              _tabController.index = initialIndex;
              _currentTabIndex = initialIndex;
            } else {
              _tabController.index = _currentTabIndex;
            }
          }
        });
      }
    },
    child: BlocBuilder<LeadBloc, LeadState>(
      builder: (context, state) {
        if (state is LeadLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
        } else if (state is LeadLoaded) {
          if (_tabTitles.isEmpty) {
            return const Center(child: Text('Нет статусов для отображения'));
          }
          return TabBarView(
            controller: _tabController,
            children: List.generate(_tabTitles.length, (index) {
              final statusId = _tabTitles[index]['id'];
              final title = _tabTitles[index]['title'];
              return LeadColumn(statusId: statusId, title: title);
            }),
          );
        } else if (state is LeadError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox();
      },
    ),
  );
}
}