import 'dart:io';

import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_event.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/mytask_status_list_edit.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:intl/intl.dart';

class CreateMyTaskFromCalendare extends StatefulWidget {
  final DateTime? initialDate;

  const CreateMyTaskFromCalendare({Key? key, required this.initialDate}) : super(key: key);

  @override
  _CreateMyTaskFromCalendareState createState() => _CreateMyTaskFromCalendareState();
}

class _CreateMyTaskFromCalendareState extends State<CreateMyTaskFromCalendare> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  bool isEndDateInvalid = false;
  bool setPush = false;
  bool _showAdditionalFields = false;
  int? _selectedStatuses;
  bool isSubmitted = false;

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    _setDefaultValues();
  }

  void _setDefaultValues() {
    endDateController.text = DateFormat('dd/MM/yyyy').format(widget.initialDate!);
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

  // Виджет выбора файла
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
            AppLocalizations.of(context)!.translate('new_task'),
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
              onPressed: () {
                Navigator.pop(context,);
              },
            ),
          ),
        ),
        leadingWidth: 40,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: BlocListener<MyTaskBloc, MyTaskState>(
        listener: (context, state) {
          if (state is MyTaskError) {
              showCustomSnackBar(
                   context: context,
                   message: AppLocalizations.of(context)!.translate(state.message),
                   isSuccess: false,
                 );
          } else if (state is MyTaskSuccess) {
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
                          controller: nameController,
                          hintText: AppLocalizations.of(context)!.translate('enter_title'),
                          label: AppLocalizations.of(context)!.translate('event_name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.translate('field_required');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: descriptionController,
                          hintText: AppLocalizations.of(context)!.translate('enter_description'),
                          label: AppLocalizations.of(context)!.translate('description_list'),
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 16),
                        if (!_showAdditionalFields)
                          CustomButton(
                            buttonText: AppLocalizations.of(context)!.translate('additionally'),
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
                        ],
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

  // Кнопки действий
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
            child: BlocBuilder<MyTaskBloc, MyTaskState>(
              builder: (context, state) {
                if (state is MyTaskLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xff1E2E52),
                    ),
                  );
                } else {
                  return CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('add'),
                    buttonColor: const Color(0xff4759FF),
                    textColor: Colors.white,
                    onPressed: _submitForm,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    setState(() {
      isSubmitted = true; 
    });
    
  if (_formKey.currentState!.validate() && _selectedStatuses != null) {
    _createMyTask();
  } else {
    String errorMessage = _selectedStatuses == null
        ? AppLocalizations.of(context)!.translate('Выберете статус')
        : AppLocalizations.of(context)!.translate('fill_required_fields');

  showCustomSnackBar(
       context: context,
       message: AppLocalizations.of(context)!.translate(errorMessage),
       isSuccess: false,
     );
  }
}

  void _createMyTask() {
    final String name = nameController.text;
    final String? endDateString =
        endDateController.text.isEmpty ? null : endDateController.text;
    final String? description =
        descriptionController.text.isEmpty ? null : descriptionController.text;

    // Всегда используем текущую дату как startDate
    DateTime startDate = DateTime.now();

    DateTime? endDate;
    if (endDateString != null && endDateString.isNotEmpty) {
      try {
        endDate = DateFormat('dd/MM/yyyy').parse(endDateString);
      } catch (e) {
          showCustomSnackBar(
              context: context,
              message: AppLocalizations.of(context)!.translate('enter_valid_date'),
              isSuccess: false,
            );
        return;
      }
    }

    List<MyTaskFile> files = [];
    for (int i = 0; i < selectedFiles.length; i++) {
      files.add(MyTaskFile(
        name: fileNames[i],
        size: fileSizes[i],
      ));
    }

    final localizations = AppLocalizations.of(context)!;

    context.read<MyTaskBloc>().add(CreateMyTask(
          name: name,
          statusId: _selectedStatuses!,
          taskStatusId: _selectedStatuses!,
          startDate: startDate, 
          endDate: endDate,
          description: description,
          filePaths: selectedFiles,
          setPush: setPush,
          localizations: localizations,
        ));
  }
}
