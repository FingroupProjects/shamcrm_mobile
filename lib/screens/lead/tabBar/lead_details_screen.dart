import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_event.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_state.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/leadById_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/history_dialog.dart';
import 'package:crm_task_manager/screens/lead/export_lead_to_contact.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_delete.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/contact_person_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/dropdown_history.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/dropdown_notes.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_deal_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_navigate_to_chat.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_to_1c.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_edit_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'dart:ui' as ui;
import 'package:url_launcher/url_launcher.dart';

class LeadDetailsScreen extends StatefulWidget {
  final String leadId;
  final String leadName;
  final String leadStatus;
  final int statusId;
  final String? region;
  final int? regionId;
  final String? sourse;
  final int? sourseId;
  final String? manager;
  final int? managerId;
  final String? birthday;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? phone;
  final String? description;

  LeadDetailsScreen({
    required this.leadId,
    required this.leadName,
    required this.leadStatus,
    required this.statusId,
    this.region,
    this.regionId,
    this.sourse,
    this.sourseId,
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
  LeadById? currentLead;
  bool _canEditLead = false;
  bool _canDeleteLead = false;
  bool _canReadNotes = false;
  bool _canReadDeal = false;
  bool _canExportContact = false;
  bool _isExportContactEnabled = false;


  final ApiService _apiService = ApiService();
  String? selectedOrganization;

  final GlobalKey keyLeadHistory = GlobalKey();
  final GlobalKey keyLeadEdit = GlobalKey();
  final GlobalKey keyLeadDelete = GlobalKey();
  final GlobalKey keyLeadNavigateChat = GlobalKey();
  final GlobalKey keyLeadNotice = GlobalKey();
  final GlobalKey keyLeadDeal = GlobalKey();
  final GlobalKey keyLeadContactPerson = GlobalKey();
  late ScrollController _scrollController;


  List<TargetFocus> targets = [];
  bool _isTutorialShown = false; 

  @override

  void initState() {
  super.initState();
   _scrollController = ScrollController(); 
  _checkPermissions();
    context.read<OrganizationBloc>().add(FetchOrganizations());
    _loadSelectedOrganization(); 
    context.read<LeadByIdBloc>().add(FetchLeadByIdEvent(leadId: int.parse(widget.leadId)));
  }

void _initTutorialTargets() {
  targets.addAll([
    createTarget(
      identify: "LeadHistory",
      keyTarget: keyLeadHistory,
      title: AppLocalizations.of(context)!.translate('tutorial_lead_details_history_title'),
      description: AppLocalizations.of(context)!.translate('tutorial_lead_details_history_description'),
      align: ContentAlign.bottom,
      context: context,
      contentPosition: ContentPosition.above,
    ),
  if (_canEditLead)
    createTarget(
      identify: "LeadEdit",
      keyTarget: keyLeadEdit,
      title: AppLocalizations.of(context)!.translate('tutorial_lead_details_edit_title'),
      description: AppLocalizations.of(context)!.translate('tutorial_lead_details_edit_description'),
      align: ContentAlign.bottom,
      context: context,
      contentPosition: ContentPosition.above,
    ),
  if (_canDeleteLead)
    createTarget(
      identify: "LeadDelete",
      keyTarget: keyLeadDelete,
      title: AppLocalizations.of(context)!.translate('tutorial_lead_details_delete_title'),
      description: AppLocalizations.of(context)!.translate('tutorial_lead_details_delete_description'),
      align: ContentAlign.bottom,
      context: context,
      contentPosition: ContentPosition.above,
    ),
    createTarget(
      identify: "keyNavigateChat",
      keyTarget: keyLeadNavigateChat,
      title: AppLocalizations.of(context)!.translate('tutorial_lead_details_chat_title'),
      description: AppLocalizations.of(context)!.translate('tutorial_lead_details_chat_description'),
      align: ContentAlign.top,
      extraSpacing: SizedBox(height: MediaQuery.of(context).size.height * 0.3),
      context: context,
    ),
  if (_canReadNotes)
    createTarget(
      identify: "keyLeadNotice",
      keyTarget: keyLeadNotice,
      title: AppLocalizations.of(context)!.translate('tutorial_lead_details_notice_title'),
      description: AppLocalizations.of(context)!.translate('tutorial_lead_details_notice_description'),
      align: ContentAlign.top,
      extraSpacing: SizedBox(height: MediaQuery.of(context).size.height * 0.2),
      context: context,
    ),
  if (_canReadDeal)
    createTarget(
      identify: "keyLeadDeal",
      keyTarget: keyLeadDeal,
      title: AppLocalizations.of(context)!.translate('tutorial_lead_details_deal_title'),
      description: AppLocalizations.of(context)!.translate('tutorial_lead_details_deal_description'),
      align: ContentAlign.top,
      extraSpacing: SizedBox(height: MediaQuery.of(context).size.height * 0.2),
      context: context,
    ),
    createTarget(
      identify: "keyLeadContactPerson",
      keyTarget: keyLeadContactPerson,
      title: AppLocalizations.of(context)!.translate('tutorial_lead_details_contact_title'),
      description: AppLocalizations.of(context)!.translate('tutorial_lead_details_contact_description'),
      align: ContentAlign.top,
      extraSpacing: SizedBox(height: MediaQuery.of(context).size.height * 0.2),
      context: context,
    ),
  ]);
}


void showTutorial() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isTutorialShown = prefs.getBool('isTutorialShownLeadDetails') ?? false;

  await Future.delayed(const Duration(milliseconds: 700));

  if (!isTutorialShown) {
    TutorialCoachMark(
      targets: targets,
      textSkip: AppLocalizations.of(context)!.translate('skip'),
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontFamily: 'Gilroy',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(offset: Offset(-1.5, -1.5),color: Colors.black),
          Shadow(offset: Offset(1.5, -1.5),color: Colors.black),
          Shadow(offset: Offset(1.5, 1.5),color: Colors.black),
          Shadow(offset: Offset(-1.5, 1.5),color: Colors.black),
        ],
      ),
      colorShadow: Color(0xff1E2E52),
      onClickTarget: (target) {
          if (target.identify == "keyNavigateChat") {
          _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      },
      onSkip: () {
        prefs.setBool('isTutorialShownLeadDetails', true);
        return true;
      },
      onFinish: () {
        prefs.setBool('isTutorialShownLeadDetails', true);
      },
    ).show(context: context);
  }

  
}

  // Метод для проверки разрешений
  Future<void> _checkPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final canEdit = await _apiService.hasPermission('lead.update');
    final canDelete = await _apiService.hasPermission('lead.delete');
    final canReadNotes = await _apiService.hasPermission('notice.read');
    final canReadDeal = await _apiService.hasPermission('deal.read');
    final canExportContact = await _apiService.hasPermission('lead.create');

    setState(() {
      _canEditLead = canEdit;
      _canDeleteLead = canDelete;
      _canReadNotes = canReadNotes;
      _canReadDeal = canReadDeal;
      _canExportContact = canExportContact;
      _isExportContactEnabled = prefs.getBool('switchContact') ?? false;
    });

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initTutorialTargets(); 
  });
  }

  // Обновление данных лида
  void _updateDetails(LeadById lead) {
    currentLead = lead; 
    details = [
      {
        'label': AppLocalizations.of(context)!.translate('name_details'),
        'value': lead.name
      },
      {
        'label': AppLocalizations.of(context)!.translate('phone_use'),
        'value': lead.phone ?? ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('region_details'),
        'value': lead.region?.name ?? ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('manager_details'),
        'value': lead.manager != null
            ? '${lead.manager!.name} ${lead.manager!.lastname ?? ''}'
            : AppLocalizations.of(context)!.translate('system_text'),
      },
      {
        'label': AppLocalizations.of(context)!.translate('source_details'),
        'value': lead.source?.name ?? ''
      },
      {'label': 'Instagram:', 'value': lead.instagram ?? ''},
      {'label': 'Facebook:', 'value': lead.facebook ?? ''},
      {'label': 'Telegram:', 'value': lead.telegram ?? ''},
      {'label': 'WhatsApp:', 'value': lead.whatsApp ?? ''},
      {
        'label': AppLocalizations.of(context)!.translate('email_details'),
        'value': lead.email ?? ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('birthday_details'),
        'value': formatDate(lead.birthday)
      },
      {
        'label': AppLocalizations.of(context)!.translate('description_details'),
        'value': lead.description ?? ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('author_details'),
        'value': lead.author?.name ?? ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('created_at_details'),
        'value': formatDate(lead.createdAt)
      },
      {
        'label': AppLocalizations.of(context)!.translate('status_details'),
        'value': lead.leadStatus?.title ?? ''
      },
    ];
    for (var field in lead.leadCustomFields) {
      details.add({'label': '${field.key}:', 'value': field.value});
    }
  }

  bool _isTextOverflow(String text, TextStyle style, double maxWidth) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
  }

  Widget _buildExpandableText(String label, String value, double maxWidth) {
    final TextStyle style = TextStyle(
      fontSize: 16,
      fontFamily: 'Gilroy',
      fontWeight: FontWeight.w500,
      color: Color(0xff1E2E52),
      backgroundColor: Colors.white,
    );

    return GestureDetector(
      onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
      child: Text(
        value,
        style: style.copyWith(
          decoration: TextDecoration.underline,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
             if (!_isTutorialShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showTutorial();
              setState(() {
                _isTutorialShown = true; 
              });
            });
          }
    return Scaffold(
        appBar: _buildAppBar(
        context, AppLocalizations.of(context)!.translate('view_lead')),
        backgroundColor: Colors.white,
        body: BlocListener<LeadByIdBloc, LeadByIdState>(
          listener: (context, state) {
            if (state is LeadByIdLoaded) {
            } else if (state is LeadByIdError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.translate(state.message), 
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
                    duration: Duration(seconds: 3),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView(
                    controller: _scrollController,
                    children: [
                      _buildDetailsList(),
                      const SizedBox(height: 8),
                      LeadNavigateToChat(
                        key: keyLeadNavigateChat,
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
                        NotesWidget(leadId: int.parse(widget.leadId), key: keyLeadNotice),
                      // const SizedBox(height: 16),
                      if (_canReadDeal)
                        DealsWidget(leadId: int.parse(widget.leadId), key: keyLeadDeal),
                      // const SizedBox(height: 16),
                      ContactPersonWidget(leadId: int.parse(widget.leadId), key: keyLeadContactPerson),
                    ],
                  ),
                );
              } else if (state is LeadByIdError) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate(state.message), 
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
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Transform.translate(
          offset: const Offset(0, -2),
          child: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () async {
              Navigator.pop(context, widget.statusId);
            },
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      actions: [
        IconButton(
          key: keyLeadHistory,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          icon: Icon(
            Icons.history, 
            size: 30,
            color: Color.fromARGB(224, 0, 0, 0),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => HistoryDialog(
                leadId: currentLead!.id,
              ),
            );
          },
        ),
        if (_canEditLead || _canDeleteLead)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canEditLead)
                IconButton(
                  key: keyLeadEdit,
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
                            sourceId: currentLead!.source != null
                                ? currentLead!.source!.id.toString()
                                : '',
                            region: currentLead!.region != null
                                ? currentLead!.region!.id.toString()
                                : '',
                            manager: currentLead!.manager != null
                                ? currentLead!.manager!.id.toString()
                                : '',
                            birthday: birthdayString,
                            createAt: createdAtString,
                            instagram: currentLead!.instagram,
                            facebook: currentLead!.facebook,
                            telegram: currentLead!.telegram,
                            phone: currentLead!.phone,
                            whatsApp: currentLead!.whatsApp,
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
                  key: keyLeadDelete,
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
 Future<void> _addContact(String name, String phone) async {
  showDialog(
    context: context,
    builder: (context) => ExportContactDialog(
      leadName: name,
      phoneNumber: phone,
    ),
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            SizedBox(width: 8),
            Expanded(
              child: (label.contains(
                          AppLocalizations.of(context)!.translate('lead')) ||
                      label.contains(AppLocalizations.of(context)!
                          .translate('description_list')))
                  ? _buildExpandableText(label, value, constraints.maxWidth)
                  : _buildValue(value,label),
            ),
          ],
        );
      },
    );
  }

  
  // Функция для форматирования даты
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('invalid_format');
    }
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

Widget _buildValue(String value, String label) {
  if (value.isEmpty) return Container();

  if (label == AppLocalizations.of(context)!.translate('phone_use')) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _makePhoneCall(value),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E2E52),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        if (_canExportContact && _isExportContactEnabled)
          GestureDetector(
            onTap: () => _addContact(widget.leadName, value),
            child: Icon(
              Icons.contacts,
              size: 24,
              color: Color(0xFF1E2E52),
            ),
          ),
      ],
    );
  }

  if (label == 'WhatsApp:') {
    return GestureDetector(
      onTap: () => _openWhatsApp(value),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E2E52),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  return Text(
    value,
    style: TextStyle(
      fontSize: 16,
      fontFamily: 'Gilroy',
      fontWeight: FontWeight.w500,
      color: Color(0xFF1E2E52),
    ),
    overflow: TextOverflow.visible,
  );
}

@override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(maxHeight: 400),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    textAlign: TextAlign.justify, // Выровнять текст по ширине
                    style: TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('close'),
                  onPressed: () => Navigator.pop(context),
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSelectedOrganization() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedOrganization = prefs.getString('selectedOrganization');
    });
  }

  // Добавьте эту функцию для совершения звонка
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // Убираем все не числовые символы из номера телефона
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Если номер начинается с '8', заменяем на '+7'
    if (cleanNumber.startsWith('8')) {
      cleanNumber = '+7${cleanNumber.substring(1)}';
    }
    // Если номер начинается с '7', добавляем '+'
    else if (cleanNumber.startsWith('7')) {
      cleanNumber = '+$cleanNumber';
    }

    try {
      Uri whatsappUri;
      if (Platform.isIOS) {
        // Для iOS используем другую схему URL
        whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
      } else {
        // Для Android оставляем прежнюю схему
        whatsappUri = Uri.parse('whatsapp://send?phone=$cleanNumber');
      }

      if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
        // Если не удалось открыть, показываем сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('whatsapp_not_installed'),
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
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Обработка ошибок
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('whatsapp_open_failed'),
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
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

