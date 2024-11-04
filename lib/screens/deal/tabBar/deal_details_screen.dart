import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void initState() {
    super.initState();
    _updateDetails();
  }


  void _updateDetails() {
    details = [
      {'label': 'ID Сделки:', 'value': widget.dealId},
      {'label': 'Имя сделки:', 'value': widget.dealName},
      // {'label': 'Статус:', 'value': widget.dealStatus},
      // {'label': 'СтатусID:', 'value': widget.statusId.toString()},
      {'label': 'Менеджер:', 'value': widget.manager ?? 'Не указано'},
      {'label': 'Валюта:', 'value': widget.currency ?? 'Не указано'},
      {'label': 'Клиент:', 'value': widget.lead ?? 'Не указано'},
      {'label': 'Дата начало:', 'value': widget.startDate ?? 'Не указано'},
      {'label': 'Дата окончание:', 'value': widget.endDate ?? 'Не указано'},
      {'label': 'Сумма:', 'value': widget.sum ?? 'Не указано'},
      {'label': 'Описание:', 'value': widget.description ?? 'Не указано'},
    ];
      // Adding deal custom fields to details
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
                  // final formattedBirthday =
                  //     (widget.birthday != null && widget.birthday!.isNotEmpty)
                  //         ? DateFormat('dd/MM/yyyy')
                  //             .format(DateTime.parse(widget.birthday!))
                  //         : null;

                  // final updatedLead = await Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => DealEditScreen(
                  //       dealId: int.parse(widget.dealId),
                  //       leadName: widget.leadName,
                  //       leadStatus: widget.leadStatus,
                  //       statusId: widget.statusId,
                  //       region: widget.regionId?.toString(),
                  //       manager: widget.managerId?.toString(),
                  //       birthday: formattedBirthday,
                  //       instagram: widget.instagram,
                  //       facebook: widget.facebook,
                  //       telegram: widget.telegram,
                  //       phone: widget.phone,
                  //       description: widget.description,
                  //     ),
                  //   ),
                  // );

                  // if (updatedLead != null) {
                  //   context.read<DealBloc>().add(FetchDealStatuses());
                  //   // context.read<HistoryBloc>().add(FetchLeadHistory(int.parse(widget.leadId)));
                  //   setState(() {
                  //     widget.leadName = updatedLead['leadName'];
                  //     widget.leadStatus = updatedLead['leadStatus'];
                  //     widget.statusId = updatedLead['statusId'];
                  //     widget.regionId = updatedLead['regionId'];
                  //     widget.managerId = updatedLead['managerId'];
                  //     widget.birthday = updatedLead['birthday'];
                  //     widget.instagram = updatedLead['instagram'];
                  //     widget.facebook = updatedLead['facebook'];
                  //     widget.telegram = updatedLead['telegram'];
                  //     widget.phone = updatedLead['phone'];
                  //     widget.description = updatedLead['description'];
                  //   });
                  //   _updateDetails();
                  // }
                })),
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
