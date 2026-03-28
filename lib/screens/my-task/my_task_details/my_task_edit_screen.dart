import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/models/my-taskbyId_model.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/mytask_status_list_edit.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
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
                            'assets/icons/files/add.png',
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
                              color: Color(0xff1E2E52),
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
              final isExistingFile = index < existingFiles.length;

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
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -6,
                      child: GestureDetector(
                        onTap: () async {
                          if (isExistingFile) {
                            bool? confirmed = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: Center(
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .translate('delete_file'),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xff1E2E52),
                                      ),
                                    ),
                                  ),
                                  content: Text(
                                    AppLocalizations.of(context)!
                                        .translate('confirm_delete_file'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff1E2E52),
                                    ),
                                  ),
                                  actions: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: CustomButton(
                                            buttonText:
                                                AppLocalizations.of(context)!
                                                    .translate('cancel'),
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
                                            buttonText:
                                                AppLocalizations.of(context)!
                                                    .translate('unpin'),
                                            onPressed: () async {
                                              try {
                                                final result = await _apiService
                                                    .deleteTaskFile(
                                                        existingFiles[index]
                                                            .id);
                                                if (result['result'] ==
                                                    'Success') {
                                                  setState(() {
                                                    existingFiles
                                                        .removeAt(index);
                                                    fileNames.removeAt(index);
                                                  });
                                                  Navigator.of(context)
                                                      .pop(true);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .translate(
                                                                'file_deleted_successfully'),
                                                        style: TextStyle(
                                                          fontFamily: 'Gilroy',
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      margin:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 8),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                      elevation: 3,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 12,
                                                              horizontal: 16),
                                                      duration:
                                                          Duration(seconds: 3),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                Navigator.of(context)
                                                    .pop(false);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .translate(
                                                              'failed_to_delete_file'),
                                                      style: TextStyle(
                                                        fontFamily: 'Gilroy',
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    elevation: 3,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 12,
                                                            horizontal: 16),
                                                    duration:
                                                        Duration(seconds: 3),
                                                  ),
                                                );
                                              }
                                            },
                                            buttonColor: Color(0xff1E2E52),
                                            textColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            setState(() {
                              selectedFiles
                                  .removeAt(index - existingFiles.length);
                              fileNames.removeAt(index);
                              fileSizes.removeAt(index - existingFiles.length);
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xff1E2E52),
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
                                        AppLocalizations.of(context)!
                                            .translate('file_size_too_large'),
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
      //print('Ошибка при выборе файла!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ошибка при выборе файла!"),
          backgroundColor: Colors.red,
        ),
      );
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
      body: BlocListener<MyTaskBloc, MyTaskState>(
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
                duration: Duration(seconds: 3), // Установлено на 2 секунды
              ),
            );
            Navigator.pop(context, true);
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
                      // const SizedBox(height: 8),
                      // CustomTextFieldDate(
                      //   controller: startDateController,
                      //   label: AppLocalizations.of(context)!
                      //       .translate('from_list'),
                      //   // validator: (value) {
                      //   //   if (value == null || value.isEmpty) {
                      //   //     return AppLocalizations.of(context)!
                      //   //         .translate('field_required');
                      //   //   }
                      //   //   return null;
                      //   // },
                      // ),
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
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return AppLocalizations.of(context)!
                        //         .translate('field_required');
                        //   }
                        //   return null;
                        // },
                      ),
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
