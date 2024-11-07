import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealColumn extends StatelessWidget {
  final int statusId;
  final String title;

  DealColumn({required this.statusId, required this.title});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DealBloc(ApiService())..add(FetchDeals(statusId)),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<DealBloc, DealState>(
          builder: (context, state) {
            if (state is DealLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xfff1E2E52)));
            } else if (state is DealDataLoaded) {
              final deals = state.deals
                  .where((deal) => deal.statusId == statusId)
                  .toList();
              if (deals.isEmpty) {
                return Center(child: Text('Нет сделок для выбранного статуса'));
              }
              // Добавляем ScrollController для отслеживания прокрутки
              final ScrollController _scrollController = ScrollController();
              _scrollController.addListener(() {
                // Проверка, загружаются ли лиды, и не закончились ли данные
                if (_scrollController.position.pixels ==
                        _scrollController.position.maxScrollExtent &&
                    !context.read<DealBloc>().allDealsFetched) {
                  context.read<DealBloc>().add(FetchMoreDeals(statusId, state.currentPage));
                }
              });
              return Column(
                children: [
                  SizedBox(height: 15),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: deals.length,
                      itemBuilder: (context, index) {
                        return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: DealCard(
                              deal: deals[index],
                              title: title,
                              statusId: statusId,
                              onStatusUpdated: () {
                                context
                                    .read<DealBloc>()
                                    .add(FetchDeals(statusId));
                              },
                            )
                            );
                      },
                    ),
                  ),
                ],
              );
            } else if (state is DealError) {
              return Center(child: Text('Ошибка: ${state.message}'));
            }
            return Container();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DealAddScreen(statusId: statusId),
              ),
            );
          },
          backgroundColor: Color(0xff1E2E52),
          child:
              Image.asset('assets/icons/tabBar/add.png', width: 24, height: 24),
        ),
      ),
    );
  }
}
