import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_add_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadColumn extends StatefulWidget {
  final int statusId;
  final String title;
  final Function(int) onStatusId; // Callback to notify status change

  LeadColumn({
    required this.statusId,
    required this.title,
    required this.onStatusId,
  });

  @override
  _LeadColumnState createState() => _LeadColumnState();
}

class _LeadColumnState extends State<LeadColumn> {
  bool _hasPermissionToAddLead = false;
  final ApiService _apiService = ApiService();
  late final LeadBloc _leadBloc;

  @override
  void initState() {
    super.initState();
    _leadBloc = LeadBloc(_apiService)..add(FetchLeads(widget.statusId));
    _checkPermission();
  }

  @override
  void dispose() {
    _leadBloc.close();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    bool hasPermission = await _apiService.hasPermission('lead.create');
    setState(() {
      _hasPermissionToAddLead = hasPermission;
    });
  }

  Future<void> _onRefresh() async {

      final leadBloc = BlocProvider.of<LeadBloc>(context);
      leadBloc.add(FetchLeadStatuses());

    _leadBloc.add(FetchLeads(widget.statusId));

    return Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _leadBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<LeadBloc, LeadState>(
          builder: (context, state) {
            if (state is LeadLoading) {
             return const Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } else if (state is LeadDataLoaded) {
              final leads = state.leads
                  .where((lead) => lead.statusId == widget.statusId)
                  .toList();
              if (leads.isEmpty) {
                return RefreshIndicator(
                  backgroundColor: Colors.white,
                  color: Color(0xff1E2E52),
                  onRefresh: _onRefresh,
                  child: ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4),
                      Center(child: Text('Нет лидов для выбранного статуса')),
                    ],
                  ),
                );
              }

              final ScrollController _scrollController = ScrollController();
              _scrollController.addListener(() {
                if (_scrollController.position.pixels ==
                        _scrollController.position.maxScrollExtent &&
                    !_leadBloc.allLeadsFetched) {
                  _leadBloc
                      .add(FetchMoreLeads(widget.statusId, state.currentPage));
                }
              });

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
                        itemCount: leads.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: LeadCard(
                              lead: leads[index],
                              title: widget.title,
                              statusId: widget.statusId,
                              onStatusUpdated: () {
                                _leadBloc.add(FetchLeads(widget.statusId));
                              },
                              onStatusId: (StatusLeadId) {
                                widget.onStatusId(StatusLeadId);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is LeadError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${state.message}',
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
        floatingActionButton: _hasPermissionToAddLead
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LeadAddScreen(statusId: widget.statusId),
                    ),
                  ).then((_) => _leadBloc.add(FetchLeads(widget.statusId)));
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
