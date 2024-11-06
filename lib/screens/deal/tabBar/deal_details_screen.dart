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
  String dealName;
  String? startDate;
  String? endDate;
  String sum;
  String dealStatus;
  int statusId;
  String? manager;
  int? managerId;
  String? currency;
  int? currencyId;
  String? lead;
  int? leadId;
  String? description;
  List<DealCustomField> dealCustomFields;

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

  @override
  void initState() {
    super.initState();
    _updateDetails();
  }

  void _updateDetails() {
    String formatDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return 'Не указано';
      try {
        final parsedDate = DateTime.parse(dateString);
        return DateFormat('dd/MM/yyyy').format(parsedDate);
      } catch (e) {
        return 'Неверный формат';
      }
    }

    details = [
      {'label': 'ID Сделки:', 'value': widget.dealId},
      {'label': 'Имя сделки:', 'value': widget.dealName},
      {'label': 'Менеджер:', 'value': widget.manager ?? 'Не указано'},
      {'label': 'Валюта:', 'value': widget.currency ?? 'Не указано'},
      {'label': 'Клиент:', 'value': widget.lead ?? 'Не указано'},
      {'label': 'Дата начала:', 'value': formatDate(widget.startDate)},
      {'label': 'Дата окончания:', 'value': formatDate(widget.endDate)},
      {'label': 'Сумма:', 'value': widget.sum ?? 'Не указано'},
      {'label': 'Описание:', 'value': widget.description ?? 'Не указано'},
    ];

    for (var field in widget.dealCustomFields) {
      details.add({'label': field.key, 'value': field.value});
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DealBloc, DealState>(
      listener: (context, state) {
        if (state is DealSuccess) {
          _updateDetails();
          setState(() {});
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context, 'Просмотр Сделки'),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              _buildDetailsList(),
              const SizedBox(height: 16),
              // ActionHistoryWidget(dealId: int.parse(widget.dealId)),
            ],
          ),
        ),
      ),
    );
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
          Navigator.pop(context);
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
                final startDateString =
                    widget.startDate != null && widget.startDate!.isNotEmpty
                        ? DateFormat('dd/MM/yyyy')
                            .format(DateTime.parse(widget.startDate!))
                        : null;
                final endDateString =
                    widget.endDate != null && widget.endDate!.isNotEmpty
                        ? DateFormat('dd/MM/yyyy')
                            .format(DateTime.parse(widget.endDate!))
                        : null;

                final updatedDeal = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DealEditScreen(
                      dealId: int.parse(widget.dealId),
                      dealName: widget.dealName,
                      dealStatus: widget.dealStatus,
                      statusId: widget.statusId,
                      manager: widget.managerId?.toString(),
                      currency: widget.currencyId?.toString(),
                      lead: widget.leadId?.toString(),
                      startDate: startDateString,
                      endDate: endDateString,
                      sum: widget.sum,
                      description: widget.description,
                      dealCustomFields: widget.dealCustomFields,
                    ),
                  ),
                );

                if (updatedDeal != null) {
                  context.read<DealBloc>().add(FetchDealStatuses());
                  setState(() {
                    widget.dealName = updatedDeal['dealName'];
                    widget.dealStatus = updatedDeal['dealStatus'];
                    widget.statusId = updatedDeal['statusId'];
                    widget.managerId = updatedDeal['managerId'];
                    widget.currencyId = updatedDeal['currencyId'];
                    widget.leadId = updatedDeal['leadId'];
                    widget.endDate = updatedDeal['endDate'];
                    widget.sum = updatedDeal['sum'];
                    widget.description = updatedDeal['description'];
                    widget.dealCustomFields = updatedDeal['customFields'];
                  });

                  _updateDetails();
                }
              }),
        ),
      ],
    );
  }

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
      // {'label': 'Статус:', 'value': widget.dealStatus},
      // {'label': 'СтатусID:', 'value': widget.statusId.toString()},