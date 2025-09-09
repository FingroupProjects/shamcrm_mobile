import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/event_by_Id_model.dart';
import 'package:crm_task_manager/screens/event/event_details/managers_event.dart';
import 'package:crm_task_manager/screens/event/event_details/notice_subject_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class NoticeEditScreen extends StatefulWidget {
  final Notice notice;

  const NoticeEditScreen({Key? key, required this.notice}) : super(key: key);

  @override
  _NoticeEditScreenState createState() => _NoticeEditScreenState();
}

class _NoticeEditScreenState extends State<NoticeEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController bodyController;
  late TextEditingController dateController;

  String? selectedLead;
  List<int> selectedManagers = [];
  bool sendNotification = false;
  bool isLoading = false;
  String? selectedSubject;
  
// Переменные для файлов
  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];
  List<NoticeFiles> existingFiles = []; // Для хранения файлов с сервера
  List<String> newFiles = []; // Новый список для хранения путей к новым файлам
  final ApiService _apiService = ApiService(); // Экземпляр ApiService


  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.notice.title);
    bodyController = TextEditingController(text: widget.notice.body);
    dateController = TextEditingController( text: widget.notice.date != null ? 
    DateFormat('dd/MM/yyyy HH:mm').format(widget.notice.date!.add(Duration(hours: 5))) : '',
    );

    selectedLead = widget.notice.lead?.id.toString();
    selectedManagers = widget.notice.users.map((user) => user.id).toList();
    selectedSubject = widget.notice.title;

// Инициализация файлов
    if (widget.notice.files != null) {
      existingFiles = widget.notice.files!;
      setState(() {
        fileNames.addAll(existingFiles.map((file) => file.name));
        fileSizes.addAll(existingFiles
            .map((file) => '${(file.path.length / 1024).toStringAsFixed(3)}KB'));
        selectedFiles.addAll(existingFiles.map((file) => file.path));
      });
    }

    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
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
    offset: const Offset(-10, 0),
    child: Text(
      AppLocalizations.of(context)!.translate('edit_notice'),
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
      body: BlocListener<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventUpdateError) {
            setState(() {
              isLoading = false; // Сбрасываем состояние загрузки
            });
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
          } else if (state is EventUpdateSuccess) {
            setState(() {
              isLoading = false; // Сбрасываем состояние загрузки
            });
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
            Navigator.pop(context, true); // Закрываем экран после успешного обновления
               context.read<NotesBloc>().add(FetchNotes(widget.notice.lead!.id));
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
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: bodyController,
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
                        ),
                        const SizedBox(height: 8),
                        CustomTextFieldDate(
                          controller: dateController,
                          label: AppLocalizations.of(context)!
                              .translate('reminder_date'),
                          withTime: true,
                        ),
                        const SizedBox(height: 8),
                        ManagerMultiSelectWidget(
                          selectedManagers: selectedManagers,
                          onSelectManagers: (List<int> managers) {
                            setState(() {
                              selectedManagers = managers;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
      _buildFileSelection(), // Добавляем выбор файлов
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
                          if (isLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff1E2E52),
                              ),
                            );
                          }
                          return CustomButton(
                            buttonText:
                                AppLocalizations.of(context)!.translate('save'),
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
    );
  }
Future<void> _pickFile() async {
  try {
    //print('NoticeEditScreen: Starting file picker');
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        if (file.path != null && file.name != null) {
          final filePath = file.path!;
          //print('NoticeEditScreen: Picked file path: $filePath');
          final fileObject = File(filePath);
          if (await fileObject.exists()) {
            final fileName = file.name;
            // Проверяем, не существует ли файл уже в existingFiles или newFiles
            if (!existingFiles.any((f) => f.name == fileName) &&
                !newFiles.contains(filePath)) {
              final fileSize = await fileObject.length();
              // //print(
              //     'NoticeEditScreen: Adding new file, name: $fileName, size: $fileSize bytes');
              setState(() {
                newFiles.add(filePath); // Добавляем в newFiles
                fileNames.add(fileName);
                fileSizes.add('${(fileSize / 1024).toStringAsFixed(3)}KB');
                selectedFiles.add(filePath); // Для отображения в UI
              });
            } else {
              //print('NoticeEditScreen: File $fileName already exists, skipping');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.translate('file_already_exists'),
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
                  backgroundColor: Colors.red,
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } else {
            //print('NoticeEditScreen: File does not exist at path: $filePath');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.translate('file_not_found'),
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
                backgroundColor: Colors.red,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          // //print(
          //     'NoticeEditScreen: File path or name is null for file: ${file.name}');
        }
      }
    } else {
      //print('NoticeEditScreen: File picker cancelled or no files selected');
    }
  } catch (e, stackTrace) {
    //print('NoticeEditScreen: Error picking file: $e');
    //print('Stack trace: $stackTrace');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.translate('error_picking_file'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
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
                                        buttonText: AppLocalizations.of(context)!
                                            .translate('cancel'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        buttonColor: Colors.red,
                                        textColor: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: CustomButton(
                                        buttonText: AppLocalizations.of(context)!
                                            .translate('unpin'),
                                        onPressed: () async {
                                          if (isExistingFile) {
                                            try {
                                              final result = await _apiService
                                                  .deleteTaskFile(
                                                      existingFiles[index].id);
                                              if (result['result'] ==
                                                  'Success') {
                                                setState(() {
                                                  existingFiles.removeAt(index);
                                                  fileNames.removeAt(index);
                                                  selectedFiles.remove(
                                                      existingFiles[index].path);
                                                });
                                                Navigator.of(context).pop(true);
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
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              Navigator.of(context).pop(false);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(context)!
                                                        .translate(
                                                            'failed_to_delete_file'),
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } else {
                                            setState(() {
                                              final newFileIndex =
                                                  index - existingFiles.length;
                                              newFiles.removeAt(newFileIndex);
                                              fileNames.removeAt(index);
                                              fileSizes.removeAt(newFileIndex);
                                              selectedFiles.removeAt(index);
                                            });
                                            Navigator.of(context).pop(true);
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

                        if (confirmed != true) return;
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
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // // Проверяем тематику
      if (selectedSubject == null || selectedSubject!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Выберите тематику!'),
            backgroundColor: Colors.red,
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
