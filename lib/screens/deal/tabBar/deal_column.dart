import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealColumn extends StatefulWidget {
  final int statusId;
  final String title;
  final Function(int) onStatusId; // Callback to notify status change

  DealColumn({
    required this.statusId,
    required this.title,
    required this.onStatusId,
  });

  @override
  _DealColumnState createState() => _DealColumnState();
}

class _DealColumnState extends State<DealColumn> {
  bool _canCreateDeal = false;
  final ApiService _apiService = ApiService();
  late DealBloc _dealBloc;

  @override
  void initState() {
    super.initState();
    _dealBloc = DealBloc(_apiService);
    _checkCreatePermission();
    _fetchDeals();
  }

  @override
  void didUpdateWidget(DealColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusId != widget.statusId) {
      _fetchDeals();
    }
  }

  @override
  void dispose() {
    _dealBloc.close();
    super.dispose();
  }

  Future<void> _checkCreatePermission() async {
    final canCreate = await _apiService.hasPermission('deal.create');
    setState(() {
      _canCreateDeal = canCreate;
    });
  }

  void _fetchDeals() {
    _dealBloc.add(FetchDeals(widget.statusId));
  }

  Future<void> _onRefresh() async {
    _fetchDeals();
    return Future.delayed(Duration(milliseconds: 1500));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dealBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<DealBloc, DealState>(
          builder: (context, state) {
            if (state is DealLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xff1E2E52)),
              );
            } else if (state is DealDataLoaded) {
              final deals = state.deals
                  .where((deal) => deal.statusId == widget.statusId)
                  .toList();

              return RefreshIndicator(
                color: Color(0xff1E2E52),
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                child: deals.isEmpty
                    ? ListView(
                        physics: AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4),
                          Center(
                              child: Text('Нет сделок для выбранного статуса')),
                        ],
                      )
                    : ListView.builder(
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: deals.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: DealCard(
                              deal: deals[index],
                              title: widget.title,
                              statusId: widget.statusId,
                              onStatusUpdated: _fetchDeals,
                              onStatusId: widget.onStatusId,
                            ),
                          );
                        },
                      ),
              );
            } else if (state is DealError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${state.message}',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 3),
                  ),
                );
              });
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4),
                    Center(child: Text(state.message)),
                  ],
                ),
              );
            }
            return Container();
          },
        ),
        floatingActionButton: _canCreateDeal
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DealAddScreen(statusId: widget.statusId),
                    ),
                  ).then((_) => _fetchDeals());
                },
                backgroundColor: Color(0xff1E2E52),
                child: Image.asset('assets/icons/tabBar/add.png',
                    width: 24, height: 24),
              )
            : null, // Кнопка не отображается, если нет прав
      ),
    );
  }
}
