import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_event.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_state.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_event.dart';
import 'package:crm_task_manager/models/leadById_model.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_delete.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/contact_person_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/dropdown_history.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/dropdown_notes.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_deal_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_navigate_to_chat.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_to_1c.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadDetailsScreen extends StatefulWidget {
  final String leadId;
  final String leadName;
  final String leadStatus;
  final int statusId;
  final String? region;
  final int? regionId;
  final String? manager;
  final int? managerId;
  final String? birthday;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? phone;
  final String? description;
  final List<LeadCustomField> leadCustomFields;

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
    required this.leadCustomFields,
  });

  @override
  _LeadDetailsScreenState createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  List<Map<String, String>> details = [];
  LeadById? currentLead;
  bool _canEditLead = false;
  bool _canDeleteLead = false;
  bool _canReadNotes = false;
  bool _canReadDeal = false;

  final ApiService _apiService = ApiService();
  String? selectedOrganization;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    // context.read<LeadBloc>().add(FetchLeads(widget.statusId));
    context.read<OrganizationBloc>().add(FetchOrganizations());

    _loadSelectedOrganization(); // Загружаем выбранную организацию

    context
        .read<LeadByIdBloc>()
        .add(FetchLeadByIdEvent(leadId: int.parse(widget.leadId)));
  }

  Future<void> _loadSelectedOrganization() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedOrganization = prefs.getString('selectedOrganization');
    });
  }

  // Метод для проверки разрешений
  Future<void> _checkPermissions() async {
    final canEdit = await _apiService.hasPermission('lead.update');
    final canDelete = await _apiService.hasPermission('lead.delete');
    final canReadNotes = await _apiService.hasPermission('notice.read');
    final canReadDeal = await _apiService.hasPermission('deal.read');

    setState(() {
      _canEditLead = canEdit;
      _canDeleteLead = canDelete;
      _canReadNotes = canReadNotes;
      _canReadDeal = canReadDeal;
    });
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

  // Обновление данных лида
  void _updateDetails(LeadById lead) {
    print('Lead author: ${lead.author?.name}'); // Добавьте вывод для отладки

    currentLead = lead; // Сохраняем актуального лида
    details = [
      // {'label': 'ID лида:', 'value': lead.id.toString()},
      {'label': 'Наименование лида :', 'value': lead.name},
      {'label': 'Статус:', 'value': lead.leadStatus?.title ?? 'Не указано'},
      {'label': 'Регион:', 'value': lead.region?.name ?? 'Не указано'},
      {'label': 'Менеджер:', 'value': lead.manager?.name ?? 'Не указано'},
      {'label': 'Дата рождения:', 'value': formatDate(lead.birthday)},
      {'label': 'Instagram:', 'value': lead.instagram ?? 'Не указано'},
      {'label': 'Facebook:', 'value': lead.facebook ?? 'Не указано'},
      {'label': 'Telegram:', 'value': lead.telegram ?? 'Не указано'},
      {'label': 'Телефон:', 'value': lead.phone ?? 'Не указано'},
      {'label': 'Email:', 'value': lead.email ?? 'Не указано'},
      {'label': 'Автор:', 'value': lead.author?.name ?? 'Не указано'},
      {'label': 'Источник:', 'value': lead.sourceLead?.name ?? 'Не указано'},
      {'label': 'Дата создания:', 'value': formatDate(lead.createdAt)},
      {'label': 'Описание:', 'value': lead.description ?? 'Не указано'},
    ];
    for (var field in lead.leadCustomFields) {
      details.add({'label': '${field.key}:', 'value': field.value});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(context, 'Просмотр лида'),
        backgroundColor: Colors.white,
        body: BlocListener<LeadByIdBloc, LeadByIdState>(
          listener: (context, state) {
            if (state is LeadByIdLoaded) {
              print("Лид Data: ${state.lead.toString()}");
            } else if (state is LeadByIdError) {
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
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 2),
                  ),
                );
              });
            }
          },
          child: BlocBuilder<LeadByIdBloc, LeadByIdState>(
            builder: (context, state) {
              if (state is LeadByIdLoading) {
                return Center(
                    child: CircularProgressIndicator(color: Color(0xff1E2E52)));
              } else if (state is LeadByIdLoaded) {
                LeadById lead = state.lead;
                _updateDetails(lead);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView(
                    children: [
                      _buildDetailsList(),
                      const SizedBox(height: 8),
                      LeadNavigateToChat(
                        leadId: int.parse(widget.leadId),
                        leadName: widget.leadName,
                      ),
                      const SizedBox(height: 8),
                      if (selectedOrganization != null)
                        LeadToC(
                          leadId: int.parse(widget.leadId),
                          selectedOrganization: selectedOrganization!,
                        ),
                      const SizedBox(height: 8),
                      ActionHistoryWidget(leadId: int.parse(widget.leadId)),
                      const SizedBox(height: 8),
                      if (_canReadNotes)
                        NotesWidget(leadId: int.parse(widget.leadId)),
                      // const SizedBox(height: 16),
                      if (_canReadDeal)
                        DealsWidget(leadId: int.parse(widget.leadId)),
                      // const SizedBox(height: 16),
                      ContactPersonWidget(leadId: int.parse(widget.leadId)),
                    ],
                  ),
                );
              } else if (state is LeadByIdError) {
                return Center(
                  child: Text(
                    '${state.message}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                );
              }
              return Center(child: Text(''));
            },
          ),
        ));
  }

  // Функция для построения AppBar
  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      centerTitle: false,
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
        if (_canEditLead || _canDeleteLead)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canEditLead)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Image.asset(
                    'assets/icons/edit.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () async {
                    if (currentLead != null) {
                      final birthdayString = currentLead!.birthday != null &&
                              currentLead!.birthday!.isNotEmpty
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(currentLead!.birthday!))
                          : null;
                      final createdAtString = currentLead!.createdAt != null &&
                              currentLead!.createdAt!.isNotEmpty
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(currentLead!.createdAt!))
                          : null;

                      final shouldUpdate = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeadEditScreen(
                            leadId: currentLead!.id,
                            leadName: currentLead!.name,
                            statusId: currentLead!.statusId,
                            region: currentLead!.region != null
                                ? currentLead!.region!.id.toString()
                                : 'Не указано',
                            manager: currentLead!.manager != null
                                ? currentLead!.manager!.id.toString()
                                : 'Не указано',
                            birthday: birthdayString,
                            createAt: createdAtString,
                            instagram: currentLead!.instagram,
                            facebook: currentLead!.facebook,
                            telegram: currentLead!.telegram,
                            phone: currentLead!.phone,
                            email: currentLead!.email,
                            description: currentLead!.description,
                            leadCustomFields: currentLead!.leadCustomFields,
                          ),
                        ),
                      );

                      if (shouldUpdate == true) {
                        // Перезагружаем данные лида
                        context.read<LeadByIdBloc>().add(FetchLeadByIdEvent(
                            leadId: int.parse(widget.leadId)));
                        context.read<LeadBloc>().add(FetchLeadStatuses());
                      }
                    }
                  },
                ),
              if (_canDeleteLead)
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
                      builder: (context) =>
                          DeleteLeadDialog(leadId: currentLead!.id),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }

  // Построение списка деталей лида
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

  // Построение одной строки с деталями лида
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
