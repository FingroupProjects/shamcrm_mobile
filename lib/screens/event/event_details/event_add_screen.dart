import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/event/event_details/Lead_Manager_Selector.dart';
import 'package:crm_task_manager/screens/event/event_details/managers_event.dart';
import 'package:crm_task_manager/screens/event/event_details/notice_subject_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // Добавляем для File
import 'package:file_picker/file_picker.dart'; // Добавляем для FilePicker
import 'dart:convert';

import '../../../custom_widget/custom_textfield_deadline.dart'; // Для json.encode в API

class NoticeAddScreen extends StatefulWidget {
  @override
  _NoticeAddScreenState createState() => _NoticeAddScreenState();
}

class _NoticeAddScreenState extends State<NoticeAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? selectedLead;
  String? selectedSubject;
  List<int> selectedManagers = [];
  String body = '';
  String date = '';
  bool sendNotification = false;
  // Переменные для файлов
  List<String> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileSizes = [];

  @override
  void initState() {
    super.initState();
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
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
      print('Ошибка при выборе файла: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('error_file_pick'),
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
                              });
                            },
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
                            controller: TextEditingController(text: body),
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
                            controller: TextEditingController(text: date),
                            label: AppLocalizations.of(context)!
                                .translate('reminder_date'),
                            withTime: true,
                            onDateSelected: (value) {
                              setState(() {
                                date = value;
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
      if (date.isNotEmpty) {
        try {
          parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(date);
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
              body: body,
              leadId: int.parse(selectedLead!),
              date: parsedDate,
              sendNotification: sendNotification ? 1 : 0,
              users: selectedManagers,
              filePaths: selectedFiles,
              localizations: AppLocalizations.of(context)!,
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