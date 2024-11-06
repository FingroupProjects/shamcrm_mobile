import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_column.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_status_add.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';

class DealScreen extends StatefulWidget {
  final int? initialStatusId;

  DealScreen({this.initialStatusId});
  @override
  _DealScreenState createState() => _DealScreenState();
}

class _DealScreenState extends State<DealScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> _tabTitles = [];
  int _currentTabIndex = 0; // Track the current tab index

  @override
  void initState() {
    super.initState();
    final dealBloc = BlocProvider.of<DealBloc>(context);
    dealBloc.add(FetchDealStatuses());
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
        if (_tabTitles.isNotEmpty) 
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
  );
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
    return BlocListener<DealBloc, DealState>(
      listener: (context, state) {
        if (state is DealLoaded) {
          setState(() {
            _tabTitles =
                state.dealStatuses.map((status) => status.title).toList();
            _tabController =
                TabController(length: _tabTitles.length, vsync: this);
            _tabController.addListener(() {
              setState(() {
                _currentTabIndex =
                    _tabController.index; 
              });
            });

            int initialIndex = state.dealStatuses
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
      child: BlocBuilder<DealBloc, DealState>(
        builder: (context, state) {
          if (state is DealLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xff1E2E52)));
          } else if (state is DealLoaded) {
            return _tabTitles.isNotEmpty
                ? TabBarView(
                    controller: _tabController,
                    children: List.generate(_tabTitles.length, (index) {
                      final statusId = state.dealStatuses[index].id;
                      final title = state.dealStatuses[index].title;

                      return DealColumn(statusId: statusId, title: title);
                    }),
                  )
                : const Center(child: Text('Нет статусов для отображения'));
          } else if (state is DealError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
    );
  }
}
