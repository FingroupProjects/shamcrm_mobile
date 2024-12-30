import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_bloc.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_event.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_state.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_delete.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/dropdown_history.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/deal_task_screen.dart';
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
  final String? currency;
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
    this.currency,
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
  DealById? currentDeal;
  bool _canEditDeal = false;
  bool _canDeleteDeal = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    // context.read<DealBloc>().add(FetchDeals(widget.statusId));

    context
        .read<DealByIdBloc>()
        .add(FetchDealByIdEvent(dealId: int.parse(widget.dealId)));
  }

  Future<void> _checkPermissions() async {
    // Проверка прав на редактирование
    final canEdit = await _apiService.hasPermission('deal.update');
    final canDelete = await _apiService.hasPermission('deal.delete');

    setState(() {
      _canEditDeal = canEdit;
      _canDeleteDeal = canDelete;
    });
  }

  // Функция для форматирования даты
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Неверный формат';
    }
  }

  // Обновление данных сделки
  void _updateDetails(DealById deal) {
    currentDeal = deal; // Сохраняем актуальную сделку
    details = [
      // {'label': 'ID Сделки:', 'value': deal.id.toString()},
      {'label': 'Название сделки:', 'value': deal.name},
      {'label': 'Клиент:', 'value': deal.lead?.name ?? ''},
      {'label': 'Менеджер:', 'value': deal.manager?.name ?? ''},

      {'label': 'Дата начало:', 'value': formatDate(deal.startDate)},
      {'label': 'Дата завершения:', 'value': formatDate(deal.endDate)},
      {'label': 'Сумма:', 'value': deal.sum.toString()},
      {'label': 'Описание:', 'value': deal.description ?? ''},
      {'label': 'Автор:', 'value': deal.author?.name ?? ''},
      {'label': 'Дата создания:', 'value': formatDate(deal.createdAt)},
    ];

    for (var field in deal.dealCustomFields) {
      details.add({'label': '${field.key}:', 'value': field.value});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(context, 'Просмотр сделки'),
        backgroundColor: Colors.white,
        body: BlocListener<DealByIdBloc, DealByIdState>(
          listener: (context, state) {
            if (state is DealByIdLoaded) {
              print("Deal Data: ${state.deal.toString()}");
            } else if (state is DealByIdError) {
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
            }
          },
          child: BlocBuilder<DealByIdBloc, DealByIdState>(
            builder: (context, state) {
              if (state is DealByIdLoading) {
                return Center(
                    child: CircularProgressIndicator(color: Color(0xff1E2E52)));
              } else if (state is DealByIdLoaded) {
                DealById deal = state.deal;
                _updateDetails(deal);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ListView(
                    children: [
                      _buildDetailsList(),
                      const SizedBox(height: 8),
                      ActionHistoryWidget(dealId: int.parse(widget.dealId)),
                      const SizedBox(height: 16),
                      TasksWidget(dealId: int.parse(widget.dealId)),
                    ],
                  ),
                );
              } else if (state is DealByIdError) {
                return Center(child: Text('Ошибка: ${state.message}'));
              }
              return Center(child: Text(''));
            },
          ),
        ));
  }

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
        if (_canEditDeal || _canDeleteDeal)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canEditDeal)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
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
                      final createdAtDateString = currentDeal!.createdAt !=
                                  null &&
                              currentDeal!.createdAt!.isNotEmpty
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(currentDeal!.createdAt!))
                          : null;

                      final shouldUpdate = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DealEditScreen(
                            dealId: currentDeal!.id,
                            dealName: currentDeal!.name,
                            statusId: currentDeal!.statusId,
                            manager: currentDeal!.manager != null
                                ? currentDeal!.manager!.id.toString()
                                : '',
                            lead: currentDeal!.lead != null
                                ? currentDeal!.lead!.id.toString()
                                : '',
                            startDate: startDateString,
                            endDate: endDateString,
                            createdAt: createdAtDateString,
                            sum: currentDeal!.sum.toString(),
                            description:
                                currentDeal!.description ?? '',
                            dealCustomFields: currentDeal!.dealCustomFields,
                          ),
                        ),
                      );

                      if (shouldUpdate == true) {
                        context
                            .read<DealByIdBloc>()
                            .add(FetchDealByIdEvent(dealId: currentDeal!.id));
                        context.read<DealBloc>().add(FetchDealStatuses());
                      }
                    }
                  },
                ),
              if (_canDeleteDeal)
                IconButton(
                  padding: EdgeInsets.only(right: 8),
                  constraints: BoxConstraints(),
                  icon: Image.asset(
                    'assets/icons/delete.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => DeleteDealDialog(
                        dealId: currentDeal!.id,
                        leadId: currentDeal!.lead!.id,
                      ),
                    );
                  },
                ),
            ],
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
