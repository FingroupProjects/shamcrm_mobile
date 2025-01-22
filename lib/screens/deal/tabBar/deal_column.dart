import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealColumn extends StatefulWidget {
  final int statusId;
  final String title;
  final Function(int) onStatusId;
  final int? managerId; // Добавляем параметр managerId

  DealColumn({
    required this.statusId,
    required this.title,
    required this.onStatusId,
    this.managerId, // Добавляем в конструктор
  });

  @override
  _DealColumnState createState() => _DealColumnState();
}

class _DealColumnState extends State<DealColumn> {
  bool _canCreateDeal = false;
  final ApiService _apiService = ApiService();
  late DealBloc _dealBloc;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _dealBloc = DealBloc(_apiService)..add(FetchDeals(widget.statusId));
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _checkCreatePermission();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dealBloc.close();
    super.dispose();
  }

  Future<void> _checkCreatePermission() async {
    final canCreate = await _apiService.hasPermission('deal.create');
    setState(() {
      _canCreateDeal = canCreate;
    });
  }

  Future<void> _onRefresh() async {
            BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());

    // final dealBloc = BlocProvider.of<DealBloc>(context);
    // dealBloc.add(FetchDealStatuses());

    _dealBloc.add(FetchDeals(widget.statusId));

    return Future.delayed(Duration(milliseconds: 1));
  }

 void _onScroll() {
  if (_scrollController.position.pixels ==
      _scrollController.position.maxScrollExtent) {
    final currentState = _dealBloc.state;
    if (currentState is DealDataLoaded) {
      final hasMoreDeals = currentState.deals.length < (currentState.dealCounts[widget.statusId] ?? 0);
      if (hasMoreDeals) {
        _dealBloc.add(FetchMoreDeals(widget.statusId, currentState.currentPage));
      }
    }
  }
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
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } else if (state is DealDataLoaded) {
              final deals = state.deals
                  .where((deal) => deal.statusId == widget.statusId)
                  .toList();
              if (deals.isEmpty) {
                return RefreshIndicator(
                  backgroundColor: Colors.white,
                  color: Color(0xff1E2E52),
                  onRefresh: _onRefresh,
                  child: ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4),
                      Center(child: Text(AppLocalizations.of(context)!.translate('no_deal_in_selected_status'))),
                    ],
                  ),
                );
              }

              final ScrollController _scrollController = ScrollController();
              _scrollController.addListener(() {
                if (_scrollController.position.pixels ==
                        _scrollController.position.maxScrollExtent &&
                    !_dealBloc.allDealsFetched) {
                  _dealBloc
                      .add(FetchMoreDeals(widget.statusId, state.currentPage));
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
                        itemCount: deals.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: DealCard(
                              deal: deals[index],
                              title: widget.title,
                              statusId: widget.statusId,
                              onStatusUpdated: () {
                                _dealBloc.add(FetchDeals(widget.statusId));
                              },
                              onStatusId: (StatusDealId) {
                                widget.onStatusId(StatusDealId);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is DealError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                  AppLocalizations.of(context)!.translate(state.message), // Локализация сообщения
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
        floatingActionButton: _canCreateDeal
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DealAddScreen(statusId: widget.statusId),
                    ),
                  ).then((_) => _dealBloc.add(FetchDeals(widget.statusId)));
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
