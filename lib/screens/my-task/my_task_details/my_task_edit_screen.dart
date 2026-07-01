import 'dart:io';

import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/models/my-taskbyId_model.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/mytask_status_list_edit.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';


class MyTaskEditScreen extends StatefulWidget {
  final int taskId;
  final String taskName;
  final String taskStatus;
  final int statusId;
  final String? startDate;
  final String? endDate;
  final String? description;
  final String? file;
  final List<MyTaskFiles>? files;

  MyTaskEditScreen({
    required this.taskId,
    required this.taskName,
    required this.taskStatus,
    required this.statusId,
    this.startDate,
    this.endDate,
    this.description,
    this.file,
    this.files,
  });

  @override
  _MyTaskEditScreenState createState() => _MyTaskEditScreenState();
}

class _MyTaskEditScreenState extends State<MyTaskEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Конфигурация полей
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;
  bool isConfigurationLoading = true; // НОВОЕ: флаг загрузки
  Map<String, Widget> fieldWidgets = {};
  List<String> fieldOrder = [];

  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  bool isEndDateInvalid = false;
  bool setPush = false;
  bool _showAdditionalFields = false;
  List<MyTaskFiles> existingFiles = [];

  int? _selectedStatuses;
  bool isSubmitted = false;

  @override
  void initState() {
    super.initState();
    
    _initializeControllers();
    _loadInitialData();

    // Инициализируем информацию о файле, если он есть
    if (widget.files != null) {
      existingFiles = widget.files!;
      fileNames = existingFiles.map((file) => file.name).toList();
    }
    
    // Загружаем конфигурацию сразу в initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFieldConfiguration();
      }
    });
  }

  void _initializeControllers() {
    nameController.text = widget.taskName;
    _selectedStatuses = widget.statusId;
    if (widget.startDate != null) {
      DateTime parsedStartDate = DateTime.parse(widget.startDate!);
      startDateController.text =
          DateFormat('dd/MM/yyyy').format(parsedStartDate);
    }
    if (widget.endDate != null) {
      DateTime parsedEndDate = DateTime.parse(widget.endDate!);
      endDateController.text = DateFormat('dd/MM/yyyy').format(parsedEndDate);
    }
    descriptionController.text = widget.description ?? '';
  }

  void _loadInitialData() {
    context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
  }

  Future<void> _loadFieldConfiguration() async {
    if (kDebugMode) {
      print('MyTaskEditScreen: Loading field configuration');
    }
    
    if (mounted) {
      context.read<FieldConfigurationBloc>().add(
        FetchFieldConfiguration('tasks')
      );
    }
  }

  void _buildFieldsFromConfiguration() {
    if (kDebugMode) {
      print('MyTaskEditScreen: Building fields from configuration with ${fieldConfigurations.length} fields');
    }
    
    fieldWidgets.clear();
    fieldOrder.clear();

    for (var config in fieldConfigurations) {
      if (!config.isActive) {
        if (kDebugMode) {
          print('MyTaskEditScreen: Skipping inactive field: ${config.fieldName}');
        }
        continue;
      }

      Widget? widget = _buildFieldWidget(config);
      if (widget != null) {
        fieldWidgets[config.fieldName] = widget;
        fieldOrder.add(config.fieldName);
        
        if (kDebugMode) {
          print('MyTaskEditScreen: Added field widget for: ${config.fieldName} at position ${config.position}');
        }
      }
    }
    
    if (kDebugMode) {
      print('MyTaskEditScreen: Total field widgets: ${fieldWidgets.length}');
    }
  }

  Widget? _buildFieldWidget(FieldConfiguration config) {
    switch (config.fieldName) {
      case 'name':
        return _buildNameField();
        
      case 'status_id':
        return _buildStatusField();
        
      case 'description':
        return _buildDescriptionField();
        
      case 'end_date':
        return _buildEndDateField();
        
      default:
        if (kDebugMode) {
          print('MyTaskEditScreen: Unknown field: ${config.fieldName}');
        }
        return null;
    }
  }

  // НОВЫЕ МЕТОДЫ: Выносим построение полей в отдельные методы
  // Это гарантирует единообразие и избавляет от дублирования
  
  Widget _buildNameField() {
    return CustomTextField(
      controller: nameController,
      hintText: AppLocalizations.of(context)!.translate('enter_title'),
      label: AppLocalizations.of(context)!.translate('event_name'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.translate('field_required');
        }
        return null;
      },
    );
  }

  Widget _buildStatusField() {
    return MyTaskStatusEditWidget(
      selectedStatus: _selectedStatuses?.toString(),
      onSelectStatus: (MyTaskStatus selectedStatusData) {
        setState(() {
          _selectedStatuses = selectedStatusData.id;
        });
      },
      isSubmitted: isSubmitted,
    );
  }

  Widget _buildDescriptionField() {
    return CustomTextField(
      controller: descriptionController,
      hintText: AppLocalizations.of(context)!.translate('enter_description'),
      label: AppLocalizations.of(context)!.translate('description_list'),
      maxLines: 5,
      keyboardType: TextInputType.multiline,
    );
  }

  Widget _buildEndDateField() {
    return CustomTextFieldDate(
      controller: endDateController,
      label: AppLocalizations.of(context)!.translate('deadline'),
      hasError: isEndDateInvalid,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.translate('field_required');
        }
        return null;
      },
    );
  }

  // КЛЮЧЕВОЙ МЕТОД: Построение всех обязательных полей
  // Независимо от конфигурации, эти поля ВСЕГДА должны быть
  List<Widget> _buildAllRequiredFields() {
    return [
      _buildNameField(),
      const SizedBox(height: 8),
      _buildStatusField(),
      const SizedBox(height: 8),
      _buildDescriptionField(),
      const SizedBox(height: 8),
      _buildEndDateField(),
    ];
  }

  Widget _buildFileSelection() {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addFileAsset =
        isDark ? 'assets/icons/files/add_for_dark.png' : 'assets/icons/files/add.png';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('file'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fileNames.isEmpty ? 1 : fileNames.length + 1,
            itemBuilder: (context, index) {
              // Кнопка добавления файла
              if (fileNames.isEmpty || index == fileNames.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _pickFile,
                    child: SizedBox(
                      width: 100,
                      child: Column(
                        children: [
                          Image.asset(addFileAsset, width: 60, height: 60),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.translate('add_file'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              color: colors.textPrimary,
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
                padding: const EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Column(
                        children: [
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
                              color: colors.textPrimary,
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
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.surfacePrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow.withValues(alpha: 0.14),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: colors.textPrimary,
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

  Widget _buildFileIcon(String fileName, String fileExtension) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'];
    
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
            return Image.asset(
              'assets/icons/files/file.png',
              width: 60,
              height: 60,
            );
          },
        ),
      );
    } else {
      return Image.asset(
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
      );
    }
  }

  Future<void> _pickFile() async {
    double totalSize = selectedFiles.fold<double>(
      0.0,
      (sum, file) => sum + File(file).lengthSync() / (1024 * 1024),
    );

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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundSecondary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.backgroundSecondary,
        elevation: 0,
        title: Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            AppLocalizations.of(context)!.translate('task_edit'),
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
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 22,
                color: colors.iconPrimary,
              ),
              onPressed: () => Navigator.pop(context, null),
            ),
          ),
        ),
        leadingWidth: 40,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MyTaskBloc, MyTaskState>(
            listener: (context, state) {
              if (state is MyTaskSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colors.buttonPrimaryFg,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: colors.success,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    duration: const Duration(seconds: 3),
                  ),
                );
                Navigator.pop(context, true);
              }
            },
          ),
          BlocListener<FieldConfigurationBloc, FieldConfigurationState>(
            listener: (context, configState) {
              if (kDebugMode) {
                print('MyTaskEditScreen: FieldConfigurationBloc state changed: ${configState.runtimeType}');
              }
              
              if (configState is FieldConfigurationLoaded) {
                if (kDebugMode) {
                  print('MyTaskEditScreen: Configuration loaded with ${configState.fields.length} fields');
                }
                
                if (mounted) {
                  setState(() {
                    fieldConfigurations = configState.fields;
                    isConfigurationLoaded = true;
                    isConfigurationLoading = false; // ВАЖНО: убираем флаг загрузки
                  });
                  
                  _buildFieldsFromConfiguration();
                }
              } else if (configState is FieldConfigurationError) {
                if (kDebugMode) {
                  print('MyTaskEditScreen: Configuration error: ${configState.message}');
                }
                
                if (mounted) {
                  setState(() {
                    isConfigurationLoaded = false;
                    isConfigurationLoading = false; // ВАЖНО: убираем флаг загрузки даже при ошибке
                  });
                }
              }
            },
          ),
        ],
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
                        // КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: Всегда показываем поля
                        // Независимо от состояния загрузки конфигурации
                        ..._buildAllRequiredFields(),
                        
                        const SizedBox(height: 16),

                        if (!_showAdditionalFields)
                          CustomButton(
                            buttonText: AppLocalizations.of(context)!
                                .translate('additionally'),
                            buttonColor: colors.buttonSecondaryBg,
                            textColor: colors.buttonSecondaryFg,
                            onPressed: () {
                              setState(() {
                                _showAdditionalFields = true;
                              });
                            },
                          )
                        else ...[
                          _buildFileSelection(),
                        ],
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
                        buttonColor: colors.buttonSecondaryBg,
                        textColor: colors.buttonSecondaryFg,
                        onPressed: () => Navigator.pop(context, null),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<MyTaskBloc, MyTaskState>(
                        builder: (context, state) {
                          if (state is MyTaskLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: colors.buttonPrimaryBg,
                              ),
                            );
                          } else {
                            return CustomButton(
                              buttonText: AppLocalizations.of(context)!
                                  .translate('save'),
                              buttonColor: colors.buttonPrimaryBg,
                              textColor: colors.buttonPrimaryFg,
                              onPressed: () {
                                setState(() {
                                  isSubmitted = true;
                                });

                                if (_formKey.currentState!.validate()) {
                                  DateTime? endDate;

                                  try {
                                    if (endDateController.text.isNotEmpty) {
                                      endDate = DateFormat('dd/MM/yyyy')
                                          .parseStrict(endDateController.text);
                                    }
                                    
                                    final localizations =
                                        AppLocalizations.of(context)!;
                                    context.read<MyTaskBloc>().add(
                                          UpdateMyTask(
                                            taskId: widget.taskId,
                                            name: nameController.text,
                                            taskStatusId: _selectedStatuses!.toInt(),
                                            endDate: endDate,
                                            description:
                                                descriptionController.text,
                                            filePaths: selectedFiles,
                                            setPush: setPush,
                                            localizations: localizations,
                                            existingFiles: existingFiles,
                                          ),
                                        );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(context)!
                                              .translate('error_format_date'),
                                          style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: colors.buttonPrimaryFg,
                                          ),
                                        ),
                                        backgroundColor: colors.error,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!
                                            .translate('fill_required_fields'),
                                        style: TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: colors.buttonPrimaryFg,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: colors.error,
                                      elevation: 3,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                            );
                          }
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
    );
  }
}
