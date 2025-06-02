import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_event.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_state.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/leadById_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/history_dialog.dart';
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
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
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
  StreamSubscription? _prefsSubscription;
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
  bool _isTutorialInProgress = false;
  Map<String, dynamic>? tutorialProgress;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _checkPermissions().then((_) {
      context.read<OrganizationBloc>().add(FetchOrganizations());
      _loadSelectedOrganization();
      context
          .read<LeadByIdBloc>()
          .add(FetchLeadByIdEvent(leadId: int.parse(widget.leadId)));
    });
    _fetchTutorialProgress();
    _listenToPrefsChanges(); 
  }

  Future<void> _listenToPrefsChanges() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _prefsSubscription =
        Stream.periodic(Duration(seconds: 1)).listen((_) async {
      bool newValue = prefs.getBool('switchContact') ?? false;
      if (newValue != _isExportContactEnabled) {
        setState(() {
          _isExportContactEnabled = newValue;
        });
      }
    });
  }

  Future<void> _fetchTutorialProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = await _apiService.getTutorialProgress();
      setState(() {
        tutorialProgress = progress['result'];
      });
      await prefs.setString('tutorial_progress', json.encode(progress['result']));
      bool isTutorialShown = prefs.getBool('isTutorialShownLeadDetails') ?? false;
      setState(() {
        _isTutorialShown = isTutorialShown;
      });
      _initTutorialTargets();
      if (tutorialProgress != null &&
          tutorialProgress!['leads']?['view'] == false &&
          !isTutorialShown &&
          !_isTutorialInProgress &&
          targets.isNotEmpty &&
          mounted) {
        showTutorial();
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final savedProgress = prefs.getString('tutorial_progress');
      if (savedProgress != null) {
        setState(() {
          tutorialProgress = json.decode(savedProgress);
        });
        bool isTutorialShown = prefs.getBool('isTutorialShownLeadDetails') ?? false;
        setState(() {
          _isTutorialShown = isTutorialShown;
        });
        _initTutorialTargets();
        if (tutorialProgress != null &&
            tutorialProgress!['leads']?['view'] == false &&
            !isTutorialShown &&
            !_isTutorialInProgress &&
            targets.isNotEmpty &&
            mounted) {
          showTutorial();
        }
      }
    }
  }

  @override
  void dispose() {
    _prefsSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _initTutorialTargets() {
    targets.clear();
    targets.addAll([
      createTarget(
        identify: "LeadHistory",
        keyTarget: keyLeadHistory,
        title: AppLocalizations.of(context)!
            .translate('tutorial_lead_details_history_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_lead_details_history_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      if (_canEditLead)
        createTarget(
          identify: "LeadEdit",
          keyTarget: keyLeadEdit,
          title: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_edit_title'),
          description: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_edit_description'),
          align: ContentAlign.bottom,
          context: context,
          contentPosition: ContentPosition.above,
        ),
      if (_canDeleteLead)
        createTarget(
          identify: "LeadDelete",
          keyTarget: keyLeadDelete,
          title: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_delete_title'),
          description: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_delete_description'),
          align: ContentAlign.bottom,
          context: context,
          contentPosition: ContentPosition.above,
        ),
      createTarget(
        identify: "keyNavigateChat",
        keyTarget: keyLeadNavigateChat,
        title: AppLocalizations.of(context)!
            .translate('tutorial_lead_details_chat_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_lead_details_chat_description'),
        align: ContentAlign.top,
        extraSpacing:
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
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
          title: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_deal_title'),
          description: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_deal_description'),
          align: ContentAlign.top,
          extraSpacing:
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          context: context,
        ),
      createTarget(
        identify: "keyLeadContactPerson",
        keyTarget: keyLeadContactPerson,
        title: AppLocalizations.of(context)!
            .translate('tutorial_lead_details_contact_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_lead_details_contact_description'),
        align: ContentAlign.top,
        extraSpacing:
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        context: context,
      ),
    ]);
  }

  void showTutorial() async {
    if (_isTutorialInProgress) {
      return;
    }

    if (targets.isEmpty) {
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShownLeadDetails') ?? false;

    if (tutorialProgress == null ||
        tutorialProgress!['leads']?['view'] == true ||
        isTutorialShown ||
        _isTutorialShown) {
      return;
    }

    setState(() {
      _isTutorialInProgress = true;
    });
    await Future.delayed(const Duration(milliseconds: 700));

    TutorialCoachMark(
      targets: targets,
      textSkip: AppLocalizations.of(context)!.translate('skip'),
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontFamily: 'Gilroy',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
          Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
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
        _apiService.markPageCompleted("leads", "view").catchError((e) {
        });
        setState(() {
          _isTutorialShown = true;
          _isTutorialInProgress = false;
        });
        return true;
      },
      onFinish: () {
        prefs.setBool('isTutorialShownLeadDetails', true);
        _apiService.markPageCompleted("leads", "view").catchError((e) {
        });
        setState(() {
          _isTutorialShown = true;
          _isTutorialInProgress = false;
        });
      },
    ).show(context: context);
  }

   Future<void> _checkPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('LeadDetailsScreen: Checking permissions');
    final canEdit = await _apiService.hasPermission('lead.update');
    final canDelete = await _apiService.hasPermission('lead.delete');
    final canReadNotes = await _apiService.hasPermission('notice.read');
    final canReadDeal = await _apiService.hasPermission('deal.read');
    final canExportContact = await _apiService.hasPermission('lead.create');
    print('LeadDetailsScreen: API Permissions - lead.update: $canEdit, lead.delete: $canDelete, notice.read: $canReadNotes, deal.read: $canReadDeal, lead.create: $canExportContact');
    
    setState(() {
      _canEditLead = canEdit;
      _canDeleteLead = canDelete;
      _canReadNotes = canReadNotes;
      _canReadDeal = canReadDeal;
      _canExportContact = canExportContact;
      _isExportContactEnabled = prefs.getBool('switchContact') ?? false;
    });
    print('LeadDetailsScreen: Permissions set - canEdit: $_canEditLead, canDelete: $_canDeleteLead, canReadNotes: $_canReadNotes, canReadDeal: $_canReadDeal, canExportContact: $_canExportContact, isExportContactEnabled: $_isExportContactEnabled');
  }

     void _updateDetails(LeadById lead) {
    print('LeadDetailsScreen: Updating details for lead: ${lead.id}');
    currentLead = lead;
    print('LeadDetailsScreen: Current lead set: ${lead.name}');
    print('LeadDetailsScreen: Directory values: ${lead.directoryValues}');
    print('LeadDetailsScreen: Phone value: ${lead.phone}');
    details = [
      {
        'label': AppLocalizations.of(context)!.translate('lead_name'), 
        'value': lead.name
      },
      {
        'label': AppLocalizations.of(context)!.translate('phone_use'), 
        'value': lead.phone ?? ''
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('region_details')}', 
        'value': lead.region?.name ?? ''
      },
      if (lead.manager != null)
        {
          'label': '${AppLocalizations.of(context)!.translate('manager_details')}', 
          'value': '${lead.manager!.name} ${lead.manager!.lastname ?? ''}'
        }
      else
        {
          'label': '',
          'value': 'become_manager'
        },
      {
        'label': '${AppLocalizations.of(context)!.translate('source_details')}', 
        'value': lead.source?.name ?? ''
      },
      {'label': 'Instagram:', 'value': lead.instagram ?? ''}, 
      {'label': 'Facebook:', 'value': lead.facebook ?? ''}, 
      {'label': 'Telegram:', 'value': lead.telegram ?? ''}, 
      {'label': 'WhatsApp:', 'value': lead.whatsApp ?? ''}, 
      {
        'label': '${AppLocalizations.of(context)!.translate('email_details')}',
        'value': lead.email ?? ''
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('birthday_details')}', 
        'value': formatDate(lead.birthday)
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('description_details_lead')}', 
        'value': lead.description ?? ''
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('author_details')}', 
        'value': lead.author?.name ?? ''
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('created_at_details')}',
        'value': formatDate(lead.createdAt)
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('status_details')}',
        'value': lead.leadStatus?.title ?? ''
      },
    ];
    print('LeadDetailsScreen: Initial details added: ${details.length} items');
    for (var field in lead.leadCustomFields) {
      print('LeadDetailsScreen: Adding custom field - key: ${field.key}, value: ${field.value}');
      details.add({'label': '${field.key}:', 'value': field.value}); 
    }
    for (var dirValue in lead.directoryValues) {
      final directoryName = dirValue.entry.directory.name;
      final value = dirValue.entry.values['value'] ?? '';
      print('LeadDetailsScreen: Adding directory - name: $directoryName, value: $value');
      details.add({'label': '$directoryName:', 'value': value});
    }
    print('LeadDetailsScreen: Final details list: ${details.length} items');
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
              showCustomSnackBar(
                context: context,
                message: AppLocalizations.of(context)!.translate(state.message),
                isSuccess: false,
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
                      NotesWidget(
                        leadId: int.parse(widget.leadId),
                        key: keyLeadNotice,
                        managerId: lead.manager?.id,
                      ),
                    if (_canReadDeal)
                      DealsWidget(
                          leadId: int.parse(widget.leadId), key: keyLeadDeal),
                    ContactPersonWidget(
                        leadId: int.parse(widget.leadId),
                        key: keyLeadContactPerson),
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
      ),
    );
  }

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
                            directoryValues: currentLead!.directoryValues,
                          ),
                        ),
                      );
                      if (shouldUpdate == true) {
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
                          .translate('description_details_lead')))
                  ? _buildExpandableText(label, value, constraints.maxWidth)
                  : _buildValue(value, label),
            ),
          ],
        );
      },
    );
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateString);
      final formatted = DateFormat('dd/MM/yyyy').format(parsedDate);
      return formatted;
    } catch (e) {
      return AppLocalizations.of(context)!.translate('invalid_format');
    }
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

Widget _buildValue(String value, String label) {
    if (value.isEmpty) {
      return Container();
    }

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

    if (label == '' && value == 'become_manager') {
      return Padding(
        padding: EdgeInsets.only(left: 0,),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.translate('manager_details')}  ',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w400,
                color: Color(0xfff99A4BA),
              ),
            ),
            GestureDetector(
              onTap: () {
                _assignManager();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  color: Color(0xff1E2E52),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.translate('become_manager'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // // Явная обработка справочников
    // if (label.contains('dilshod') ||
    //     label.contains('тест') ||
    //     label.contains('тет')) {
    //   print(
    //       'LeadDetailsScreen: Handling directory field - label: $label, value: $value');
    //   return _buildExpandableText(
    //       label, value, MediaQuery.of(context).size.width);
    // }

    // print(
    //     'LeadDetailsScreen: Default case for value - label: $label, value: $value');
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
  void _showFullTextDialog(String title, String content) {
    print(
        'LeadDetailsScreen: Showing full text dialog - title: $title, content: $content');
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
                    textAlign: TextAlign.justify,
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.startsWith('8')) {
      cleanNumber = '+7${cleanNumber.substring(1)}';
    } else if (cleanNumber.startsWith('7')) {
      cleanNumber = '+$cleanNumber';
    }

    try {
      Uri whatsappUri;
      if (Platform.isIOS) {
        whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
      } else {
        whatsappUri = Uri.parse('whatsapp://send?phone=$cleanNumber');
      }
      if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
        showCustomSnackBar(
          context: context,
          message:
              AppLocalizations.of(context)!.translate('whatsapp_not_installed'),
          isSuccess: false,
        );
      }
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message:
            AppLocalizations.of(context)!.translate('whatsapp_open_failed'),
        isSuccess: false,
      );
    }
  }

  Future<void> _assignManager() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.translate('confirm_manager_title'),
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E2E52),
              ),
            ),
          ),
          content: Text(
            AppLocalizations.of(context)!.translate('confirm_manager_message'),
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E2E52),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('no'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    buttonColor: Colors.red,
                    textColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('yes'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    buttonColor: Color(0xFF1E2E52),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    if (currentLead?.phone == null || currentLead!.phone!.isEmpty) {
      showCustomSnackBar(
        context: context,
        message: AppLocalizations.of(context)!.translate('phone_required'),
        isSuccess: false,
      );
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userID = prefs.getString('userID');
      if (userID == null || userID.isEmpty) {
        return;
      }
      int? parsedUserId = int.tryParse(userID);

      final completer = Completer<void>();
      final leadBloc = context.read<LeadBloc>();

      final listener = context.read<LeadBloc>().stream.listen((state) {
        if (state is LeadSuccess) {
          completer.complete();
        } else if (state is LeadError) {
          completer.completeError(Exception(state.message));
        }
      });

      final localizations = AppLocalizations.of(context)!;
      leadBloc.add(UpdateLead(
        leadId: currentLead!.id,
        name: currentLead!.name,
        phone: currentLead!.phone ?? "",
        managerId: parsedUserId,
        leadStatusId: currentLead?.leadStatus?.id ?? 0,
        localizations: localizations,
      ));

      await completer.future;
      listener.cancel();
      context.read<LeadByIdBloc>().add(FetchLeadByIdEvent(leadId: currentLead!.id));
      context.read<LeadBloc>().add(FetchLeadStatuses());
      showCustomSnackBar(
        context: context,
        message: AppLocalizations.of(context)!.translate('manager_assigned_success'),
        isSuccess: true,
      );
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: AppLocalizations.of(context)!.translate('manager_assign_failed'),
        isSuccess: false,
      );
    }
  }
}
