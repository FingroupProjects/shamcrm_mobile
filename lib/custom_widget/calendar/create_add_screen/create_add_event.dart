import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_event.dart';
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/custom_widget/calendar/create_add_screen/tematika_list.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/notice_sms_sample_model.dart';
import 'package:crm_task_manager/screens/event/event_details/Lead_Manager_Selector.dart';
import 'package:crm_task_manager/screens/event/event_details/notice_sms_template_section.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateEventFromCalendare extends StatefulWidget {
  final DateTime? initialDate;

  const CreateEventFromCalendare({Key? key, this.initialDate})
      : super(key: key);

  @override
  _CreateEventFromCalendareState createState() =>
      _CreateEventFromCalendareState();
}

class _CreateEventFromCalendareState extends State<CreateEventFromCalendare> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  String? selectedLead;
  String? selectedSubject;
  List<int> selectedManagers = [];
  String body = '';
  String date = '';
  bool sendNotification = false;
  bool sendSms = false;
  bool smsNoticeNotificationEnabled = false;
  bool _subjectError = false; // Переменная для отслеживания ошибки тематики
  List<NoticeSmsSample> smsTemplates = [NoticeSmsSample.empty()];
  NoticeSmsSample? selectedSmsTemplate;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      final now = DateTime.now();
      final combinedDateTime = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
        now.hour,
        now.minute,
      );
      date = DateFormat('dd/MM/yyyy HH:mm').format(combinedDateTime);
    } else {
      date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    }
    selectedSmsTemplate = smsTemplates.first;
    _loadSmsNoticeConfigFromCache();
    _loadSmsNoticeConfig();
  }

  Future<void> _loadSmsNoticeConfigFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('sms_notice_notification') ?? false;
    if (!mounted) return;
    setState(() {
      smsNoticeNotificationEnabled = isEnabled;
    });
  }

  Future<void> _loadSmsNoticeConfig() async {
    try {
      final settings = await _apiService.getSettings(null);
      final result = settings['result'] as Map<String, dynamic>?;
      final isEnabled = _toBool(result?['sms_notice_notification']);

      var templates = <NoticeSmsSample>[NoticeSmsSample.empty()];
      if (isEnabled) {
        final remoteTemplates = await _apiService.getNoticeSmsSamples();
        templates.addAll(remoteTemplates);
      }

      if (!mounted) return;
      setState(() {
        smsNoticeNotificationEnabled = isEnabled;
        smsTemplates = templates;
        selectedSmsTemplate ??= templates.first;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        smsNoticeNotificationEnabled = false;
        sendSms = false;
        smsTemplates = [NoticeSmsSample.empty()];
        selectedSmsTemplate = smsTemplates.first;
      });
    }
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  void _handleTemplateSelected(NoticeSmsSample template) {
    setState(() {
      selectedSmsTemplate = template;
      if (!template.isEmptyTemplate) {
        body = template.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        title: Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            AppLocalizations.of(context)!.translate('new_notice'),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Transform.translate(
            offset: const Offset(0, -2),
            child: IconButton(
              icon: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  colors.textPrimary,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/icons/arrow-left.png',
                  width: 24,
                  height: 24,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        leadingWidth: 40,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
          MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => GetAllLeadBloc()),
              BlocProvider(create: (_) => GetAllManagerBloc()),
            ],
            child: BlocListener<EventBloc, EventState>(
              listener: (context, state) {
                if (state is EventError) {
                  showCustomSnackBar(
                    context: context,
                    message:
                        AppLocalizations.of(context)!.translate(state.message),
                    isSuccess: false,
                  );
                } else if (state is EventSuccess) {
                  showCustomSnackBar(
                    context: context,
                    message:
                        AppLocalizations.of(context)!.translate(state.message),
                    isSuccess: true,
                  );
                  Navigator.pop(context);
                  context.read<CalendarBloc>().add(FetchCalendarEvents(
                      widget.initialDate?.month ?? DateTime.now().month,
                      widget.initialDate?.year ?? DateTime.now().year));
                }
              },
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                        },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TematikaListWidget(
                                selectedSubject: selectedSubject,
                                onSelectSubject: (String subject) {
                                  setState(() {
                                    selectedSubject = subject;
                                    if (subject.trim().isNotEmpty) {
                                      _subjectError = false;
                                    }
                                  });
                                },
                                hasError: _subjectError,
                              ),
                              const SizedBox(height: 8),
                              NoticeSmsTemplateSection(
                                isVisible: smsNoticeNotificationEnabled,
                                sendSms: sendSms,
                                templates: smsTemplates,
                                selectedTemplate: selectedSmsTemplate,
                                onToggle: (value) {
                                  setState(() {
                                    sendSms = value;
                                  });
                                },
                                onTemplateSelected: _handleTemplateSelected,
                              ),
                              const SizedBox(height: 8),
                              LeadManagerSelector(
                                onLeadSelected: (lead) {
                                  setState(() {
                                    selectedLead = lead.id.toString();
                                  });
                                },
                                onManagersSelected: (managers) {
                                  setState(() {
                                    selectedManagers = managers;
                                  });
                                },
                                onBodyChanged: (value) {
                                  setState(() {
                                    body = value;
                                  });
                                },
                                onDateChanged: (value) {
                                  setState(() {
                                    date = value;
                                  });
                                },
                                initialLeadId: selectedLead,
                                initialManagerIds: selectedManagers,
                                initialBody: body,
                                initialDate: date,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 30),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              buttonText: AppLocalizations.of(context)!
                                  .translate('cancel'),
                              buttonColor:
                                  colors.surfacePrimary.withValues(alpha: 0.72),
                              textColor: colors.textPrimary,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: BlocBuilder<EventBloc, EventState>(
                              builder: (context, state) {
                                if (state is EventLoading) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: colors.buttonPrimaryBg,
                                    ),
                                  );
                                }
                                return CustomButton(
                                  buttonText: AppLocalizations.of(context)!
                                      .translate('add'),
                                  buttonColor: colors.buttonPrimaryBg,
                                  textColor: colors.textInverse,
                                  onPressed: _submitForm,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && selectedLead != null) {
      DateTime? parsedDate;
      if (date.isNotEmpty) {
        parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(date);
      }
      if (selectedSubject == null || selectedSubject!.isEmpty) {
        setState(() {
          _subjectError =
              true; // Устанавливаем ошибку, если тематика не выбрана
        });
        showCustomSnackBar(
          context: context,
          message: AppLocalizations.of(context)!
              .translate('select_subject_required'),
          isSuccess: false,
        );
        return;
      }

      context.read<EventBloc>().add(
            CreateNotice(
              title: selectedSubject!.trim(),
              body: body,
              leadId: int.parse(selectedLead!),
              date: parsedDate,
              sendNotification: sendNotification ? 1 : 0,
              sendSms: sendSms ? 1 : 0,
              users: selectedManagers,
              localizations: AppLocalizations.of(context)!,
            ),
          );
    } else {
      setState(() {
        _subjectError = selectedSubject == null || selectedSubject!.isEmpty;
      });
      showCustomSnackBar(
        context: context,
        message:
            AppLocalizations.of(context)!.translate('fill_required_fields'),
        isSuccess: false,
      );
    }
  }
}
