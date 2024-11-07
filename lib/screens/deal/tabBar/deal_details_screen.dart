import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DealDetailsScreen extends StatefulWidget {
  final String dealId;
  final String dealName;
  final String? startDate;
  final String? endDate;
  final String sum;
  final String dealStatus;
  final int statusId;
  final String? manager;
  final int? managerId;
  final String? currency;
  final int? currencyId;
  final String? lead;
  final int? leadId;
  final String? description;
  final List<DealCustomField> dealCustomFields;

  DealDetailsScreen({
    required this.dealId,
    required this.dealName,
    this.startDate,
    this.endDate,
    required this.sum,
    required this.dealStatus,
    required this.statusId,
    this.manager,
    this.managerId,
    this.currency,
    this.currencyId,
    this.lead,
    this.leadId,
    this.description,
    required this.dealCustomFields,
  });

  @override
  _DealDetailsScreenState createState() => _DealDetailsScreenState();
}

class _DealDetailsScreenState extends State<DealDetailsScreen> {
  List<Map<String, String>> details = [];
  Deal? currentDeal; 

  @override
  void initState() {
    super.initState();
    context.read<DealBloc>().add(FetchDeals(widget.statusId));
  }

  // Функция для форматирования даты
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Не указано';
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Неверный формат';
    }
  }

  // Обновление данных сделки
  void _updateDetails(Deal deal) {
    currentDeal = deal; // Сохраняем актуальную сделку
    details = [
      {'label': 'ID Сделки:', 'value': deal.id.toString()},
      {'label': 'Имя сделки:', 'value': deal.name},
      {'label': 'Менеджер:', 'value': deal.manager?.name ?? 'Не указано'},
      {'label': 'Валюта:', 'value': deal.currency?.name ?? 'Не указано'},
      {'label': 'Клиент:', 'value': deal.lead?.name ?? 'Не указано'},
      {'label': 'Дата начала:', 'value': formatDate(deal.startDate)},
      {'label': 'Дата окончания:', 'value': formatDate(deal.endDate)},
      {'label': 'Сумма:', 'value': deal.sum.toString()},
      {'label': 'Описание:', 'value': deal.description ?? 'Не указано'},
    ];

    for (var field in deal.dealCustomFields) {
      details.add({'label': field.key, 'value': field.value});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context, 'Просмотр Сделки'),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<DealBloc, DealState>(
          builder: (context, state) {
            if (state is DealLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is DealDataLoaded) {
              Deal? deal;
              try {
                deal = state.deals.firstWhere(
                  (deal) => deal.id.toString() == widget.dealId,
                );
              } catch (e) {
                deal = null; 
              }

              if (deal != null) {
                _updateDetails(deal); 
              } else {
                return Center(child: Text('Сделка не найдена'));
              }
              return ListView(
                children: [
                  _buildDetailsList(),
                  const SizedBox(height: 16),
                ],
              );
            } else if (state is DealError) {
              return Center(child: Text('Ошибка: ${state.message}'));
            }
            return Center(child: Text('Неизвестное состояние'));
          },
        ),
      ),
    );
  }

  // Функция для построения AppBar
  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: Image.asset(
          'assets/icons/arrow-left.png',
          width: 24,
          height: 24,
        ),
        onPressed: () {
          Navigator.pop(context, widget.statusId);
          context.read<DealBloc>().add(FetchDealStatuses());
        },
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Image.asset(
              'assets/icons/edit.png',
              width: 24,
              height: 24,
            ),
            onPressed: () async {
              if (currentDeal != null) {
                final startDateString = currentDeal!.startDate != null &&
                        currentDeal!.startDate!.isNotEmpty
                    ? DateFormat('dd/MM/yyyy')
                        .format(DateTime.parse(currentDeal!.startDate!))
                    : null;
                final endDateString = currentDeal!.endDate != null &&
                        currentDeal!.endDate!.isNotEmpty
                    ? DateFormat('dd/MM/yyyy')
                        .format(DateTime.parse(currentDeal!.endDate!))
                    : null;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DealEditScreen(
                      dealId: currentDeal!.id, 
                      dealName: currentDeal!.name, 
                      // dealStatus: currentDeal!.dealStatus, // Передаем статус как строку
                      statusId: currentDeal!.statusId,
                      manager: currentDeal!.manager != null
                          ? currentDeal!.manager!.id.toString()
                          : 'Не указано', 
                      currency: currentDeal!.currency != null
                          ? currentDeal!.currency!.id.toString()
                          : 'Не указано',
                      lead: currentDeal!.lead != null
                          ? currentDeal!.lead!.id.toString()
                          : 'Не указано', 
                      startDate: startDateString, 
                      endDate: endDateString, 
                      sum: currentDeal!.sum.toString(), 
                      description: currentDeal!.description ??
                          'Не указано', 
                      dealCustomFields: currentDeal!
                          .dealCustomFields, 
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // Построение списка деталей сделки
  Widget _buildDetailsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildDetailItem(
            details[index]['label']!,
            details[index]['value']!,
          ),
        );
      },
    );
  }

  // Построение одной строки с деталями сделки
  Widget _buildDetailItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        SizedBox(width: 8),
        Expanded(
          child: _buildValue(value),
        ),
      ],
    );
  }

  // Построение метки
  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xfff99A4BA),
      ),
    );
  }

  // Построение значения
  Widget _buildValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xfff1E2E52),
      ),
      overflow: TextOverflow.visible,
    );
  }
}
