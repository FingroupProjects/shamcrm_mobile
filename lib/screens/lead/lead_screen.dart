import 'package:crm_task_manager/screens/lead/tabBar/lead_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';

class LeadScreen extends StatefulWidget {
  @override
  _LeadScreenState createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> _tabTitles = [];

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
    return _tabTitles.isNotEmpty
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_tabTitles.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildTabButton(index),
                );
              }),
            ),
          )
        : const SizedBox();
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
              color: isActive ? TaskStyles.activeColor : TaskStyles.inactiveColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) {
        if (state is LeadLoaded) {
          setState(() {
            _tabTitles = state.leadStatuses.map((status) => status.title).toList();
            _tabController = TabController(length: _tabTitles.length, vsync: this);
            _tabController.addListener(() => setState(() {}));
          });
        }
      },
      child: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          if (state is LeadLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
          } else if (state is LeadLoaded) {
            return _tabTitles.isNotEmpty
                ? TabBarView(
                    controller: _tabController,
                    children: List.generate(_tabTitles.length, (index) {
                      final statusId = state.leadStatuses[index].id;
                      final title = state.leadStatuses[index].title;

                      return LeadColumn(statusId: statusId, title: title);
                    }),
                  )
                : const Center(child: Text('Нет статусов для отображения'));
          } else if (state is LeadError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
    );
  }
}
