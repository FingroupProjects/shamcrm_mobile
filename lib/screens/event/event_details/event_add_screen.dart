import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/notice_sms_sample_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/event/event_details/managers_event.dart';
import 'package:crm_task_manager/screens/event/event_details/notice_sms_template_section.dart';
import 'package:crm_task_manager/screens/event/event_details/notice_subject_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // Добавляем для File
import '../../../custom_widget/custom_textfield_deadline.dart';

class NoticeAddScreen extends StatefulWidget {
  @override
  _NoticeAddScreenState createState() => _NoticeAddScreenState();
}

class _NoticeAddScreenState extends State<NoticeAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late final TextEditingController _bodyController;
  late final TextEditingController _dateController;
  String? selectedLead;
  String? selectedSubject;
  List<int> selectedManagers = [];
  String body = '';
  String date = '';
  bool sendNotification = false;
  bool sendSms = false;
  bool smsNoticeNotificationEnabled = false;
  bool isSubjectInvalid = false; // Флаг для валидации тематики
  List<NoticeSmsSample> smsTemplates = [NoticeSmsSample.empty()];
  NoticeSmsSample? selectedSmsTemplate;
  // Переменные для файлов
  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];

  @override
  void initState() {
    super.initState();
    _bodyController = TextEditingController();
    _dateController = TextEditingController();
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    selectedSmsTemplate = smsTemplates.first;
    _loadSmsNoticeConfigFromCache();
    _loadSmsNoticeConfig();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _dateController.dispose();
    super.dispose();
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
        _bodyController.text = template.text;
      }
    });
  }

  Future<void> _pickFile() async {
  // Вычисляем текущий общий размер файлов
  double totalSize = selectedFiles.fold<double>(
    0.0,
    (sum, file) => sum + File(file).lengthSync() / (1024 * 1024),
  );

  // Показываем диалог выбора типа файла
  final List<PickedFileInfo>? pickedFiles = await FilePickerDialog.show(
    context: context,
    allowMultiple: true,
    maxSizeMB: 50.0,
    currentTotalSizeMB: totalSize,
    fileLabel: AppLocalizations.of(context)!.translate('file'),
    galleryLabel: AppLocalizations.of(context)!.translate('gallery'),
    cameraLabel: AppLocalizations.of(context)!.translate('camera'),
    cancelLabel: AppLocalizations.of(context)!.translate('cancel'),
    fileSizeTooLargeMessage: AppLocalizations.of(context)!.translate('file_size_too_large'),
    errorPickingFileMessage: AppLocalizations.of(context)!.translate('error_picking_file'),
  );

  // Если файлы выбраны, добавляем их
  if (pickedFiles != null && pickedFiles.isNotEmpty) {
    setState(() {
      for (var file in pickedFiles) {
        selectedFiles.add(file.path);
        fileNames.add(file.name);
        fileSizes.add(file.sizeKB);
      }
    });
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
          color: Color(0xff1E2E52),
        ),
      ),
      SizedBox(height: 16),
      Container(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: fileNames.isEmpty ? 1 : fileNames.length + 1,
          itemBuilder: (context, index) {
            // Кнопка добавления файла
            if (fileNames.isEmpty || index == fileNames.length) {
              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: 100,
                    child: Column(
                      children: [
                        Image.asset('assets/icons/files/add.png', width: 60, height: 60),
                        SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.translate('add_file'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            
            // Отображение выбранных файлов
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
                        // НОВОЕ: Используем метод _buildFileIcon для показа превью или иконки
                        _buildFileIcon(fileName, fileExtension),
                        SizedBox(height: 8),
                        Text(
                          fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Кнопка удаления файла
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.close, size: 16, color: Color(0xff1E2E52)),
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

// ==========================================
// НОВЫЙ ВСПОМОГАТЕЛЬНЫЙ МЕТОД
// Добавьте этот метод в класс _DealAddScreenState
// ==========================================

/// Строит иконку файла или превью изображения
Widget _buildFileIcon(String fileName, String fileExtension) {
  // Список расширений изображений
  final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'];
  
  // Если файл - изображение, показываем превью
  if (imageExtensions.contains(fileExtension)) {
    final filePath = selectedFiles[fileNames.indexOf(fileName)];
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(filePath),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Если не удалось загрузить превью, показываем иконку
          return Image.asset(
            'assets/icons/files/file.png',
            width: 60,
            height: 60,
          );
        },
      ),
    );
  } else {
    // Для остальных типов файлов показываем иконку по расширению
    return Image.asset(
      'assets/icons/files/$fileExtension.png',
      width: 60,
      height: 60,
      errorBuilder: (context, error, stackTrace) {
        // Если нет иконки для этого типа, показываем общую иконку файла
        return Image.asset(
          'assets/icons/files/file.png',
          width: 60,
          height: 60,
        );
      },
    );
  }
}
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            AppLocalizations.of(context)!.translate('new_notice'),
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        centerTitle: false,
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        leadingWidth: 40,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => GetAllLeadBloc()),
          BlocProvider(create: (_) => GetAllManagerBloc()),
        ],
        child: BlocListener<EventBloc, EventState>(
          listener: (context, state) {
            if (state is EventError) {
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
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            } else if (state is EventSuccess) {
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
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              Navigator.pop(context);
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
                          // Lead selection
                          LeadRadioGroupWidget(
                            onSelectLead: (LeadData lead) {
                              setState(() {
                                selectedLead = lead.id.toString();
                              });
                            },
                            selectedLead: selectedLead,
                          ),
                          const SizedBox(height: 8),
                          // Description field
                          CustomTextField(
                            controller: _bodyController,
                            hintText: AppLocalizations.of(context)!
                                .translate('description_list'),
                            label: AppLocalizations.of(context)!
                                .translate('description_list'),
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!
                                    .translate('field_required');
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                body = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          // Date field
                          CustomTextFieldDate(
                            controller: _dateController,
                            label: AppLocalizations.of(context)!
                                .translate('reminder_date'),
                            withTime: true,
                            onDateSelected: (value) {
                              setState(() {
                                date = value;
                                _dateController.text = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          // Manager selection
                          ManagerMultiSelectWidget(
                            selectedManagers: selectedManagers,
                            onSelectManagers: (managers) {
                              setState(() {
                                selectedManagers = managers;
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
                          const SizedBox(height: 15),
                          _buildFileSelection(),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          buttonText:
                              AppLocalizations.of(context)!.translate('cancel'),
                          buttonColor: Color(0xffF4F7FD),
                          textColor: Colors.black,
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
                                  color: Color(0xff1E2E52),
                                ),
                              );
                            }
                            return CustomButton(
                              buttonText: AppLocalizations.of(context)!
                                  .translate('add'),
                              buttonColor: Color(0xff4759FF),
                              textColor: Colors.white,
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
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && selectedLead != null) {
      DateTime? parsedDate;
      final dateValue = _dateController.text.trim();
      if (dateValue.isNotEmpty) {
        try {
          parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(dateValue);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('enter_valid_datetime'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }
      }
      if (selectedSubject == null || selectedSubject!.isEmpty) {
        setState(() {
          isSubjectInvalid = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('select_subject'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      context.read<EventBloc>().add(
            CreateNotice(
              title: selectedSubject!.trim(),
              body: _bodyController.text.trim(),
              leadId: int.parse(selectedLead!),
              date: parsedDate,
              sendNotification: sendNotification ? 1 : 0,
              sendSms: sendSms ? 1 : 0,
              users: selectedManagers,
              filePaths: selectedFiles,
              localizations: AppLocalizations.of(context)!,
            ),
          );
    } else {
      if (selectedSubject == null || selectedSubject!.trim().isEmpty) {
        setState(() {
          isSubjectInvalid = true;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('fill_required_fields'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
