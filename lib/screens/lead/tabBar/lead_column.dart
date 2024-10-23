import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_add_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadColumn extends StatelessWidget {
  final int statusId; 
  final String title;

  LeadColumn({required this.statusId, required this.title});

  @override
  Widget build(BuildContext context) {
  return BlocProvider(
    create: (context) => LeadBloc(ApiService())..add(FetchLeads(statusId)),
    child: Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          if (state is LeadLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xfff1E2E52)));
          } else if (state is LeadDataLoaded) {
            final leads = state.leads.where((lead) => lead.statusId == statusId).toList();

            if (leads.isEmpty) {
              return Center(child: Text('Нет лидов для выбранного статуса'));
            }
            // Добавляем ScrollController для отслеживания прокрутки
            final ScrollController _scrollController = ScrollController();
            _scrollController.addListener(() {
              // Проверка, загружаются ли лиды, и не закончились ли данные
              if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !context.read<LeadBloc>().allLeadsFetched) {
                context.read<LeadBloc>().add(FetchMoreLeads(statusId, state.currentPage));
              }
            });
            return Column(
              children: [
                SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController, // Устанавливаем контроллер
                    itemCount: leads.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: LeadCard(
                          lead: leads[index],
                          title: title,
                          onStatusUpdated: () {
                            context.read<LeadBloc>().add(FetchLeads(statusId));
                          },
                        )
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (state is LeadError) {
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
                builder: (context) => LeadAddScreen(statusId: statusId),
              ),
            );
          },
          backgroundColor: Color(0xff1E2E52),
          child: Image.asset('assets/icons/tabBar/add.png', width: 24, height: 24),
        ),
      ),
    );
  }
}
