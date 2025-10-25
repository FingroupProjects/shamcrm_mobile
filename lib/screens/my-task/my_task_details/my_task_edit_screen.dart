import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/models/my-taskbyId_model.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/mytask_status_list_edit.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
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
  final List<MyTaskFiles>? files; // вместо String? taskFile

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
  Map<String, Widget> fieldWidgets = {};
  List<String> fieldOrder = [];

  // Добавьте эти переменные в класс _MyTaskEditScreenState
  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  bool isEndDateInvalid = false;
  bool setPush = false;
  bool _showAdditionalFields = false;
  List<MyTaskFiles> existingFiles = []; // Для существующих файлов

  final ApiService _apiService = ApiService();
    int? _selectedStatuses;
      bool isSubmitted = false;



  @override
  void initState() {
    super.initState();
    
    // Загружаем конфигурацию после build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFieldConfiguration();
      }
    });
    
    _initializeControllers();
    _loadInitialData();

    // Инициализируем информацию о файле, если он есть
    if (widget.files != null) {
      existingFiles = widget.files!;
      fileNames = existingFiles.map((file) => file.name).toList();
    }
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
        FetchFieldConfiguration('tasks')  // Используем ту же конфигурацию что и для обычных задач
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
        
      case 'status_id':
        return MyTaskStatusEditWidget(
          selectedStatus: _selectedStatuses?.toString(),
          onSelectStatus: (MyTaskStatus selectedStatusData) {
            setState(() {
              _selectedStatuses = selectedStatusData.id;
            });
          },
          isSubmitted: isSubmitted,
        );
        
      case 'description':
        return CustomTextField(
          controller: descriptionController,
          hintText: AppLocalizations.of(context)!.translate('enter_description'),
          label: AppLocalizations.of(context)!.translate('description_list'),
          maxLines: 5,
          keyboardType: TextInputType.multiline,
        );
        
      case 'end_date':
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
        
      default:
        if (kDebugMode) {
          print('MyTaskEditScreen: Unknown field: ${config.fieldName}');
        }
        return null;
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


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Transform.translate(
          offset: const Offset(-10, 0),          child: Text(
            AppLocalizations.of(context)!.translate('task_edit'),
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
                    backgroundColor: Colors.green,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 3),
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
                      // Используем конфигурацию если загружена
                      if (isConfigurationLoaded && fieldWidgets.isNotEmpty) ...[
                        for (var fieldName in fieldOrder) ...[
                          fieldWidgets[fieldName]!,
                          const SizedBox(height: 8),
                        ],
                      ] else ...[
                        // Fallback: показываем все поля как раньше
                        CustomTextField(
                          controller: nameController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_title'),
                          label: AppLocalizations.of(context)!
                              .translate('event_name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .translate('field_required');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        MyTaskStatusEditWidget(
                          selectedStatus: _selectedStatuses?.toString(),
                          onSelectStatus: (MyTaskStatus selectedStatusData) {
                            setState(() {
                              _selectedStatuses = selectedStatusData.id;
                            });
                          },
                          isSubmitted: isSubmitted,
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: descriptionController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_description'),
                          label: AppLocalizations.of(context)!
                              .translate('description_list'),
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 8),
                        CustomTextFieldDate(
                          controller: endDateController,
                          label:
                              AppLocalizations.of(context)!.translate('deadline'),
                          hasError: isEndDateInvalid,
                        ),
                      ],
                      const SizedBox(height: 16),

                      if (!_showAdditionalFields)
                        CustomButton(
                          buttonText: AppLocalizations.of(context)!
                              .translate('additionally'),
                          buttonColor: Color(0xff1E2E52),
                          textColor: Colors.white,
                          onPressed: () {
                            setState(() {
                              _showAdditionalFields = true;
                            });
                          },
                        )
                      else ...[
                        // const SizedBox(height: 16),
                        _buildFileSelection(), // Добавляем виджет выбора файла
                        // _buildPushNotificationCheckbox(), // Add this line
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
                        buttonColor: const Color(0xffF4F7FD),
                        textColor: Colors.black,
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
                                color: Color(0xff1E2E52),
                              ),
                            );
                          } else {
                            return CustomButton(
                              buttonText: AppLocalizations.of(context)!
                                  .translate('save'),
                              buttonColor: const Color(0xff4759FF),
                              textColor: Colors.white,
                              onPressed: () {
                                setState(() {
                                    isSubmitted = true;
                                  });

                                if (_formKey.currentState!.validate()) {
                                  DateTime? startDate;
                                  DateTime? endDate;

                                  try {
                                    // if (startDateController.text.isNotEmpty) {
                                    //   startDate = DateFormat('dd/MM/yyyy')
                                    //       .parseStrict(
                                    //           startDateController.text);
                                    // }
                                    if (endDateController.text.isNotEmpty) {
                                      endDate = DateFormat('dd/MM/yyyy')
                                          .parseStrict(endDateController.text);
                                    }
                                    // if (startDate != null &&
                                    //     endDate != null &&
                                    //     startDate.isAfter(endDate)) {
                                    //   setState(() {
                                    //     isEndDateInvalid = true;
                                    //   });
                                    //   ScaffoldMessenger.of(context)
                                    //       .showSnackBar(
                                    //     SnackBar(
                                    //       content: Text(
                                    //         AppLocalizations.of(context)!
                                    //             .translate(
                                    //                 'start_date_after_end_date'),
                                    //         style: TextStyle(
                                    //           color: Colors.white,
                                    //         ),
                                    //       ),
                                    //       backgroundColor: Colors.red,
                                    //     ),
                                    //   );
                                    //   return;
                                    // }
                                    final localizations =
                                        AppLocalizations.of(context)!;
                                    context.read<MyTaskBloc>().add(
                                          UpdateMyTask(
                                            taskId: widget.taskId,
                                            name: nameController.text,
                                            taskStatusId: _selectedStatuses!.toInt(),
                                            // startDate: startDate,
                                            endDate: endDate,
                                            description:
                                                descriptionController.text,
                                            filePaths:
                                                selectedFiles, // Передаем список путей к файлам
                                            setPush: setPush, // Add this line
                                            localizations: localizations,
                                            existingFiles:
                                                existingFiles, // Добавляем существующие файлы
                                          ),
                                        );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(context)!
                                              .translate('error_format_date'),
                                        ),
                                        backgroundColor: Colors.red,
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
                                          color: Colors.white,
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.red,
                                      elevation: 3,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      duration: Duration(seconds: 3),
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
