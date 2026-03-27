import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_event.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_bloc.dart';
import 'package:crm_task_manager/bloc/project_task/project_task_event.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_withPriority.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/file_helper.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list_task.dart';
import 'package:crm_task_manager/screens/task/task_details/status_list.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:intl/intl.dart';

class CreateTaskFromCalendare extends StatefulWidget {
  final DateTime? initialDate;

  const CreateTaskFromCalendare({
    Key? key,
    this.initialDate,
  }) : super(key: key);

  @override
  _CreateTaskFromCalendareState createState() => _CreateTaskFromCalendareState();
}


class _CreateTaskFromCalendareState extends State<CreateTaskFromCalendare> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  int? selectedPriority;
  String? selectedProject;
  int? selectedStatusId;
  List<String>? selectedUsers;
  List<CustomField> customFields = [];
  bool isEndDateInvalid = false;
  bool _showAdditionalFields = false;

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetTaskProjectBloc>().add(GetTaskProjectEv());
    context.read<UserTaskBloc>().add(FetchUsers());
    _fetchAndAddCustomFields();
    _setDefaultValues();

      if (widget.initialDate != null) {
      endDateController.text = DateFormat('dd/MM/yyyy').format(widget.initialDate!);
    }
  }

   void _setDefaultValues() {
    selectedPriority = 1;
  }

  void _fetchAndAddCustomFields() async {
    try {
      final data = await ApiService().getCustomFields();
      if (data['result'] != null) {
        setState(() {
          customFields = data['result']
              .map<CustomField>((value) => CustomField(fieldName: value))
              .toList();
        });
      }
    } catch (e) {
      //print('Ошибка!');
    }
  }

 

  void _addCustomField(String fieldName) {
    setState(() {
      customFields.add(CustomField(fieldName: fieldName));
    });
  }


  void _showAddFieldDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCustomFieldDialog(
          onAddField: (fieldName) {
            _addCustomField(fieldName);
          },
        );
      },
    );
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

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              buttonText: AppLocalizations.of(context)!.translate('cancel'),
              buttonColor: const Color(0xffF4F7FD),
              textColor: Colors.black,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                return state is TaskLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff1E2E52),
                        ),
                      )
                    : CustomButton(
                        buttonText:
                            AppLocalizations.of(context)!.translate('add'),
                        buttonColor: const Color(0xff4759FF),
                        textColor: Colors.white,
                        onPressed: _submitForm,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (selectedStatusId == null) {
          showCustomSnackBar(
             context: context,
             message: AppLocalizations.of(context)!.translate('please_select_status_task'),
             isSuccess: false,
           );
        return;
      }

      try {

        final DateTime? endDate = endDateController.text.isNotEmpty
            ? DateFormat('dd/MM/yyyy').parse(endDateController.text)
            : null;

      
        List<Map<String, String>> customFieldMap = customFields
            .where((field) => field.controller.text.isNotEmpty)
            .map((field) => {field.fieldName: field.controller.text})
            .toList();
            
    final localizations = AppLocalizations.of(context)!;

        context.read<TaskBloc>().add(
              CreateTask(
                name: nameController.text,
                statusId: selectedStatusId!,
                taskStatusId: selectedStatusId!,
                priority: selectedPriority,
                // startDate: startDate,
                endDate: endDate,
                projectId: selectedProject != null
                    ? int.parse(selectedProject!)
                    : null,
                userId: selectedUsers?.map((id) => int.parse(id)).toList(),
                description: descriptionController.text,
                customFields: customFieldMap,
                files: selectedFiles.isNotEmpty
                    ? selectedFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        return FileHelper(
                          id: 0,
                          name: fileNames[index],
                          path: entry.value,
                          size: fileSizes[index],
                        );
                      }).toList()
                    : null,
                localizations: localizations, 
              ),
            );

      } catch (e) {
          showCustomSnackBar(
               context: context,
               message: AppLocalizations.of(context)!.translate('error_create_task'),
               isSuccess: false,
             );
      }
    } else {
          showCustomSnackBar(
              context: context,
              message: AppLocalizations.of(context)!.translate('fill_required_fields'),
              isSuccess: false,
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            Navigator.pop(context, );
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('new_task'),
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: false,
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskError) {
               showCustomSnackBar(
                   context: context,
                   message: AppLocalizations.of(context)!.translate(state.message),
                   isSuccess: false,
                 );
          } else if (state is TaskSuccess) {
                showCustomSnackBar(
                   context: context,
                   message: AppLocalizations.of(context)!.translate(state.message),
                   isSuccess: true,
                 );
            Navigator.pop(context);
            context.read<CalendarBloc>().add(FetchCalendarEvents(widget.initialDate?.month ?? DateTime.now().month, widget.initialDate?.year ?? DateTime.now().year));
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
                      TaskStatusRadioGroupWidget(
                        selectedStatus: selectedStatusId?.toString(),
                        onSelectStatus: (TaskStatus selectedStatusData) {
                          setState(() {
                            selectedStatusId = selectedStatusData.id;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextFieldWithPriority(
                        controller: nameController,
                        hintText: AppLocalizations.of(context)!.translate('enter_title'),
                        label: AppLocalizations.of(context)!.translate('event_name'),
                        showPriority: true,
                        isPrioritySelected: selectedPriority == 3,
                        onPriorityChanged: (bool? value) {
                          setState(() {
                            selectedPriority = value == true ? 3 : 1;
                          });
                        },
                        priorityText:
                            AppLocalizations.of(context)!.translate('urgent'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .translate('field_required');
                          }
                          return null;
                        },
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
                      UserMultiSelectWidget(
                        selectedUsers: selectedUsers,
                        onSelectUsers: (List<UserData> selectedUsersData) {
                          setState(() {
                            selectedUsers = selectedUsersData
                                .map((user) => user.id.toString())
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      ProjectTaskGroupWidget(
                        selectedProject: selectedProject,
                        onSelectProject: (ProjectTask selectedProjectData) {
                          setState(() {
                            selectedProject = selectedProjectData.id.toString();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
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
              
                        _buildFileSelection(),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: customFields.length,
                          itemBuilder: (context, index) {
                            return CustomFieldWidget(
                              fieldName: customFields[index].fieldName,
                              valueController: customFields[index].controller,
                              onRemove: () {
                                setState(() {
                                  customFields.removeAt(index);
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        CustomButton(
                          buttonText: AppLocalizations.of(context)!
                              .translate('add_field'),
                          buttonColor: Color(0xff1E2E52),
                          textColor: Colors.white,
                          onPressed: _showAddFieldDialog,
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              ),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }
  }

  

class CustomField {
  final String fieldName;
  final TextEditingController controller = TextEditingController();

  CustomField({required this.fieldName});
}
