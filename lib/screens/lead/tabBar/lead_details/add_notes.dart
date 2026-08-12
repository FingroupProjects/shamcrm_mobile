import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:crm_task_manager/bloc/notes/notes_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/event/notice_sms_sample_model.dart';
import 'package:crm_task_manager/screens/event/event_details/managers_event.dart';
import 'package:crm_task_manager/screens/event/event_details/notice_sms_template_section.dart';
import 'package:crm_task_manager/screens/event/event_details/notice_subject_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // Для File
import 'package:file_picker/file_picker.dart'; // Для FilePicker
import 'package:shared_preferences/shared_preferences.dart';

class CreateNotesDialog extends StatefulWidget {
  final int leadId;
  final int? managerId;
  final int? dealId;

  CreateNotesDialog({required this.leadId, this.managerId, this.dealId});

  @override
  _CreateNotesDialogState createState() => _CreateNotesDialogState();
}

class _CreateNotesDialogState extends State<CreateNotesDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  List<int> selectedManagers = [];
  String? selectedSubject;
  bool isSubjectInvalid = false;
  bool hasAutoSelectedManager = false;
  bool sendSms = false;
  bool smsNoticeNotificationEnabled = false;
  List<NoticeSmsSample> smsTemplates = [NoticeSmsSample.empty()];
  NoticeSmsSample? selectedSmsTemplate;
  // Переменные для файлов
  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];

  Color _screenPrimaryText(BuildContext context) =>
      context.appColors.textInverse.withValues(alpha: 0.96);
  Color _screenSecondaryText(BuildContext context) =>
      context.appColors.textInverse.withValues(alpha: 0.82);
  Color _screenHintText(BuildContext context) =>
      context.appColors.textInverse.withValues(alpha: 0.58);
  Color _screenBorder(BuildContext context) =>
      context.appColors.textInverse.withValues(alpha: 0.16);
  Color _screenFieldBackground(BuildContext context) =>
      context.appColors.surfaceElevated.withValues(alpha: 0.96);
  Color _screenSurfaceBackground(BuildContext context) =>
      context.appColors.surfacePrimary.withValues(alpha: 0.84);

  @override
  void initState() {
    super.initState();
    if (widget.managerId != null && !hasAutoSelectedManager) {
      selectedManagers = [widget.managerId!];
      hasAutoSelectedManager = true;
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
        bodyController.text = template.text;
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(allowMultiple: true);

      if (result != null) {
        double totalSize = selectedFiles.fold<double>(
          0.0,
          (sum, file) => sum + File(file).lengthSync() / (1024 * 1024), // MB
        );

        double newFilesSize = result.files.fold<double>(
          0.0,
          (sum, file) => sum + file.size / (1024 * 1024), // MB
        );

        if (totalSize + newFilesSize > 50) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('file_size_too_large'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.error,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        setState(() {
          for (var file in result.files) {
            selectedFiles.add(file.path!);
            fileNames.add(file.name);
            fileSizes.add('${(file.size / 1024).toStringAsFixed(3)}KB');
          }
        });
      }
    } catch (e) {
      ////print('Ошибка при выборе файла: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('error_file_pick'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appColors.textInverse,
            ),
          ),
          backgroundColor: context.appColors.error,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildFileSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('file'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: _screenPrimaryText(context),
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fileNames.isEmpty ? 1 : fileNames.length + 1,
            itemBuilder: (context, index) {
              if (fileNames.isEmpty || index == fileNames.length) {
                return Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: 100,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/icons/files/add_for_dark.png',
                            width: 60,
                            height: 60,
                          ),
                          SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.translate('add_file'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              color: _screenPrimaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final fileName = fileNames[index];
              final fileExtension = fileName.split('.').last.toLowerCase();

              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/icons/files/$fileExtension.png',
                            width: 60,
                            height: 60,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/icons/files/file.png',
                                width: 60,
                                height: 60,
                              );
                            },
                          ),
                          SizedBox(height: 8),
                          Text(
                            fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              color: _screenPrimaryText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -6,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFiles.removeAt(index);
                            fileNames.removeAt(index);
                            fileSizes.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: _screenPrimaryText(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotesBloc, NotesState>(
      listener: (context, state) {
        if (state is NotesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.error,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
        } else if (state is NotesSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.success,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true);
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
              decoration: BoxDecoration(
                color: _screenSurfaceBackground(context),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _screenBorder(context)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('add_note'),
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        color: _screenPrimaryText(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SubjectSelectionWidget(
                      selectedSubject: selectedSubject,
                      onSelectSubject: (String subject) {
                        setState(() {
                          selectedSubject = subject;
                          if (subject.trim().isNotEmpty) {
                            isSubjectInvalid = false;
                          }
                        });
                      },
                      hasError: isSubjectInvalid,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: bodyController,
                      backgroundColor: _screenFieldBackground(context),
                      textColor: _screenPrimaryText(context),
                      labelColor: _screenPrimaryText(context),
                      hintColor: _screenHintText(context),
                      borderColor: _screenBorder(context),
                      focusedBorderColor: context.appColors.buttonPrimaryBg,
                      hintText:
                          AppLocalizations.of(context)!.translate('enter_text'),
                      label: AppLocalizations.of(context)!
                          .translate('description_list'),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!
                              .translate('field_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    CustomTextFieldDate(
                      controller: dateController,
                      label:
                          AppLocalizations.of(context)!.translate('reminder'),
                      withTime: true,
                    ),
                    const SizedBox(height: 8),
                    ManagerMultiSelectWidget(
                      selectedManagers: selectedManagers,
                      onSelectManagers: (List<int> managers) {
                        setState(() {
                          selectedManagers = managers;
                          if (widget.managerId != null &&
                              !managers.contains(widget.managerId)) {
                            hasAutoSelectedManager = true;
                          }
                        });
                      },
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
                    _buildFileSelection(),
                    const SizedBox(height: 8),
                    CustomButton(
                      buttonText:
                          AppLocalizations.of(context)!.translate('save'),
                      onPressed: () {
                        final bool subjectMissing = selectedSubject == null ||
                            selectedSubject!.trim().isEmpty;
                        if (subjectMissing) {
                          setState(() {
                            isSubjectInvalid = true;
                          });
                        }

                        final bool formValid =
                            _formKey.currentState!.validate();
                        if (!formValid || subjectMissing) {
                          if (subjectMissing) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!
                                      .translate('select_subject'),
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: context.appColors.textInverse,
                                  ),
                                ),
                                backgroundColor: context.appColors.error,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                          return;
                        }

                        final String body = bodyController.text;
                        final String? dateString = dateController.text.isEmpty
                            ? null
                            : dateController.text;

                        DateTime? date;
                        if (dateString != null && dateString.isNotEmpty) {
                          try {
                            date = DateFormat('dd/MM/yyyy HH:mm')
                                .parse(dateString);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!
                                      .translate('enter_valid_datetime'),
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: context.appColors.textInverse,
                                  ),
                                ),
                                backgroundColor: context.appColors.error,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }
                        }

                        context.read<NotesBloc>().add(
                              CreateNotes(
                                leadId: widget.leadId,
                                dealId: widget.dealId,
                                title: selectedSubject!.trim(),
                                body: body,
                                date: date,
                                sendSms: sendSms ? 1 : 0,
                                users: selectedManagers,
                                filePaths: selectedFiles,
                              ),
                            );
                      },
                      buttonColor: context.appColors.buttonPrimaryBg,
                      textColor: context.appColors.buttonPrimaryFg,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
