import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/event/event_by_Id_model.dart';
import 'package:crm_task_manager/models/event/notice_sms_sample_model.dart';
import 'package:crm_task_manager/screens/event/event_details/managers_event.dart';
import 'package:crm_task_manager/screens/event/event_details/notice_sms_template_section.dart';
import 'package:crm_task_manager/screens/event/event_details/notice_subject_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoticeEditScreen extends StatefulWidget {
  final Notice notice;

  const NoticeEditScreen({Key? key, required this.notice}) : super(key: key);

  @override
  _NoticeEditScreenState createState() => _NoticeEditScreenState();
}

class _NoticeEditScreenState extends State<NoticeEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late TextEditingController titleController;
  late TextEditingController bodyController;
  late TextEditingController dateController;

  String? selectedLead;
  List<int> selectedManagers = [];
  bool sendNotification = false;
  bool sendSms = false;
  bool smsNoticeNotificationEnabled = false;
  bool isLoading = false;
  String? selectedSubject;
  bool isSubjectInvalid = false; // Флаг для валидации тематики
  List<NoticeSmsSample> smsTemplates = [NoticeSmsSample.empty()];
  NoticeSmsSample? selectedSmsTemplate;

// Переменные для файлов
  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  List<NoticeFiles> existingFiles = []; // Для хранения файлов с сервера
  List<String> newFiles = []; // Новый список для хранения путей к новым файлам

  // ===== Цвета/темизация в стиле LeadAddScreen / NoticeAddScreen =====
  Color _screenPrimaryText(BuildContext context) =>
      context.appColors.textPrimary;
  Color _screenSecondaryText(BuildContext context) =>
      context.appColors.textSecondary;
  Color _screenHintText(BuildContext context) =>
      context.appColors.fieldHint;
  Color _screenBorder(BuildContext context) =>
      context.appColors.borderSubtle;
  Color _screenFocusBorder(BuildContext context) =>
      context.appColors.borderPrimary;
  Color _screenFieldBackground(BuildContext context) =>
      context.appColors.fieldBg;
  Color _screenSurfaceBackground(BuildContext context) =>
      context.appColors.surfacePrimary;
  Color _screenSurfaceElevated(BuildContext context) =>
      context.appColors.surfaceElevated;
  Color _screenFooterBackground(BuildContext context) =>
      context.appColors.surfacePrimary;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.notice.title);
    bodyController = TextEditingController(text: widget.notice.body);
    dateController = TextEditingController(
      text: widget.notice.date != null
          ? DateFormat('dd/MM/yyyy HH:mm')
              .format(widget.notice.date!.add(Duration(hours: 5)))
          : '',
    );

    selectedLead = widget.notice.lead?.id.toString();
    selectedManagers = widget.notice.users.map((user) => user.id).toList();
    selectedSubject = widget.notice.title;
    sendSms = widget.notice.sendSms;

// Инициализация файлов
    if (widget.notice.files != null) {
      existingFiles = widget.notice.files!;
      setState(() {
        fileNames.addAll(existingFiles.map((file) => file.name));
        fileSizes.addAll(existingFiles.map(
            (file) => '${(file.path.length / 1024).toStringAsFixed(3)}KB'));
        selectedFiles.addAll(existingFiles.map((file) => file.path));
      });
    }

    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
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

      NoticeSmsSample? matchedTemplate;
      for (final template in templates) {
        if (!template.isEmptyTemplate && template.text == bodyController.text) {
          matchedTemplate = template;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        smsNoticeNotificationEnabled = isEnabled;
        sendSms = isEnabled ? sendSms : false;
        smsTemplates = templates;
        selectedSmsTemplate =
            matchedTemplate ?? selectedSmsTemplate ?? templates.first;
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
    // Для лимита учитываем только новые локальные файлы
    double totalSize = 0.0;
    for (final filePath in newFiles) {
      try {
        totalSize += File(filePath).lengthSync() / (1024 * 1024);
      } catch (_) {
        // Игнорируем недоступные пути
      }
    }

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
      fileSizeTooLargeMessage:
          AppLocalizations.of(context)!.translate('file_size_too_large'),
      errorPickingFileMessage:
          AppLocalizations.of(context)!.translate('error_picking_file'),
    );

    // Если файлы выбраны, добавляем их
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          selectedFiles.add(file.path);
          newFiles.add(file.path);
          fileNames.add(file.name);
          fileSizes.add(file.sizeKB);
        }
      });
    }
  }

  /// Строит иконку файла или превью изображения (в стиле LeadAddScreen)
  Widget _buildFileIcon(int index, String fileExtension) {
    final fileTextColor = _screenPrimaryText(context);

    // Список расширений изображений
    final imageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'heic',
      'heif'
    ];

    final filePath = index < selectedFiles.length ? selectedFiles[index] : '';
    final normalizedPath = filePath.startsWith('file://')
        ? filePath.replaceFirst('file://', '')
        : filePath;
    final isLocalPath = normalizedPath.isNotEmpty &&
        (normalizedPath.startsWith('/') || normalizedPath.startsWith('./'));
    final localFile = File(normalizedPath);

    // Превью показываем только для локальных изображений.
    // Для серверных/удаленных файлов — иконка по расширению.
    if (imageExtensions.contains(fileExtension) &&
        isLocalPath &&
        localFile.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          localFile,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.insert_drive_file_rounded,
              size: 40,
              color: fileTextColor,
            );
          },
        ),
      );
    } else {
      // Для остальных типов файлов показываем иконку по расширению
      return Image.asset(
        'assets/icons/files/$fileExtension.png',
        width: 54,
        height: 54,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/icons/files/file.png',
            width: 54,
            height: 54,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.insert_drive_file_rounded,
                size: 40,
                color: fileTextColor,
              );
            },
          );
        },
      );
    }
  }

  Widget _buildFileSelection() {
    final fileCardColor = _screenFieldBackground(context);
    final fileTextColor = _screenPrimaryText(context);
    final fileBorderColor = _screenBorder(context);
    final addFileIconAsset =
        ThemeData.estimateBrightnessForColor(fileCardColor) == Brightness.dark
            ? 'assets/icons/files/add_for_dark.png'
            : 'assets/icons/files/add.png';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('file'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: fileTextColor,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: fileCardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: fileBorderColor,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(addFileIconAsset, width: 54, height: 54),
                          SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate('add_file'),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                color: fileTextColor,
                              ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: fileCardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: fileBorderColor,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Center(
                              child: _buildFileIcon(index, fileExtension),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              fileName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                color: fileTextColor,
                              ),
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
                          final removedPath = selectedFiles[index];
                          setState(() {
                            selectedFiles.removeAt(index);
                            fileNames.removeAt(index);
                            fileSizes.removeAt(index);
                            newFiles.remove(removedPath);
                            existingFiles.removeWhere(
                                (file) => file.path == removedPath);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.appColors.surfacePrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: context.appColors.shadow
                                    .withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.close,
                              size: 16, color: fileTextColor),
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
    final baseTheme = Theme.of(context);
    final baseColors = context.appColors;
    final baseTextStyles = context.appTextStyles;
    final baseShadows = context.appShadows;
    final screenTheme = baseTheme.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        baseColors.copyWith(
          surfacePrimary: _screenSurfaceBackground(context),
          surfaceElevated: _screenSurfaceElevated(context),
          textPrimary: _screenPrimaryText(context),
          textSecondary: _screenSecondaryText(context),
          textMuted: _screenHintText(context),
          textInverse: _screenPrimaryText(context),
          iconPrimary: _screenPrimaryText(context),
          iconSecondary: _screenSecondaryText(context),
          borderPrimary: _screenBorder(context),
          borderSubtle: _screenBorder(context),
          buttonSecondaryBg: _screenFieldBackground(context),
          buttonSecondaryFg: _screenPrimaryText(context),
          fieldBg: _screenFieldBackground(context),
          fieldBorder: _screenBorder(context),
          fieldHint: _screenHintText(context),
          overlay: baseColors.overlay,
        ),
        baseTextStyles.copyWith(
          titleLg: baseTextStyles.titleLg
              .copyWith(color: _screenPrimaryText(context)),
          titleMd: baseTextStyles.titleMd
              .copyWith(color: _screenPrimaryText(context)),
          bodyLg: baseTextStyles.bodyLg
              .copyWith(color: _screenPrimaryText(context)),
          bodyMd: baseTextStyles.bodyMd.copyWith(
            color: _screenSecondaryText(context),
          ),
          bodySm: baseTextStyles.bodySm.copyWith(
            color: _screenSecondaryText(context),
          ),
          labelLg: baseTextStyles.labelLg
              .copyWith(color: _screenPrimaryText(context)),
          labelMd: baseTextStyles.labelMd.copyWith(
            color: _screenSecondaryText(context),
          ),
          caption: baseTextStyles.caption
              .copyWith(color: _screenHintText(context)),
        ),
        baseShadows,
      ],
    );
    final appBarGradient = [
      _screenSurfaceElevated(context),
      _screenFieldBackground(context),
    ];
    final primaryText = _screenPrimaryText(context);
    final subtleBorder = _screenBorder(context);
    final formSurface = _screenSurfaceBackground(context);
    final footerSurface = _screenFooterBackground(context);

    return Theme(
      data: screenTheme,
      child: Scaffold(
        backgroundColor: context.appColors.overlay.withValues(alpha: 0),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          backgroundColor: context.appColors.overlay.withValues(alpha: 0),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: context.appColors.overlay.withValues(alpha: 0),
          shadowColor: context.appColors.overlay.withValues(alpha: 0),
          toolbarHeight: 74,
          titleSpacing: 16,
          title: AppBarShell(
            leading: AppBarShell.capsule(
              context,
              width: AppBarShell.orbSize,
              padding: EdgeInsets.zero,
              gradientColors: appBarGradient,
              borderColor: subtleBorder,
              child: IconButton(
                onPressed: () => Navigator.pop(context, null),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: primaryText,
                ),
              ),
            ),
            center: AppBarShell.capsule(
              context,
              gradientColors: appBarGradient,
              borderColor: subtleBorder,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.translate('edit_notice'),
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            // trailing: AppBarShell.capsule(
            //   context,
            //   width: AppBarShell.orbSize,
            //   padding: EdgeInsets.zero,
            //   gradientColors: appBarGradient,
            //   borderColor: subtleBorder,
            //   child: const SizedBox.shrink(),
            // ),
          ),
          centerTitle: false,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackgroundOverlay(
              preset: AppBackgroundPreset.aurora,
            ),
            BlocListener<EventBloc, EventState>(
              listener: (context, state) {
                if (state is EventUpdateError) {
                  setState(() {
                    isLoading = false; // Сбрасываем состояние загрузки
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!
                            .translate(state.message),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textInverse,
                        ),
                      ),
                      backgroundColor: context.appColors.error,
                      behavior: SnackBarBehavior.floating,
                      margin:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else if (state is EventUpdateSuccess) {
                  setState(() {
                    isLoading = false; // Сбрасываем состояние загрузки
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!
                            .translate(state.message),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textInverse,
                        ),
                      ),
                      backgroundColor: context.appColors.success,
                      behavior: SnackBarBehavior.floating,
                      margin:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  Navigator.pop(
                      context, true); // Закрываем экран после успешного обновления
                  context
                      .read<NotesBloc>()
                      .add(FetchNotes(widget.notice.lead!.id));
                }
              },
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).padding.top + 85,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                        },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding:
                                const EdgeInsets.fromLTRB(18, 18, 18, 22),
                            decoration: BoxDecoration(
                              color: formSurface,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: subtleBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: context.appColors.shadow
                                      .withValues(alpha: 0.14),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SubjectSelectionWidget(
                                  selectedSubject: selectedSubject,
                                  onSelectSubject: (String subject) {
                                    setState(() {
                                      selectedSubject = subject;
                                      isSubjectInvalid = subject
                                          .isEmpty; // Сбрасываем ошибку при вводе
                                    });
                                  },
                                  hasError:
                                      isSubjectInvalid, // Передаем флаг ошибки
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: bodyController,
                                  hintText: AppLocalizations.of(context)!
                                      .translate('description_list'),
                                  label: AppLocalizations.of(context)!
                                      .translate('description_list'),
                                  maxLines: 5,
                                  keyboardType: TextInputType.multiline,
                                  backgroundColor:
                                      _screenFieldBackground(context),
                                  labelColor: primaryText,
                                  hintColor: _screenHintText(context),
                                  textColor: primaryText,
                                  borderColor: subtleBorder,
                                  focusedBorderColor:
                                      _screenFocusBorder(context),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppLocalizations.of(context)!
                                          .translate('field_required');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextFieldDate(
                                  controller: dateController,
                                  label: AppLocalizations.of(context)!
                                      .translate('reminder_date'),
                                  withTime: true,
                                ),
                                const SizedBox(height: 16),
                                ManagerMultiSelectWidget(
                                  selectedManagers: selectedManagers,
                                  onSelectManagers: (List<int> managers) {
                                    setState(() {
                                      selectedManagers = managers;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
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
                                const SizedBox(height: 16),
                                _buildFileSelection(), // Добавляем выбор файлов
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: footerSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: subtleBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              buttonText: AppLocalizations.of(context)!
                                  .translate('cancel'),
                              buttonColor: _screenFieldBackground(context),
                              textColor: primaryText,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: BlocBuilder<EventBloc, EventState>(
                              builder: (context, state) {
                                if (isLoading) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: primaryText,
                                    ),
                                  );
                                }
                                return CustomButton(
                                  buttonText: AppLocalizations.of(context)!
                                      .translate('save'),
                                  buttonColor:
                                      context.appColors.buttonPrimaryBg,
                                  textColor:
                                      context.appColors.buttonPrimaryFg,
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
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // // Проверяем тематику
      if (selectedSubject == null || selectedSubject!.trim().isEmpty) {
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
        isLoading = true;
      });

      DateTime? date;
      if (dateController.text.isNotEmpty) {
        date = DateFormat('dd/MM/yyyy HH:mm').parse(dateController.text);
      }

      context.read<EventBloc>().add(
            UpdateNotice(
              noticeId: widget.notice.id,
              title: selectedSubject!.trim(),
              body: bodyController.text,
              leadId: int.parse(selectedLead!),
              date: date,
              sendNotification: sendNotification ? 1 : 0,
              sendSms: sendSms ? 1 : 0,
              users: selectedManagers,
              localizations: AppLocalizations.of(context)!,
              filePaths: newFiles, // Передаем новые файлы
              existingFiles: existingFiles, // Передаем существующие файлы
            ),
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('fill_required_fields'),
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
}
