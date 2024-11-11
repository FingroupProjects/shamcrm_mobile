import 'package:crm_task_manager/bloc/history/history_bloc.dart';
import 'package:crm_task_manager/bloc/history/history_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/dropdown_history.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/dropdown_notes.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class LeadDetailsScreen extends StatefulWidget {
  final String leadId;
  String leadName;
  String leadStatus;
  int statusId;
  String? region;
  int? regionId;
  String? manager;
  int? managerId;
  String? birthday;
  String? instagram;
  String? facebook;
  String? telegram;
  String? phone;
  String? description;

  LeadDetailsScreen({
    required this.leadId,
    required this.leadName,
    required this.leadStatus,
    required this.statusId,
    this.region,
    this.regionId,
    this.manager,
    this.managerId,
    this.birthday,
    this.instagram,
    this.facebook,
    this.telegram,
    this.phone,
    this.description,
  });

  @override
  _LeadDetailsScreenState createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  List<Map<String, String>> details = [];

  @override
  void initState() {
    super.initState();
    _updateDetails();
  }

  void _updateDetails() {
    details = [
      {'label': 'ID лида:', 'value': widget.leadId},
      {'label': 'ФИО клиента:', 'value': widget.leadName},
      {'label': 'Статус:', 'value': widget.leadStatus},
      // {'label': 'СтатусID:', 'value': widget.statusId.toString()},
      {'label': 'Регион:', 'value': widget.region ?? 'Не указано'},
      {'label': 'Менеджер:', 'value': widget.manager ?? 'Не указано'},
      // {'label': 'ID региона:', 'value': widget.regionId?.toString() ?? 'Не указано'},
      {'label': 'Дата рождения:', 'value': widget.birthday ?? 'Не указано'},
      {'label': 'Instagram:', 'value': widget.instagram ?? 'Не указано'},
      {'label': 'Facebook:', 'value': widget.facebook ?? 'Не указано'},
      {'label': 'Telegram:', 'value': widget.telegram ?? 'Не указано'},
      {'label': 'Телефон:', 'value': widget.phone ?? 'Не указано'},
      {'label': 'Описание:', 'value': widget.description ?? 'Не указано'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) {
        if (state is LeadSuccess) {
          _updateDetails();
          setState(() {});
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context, 'Просмотр лида'),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              _buildDetailsList(),
              const SizedBox(height: 16),
              ActionHistoryWidget(leadId: int.parse(widget.leadId)),
              const SizedBox(height: 16),
              NotesWidget(leadId: int.parse(widget.leadId)),
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
                  final formattedBirthday =
                      (widget.birthday != null && widget.birthday!.isNotEmpty)
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(widget.birthday!))
                            : null;

                  final updatedLead = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeadEditScreen(
                        leadId: int.parse(widget.leadId),
                        leadName: widget.leadName,
                        leadStatus: widget.leadStatus,
                        statusId: widget.statusId,
                        region: widget.regionId?.toString(),
                        manager: widget.managerId?.toString(),
                        birthday: formattedBirthday,
                        instagram: widget.instagram,
                        facebook: widget.facebook,
                        telegram: widget.telegram,
                        phone: widget.phone,
                        description: widget.description,
                      ),
                    ),
                  );

                  if (updatedLead != null) {
                    context.read<LeadBloc>().add(FetchLeadStatuses());
                    context.read<HistoryBloc>().add(FetchLeadHistory(int.parse(widget.leadId)));
                    setState(() {
                      widget.leadName = updatedLead['leadName'];
                      widget.leadStatus = updatedLead['leadStatus'];
                      widget.statusId = updatedLead['statusId'];
                      widget.regionId = updatedLead['regionId'];
                      widget.managerId = updatedLead['managerId'];
                      widget.birthday = updatedLead['birthday'];
                      widget.instagram = updatedLead['instagram'];
                      widget.facebook = updatedLead['facebook'];
                      widget.telegram = updatedLead['telegram'];
                      widget.phone = updatedLead['phone'];
                      widget.description = updatedLead['description'];
                    });
                    _updateDetails();
                  }
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
