import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:intl/intl.dart';

class MyTaskAddScreen extends StatefulWidget {
  final int statusId;

  const MyTaskAddScreen({Key? key, required this.statusId}) : super(key: key);

  @override
  _MyTaskAddScreenState createState() => _MyTaskAddScreenState();
}

class _MyTaskAddScreenState extends State<MyTaskAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  // Переменные для файла
  String? selectedFile;
  String? fileName;
  String? fileSize;
  bool isEndDateInvalid = false;
  bool setPush = false;

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    // Устанавливаем значения по умолчанию
    _setDefaultValues();
    // Подписываемся на изменения в блоках
  }

  void _setDefaultValues() {
    // Устанавливаем приоритет по умолчанию (Обычный)
    // Устанавливаем текущую дату в поле "От"
    // final now = DateTime.now();
    // startDateController.text = DateFormat('dd/MM/yyyy').format(now);
  }

  // Функция выбора файла
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          selectedFile = result.files.single.path!;
          fileName = result.files.single.name;
          // Конвертируем размер в КБ
          fileSize =
              '${(result.files.single.size / 1024).toStringAsFixed(3)}KB';
        });
      }
    } catch (e) {
      print('Ошибка при выборе файла!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.translate('file_selection_error')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPushNotificationCheckbox() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Checkbox(
            value: setPush,
            onChanged: (bool? value) {
              setState(() {
                setPush = value ?? true;
              });
            },
            activeColor: const Color(0xff1E2E52),
          ),
          Text(
            AppLocalizations.of(context)!.translate('set_push_notification'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
        ],
      ),
    );
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
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF4F7FD)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fileName ??
                        AppLocalizations.of(context)!.translate('select_file'),
                    style: TextStyle(
                      color: fileName != null
                          ? const Color(0xff1E2E52)
                          : const Color(0xff99A4BA),
                    ),
                  ),
                ),
                Icon(
                  Icons.attach_file,
                  color: const Color(0xff99A4BA),
                ),
              ],
            ),
          ),
        ),
        if (fileName != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [],
          ),
        ],
      ],
    );
  }

  // Стиль для полей ввода
  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
        borderRadius: BorderRadius.circular(12),
      ),
    );
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
              Navigator.pop(context, widget.statusId);
              context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
            }),
        title: Text(
          AppLocalizations.of(context)!.translate('new_task'),
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        // elevation: 5,
        centerTitle: false,
      ),
      body: BlocListener<MyTaskBloc, MyTaskState>(
        listener: (context, state) {
          if (state is MyTaskError) {
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
                backgroundColor: Colors.red,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state is MyTaskSuccess) {
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
            Navigator.pop(context, widget.statusId);
            context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: nameController,
                        hintText: AppLocalizations.of(context)!
                            .translate('enter_name_list'),
                        label: AppLocalizations.of(context)!
                            .translate('name_list'),
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
                        controller: startDateController,
                        label: AppLocalizations.of(context)!
                            .translate('from_list'),
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return AppLocalizations.of(context)!
                        //         .translate('field_required');
                        //   }
                        //   return null;
                        // },
                      ),
                      const SizedBox(height: 8),
                      CustomTextFieldDate(
                        controller: endDateController,
                        label:
                            AppLocalizations.of(context)!.translate('to_list'),
                        hasError: isEndDateInvalid,
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return AppLocalizations.of(context)!
                        //         .translate('field_required');
                        //   }
                        //   return null;
                        // },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: descriptionController,
                        hintText: AppLocalizations.of(context)!
                            .translate('enter_description'),
                        label: AppLocalizations.of(context)!
                            .translate('description_list'),
                        maxLines: 5,
                      ),
                      const SizedBox(height: 16),
                      _buildFileSelection(), // Добавляем виджет выбора файла
                      _buildPushNotificationCheckbox(), // Add this line
                    ],
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
    if (_formKey.currentState!.validate()) {
      _createMyTask();
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
  }

  void _createMyTask() {
    final String name = nameController.text;
    final String? startDateString =
        startDateController.text.isEmpty ? null : startDateController.text;
    final String? endDateString =
        endDateController.text.isEmpty ? null : endDateController.text;
    final String? description =
        descriptionController.text.isEmpty ? null : descriptionController.text;

    DateTime? startDate;
    if (startDateString != null && startDateString.isNotEmpty) {
      try {
        startDate = DateFormat('dd/MM/yyyy').parse(startDateString);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            AppLocalizations.of(context)!.translate('fill_required_fields'),
          )),
        );
        return;
      }
    }

    DateTime? endDate;
    if (endDateString != null && endDateString.isNotEmpty) {
      try {
        endDate = DateFormat('dd/MM/yyyy').parse(endDateString);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            AppLocalizations.of(context)!.translate('enter_valid_date'),
          )),
        );
        return;
      }
    }
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      setState(() {
        isEndDateInvalid = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .translate('start_date_after_end_date'),
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    MyTaskFile? fileData;
    if (selectedFile != null) {
      fileData = MyTaskFile(
        name: fileName ?? "unknown",
        size: fileSize ?? "0KB",
      );
    }
      final localizations = AppLocalizations.of(context)!;


    context.read<MyTaskBloc>().add(CreateMyTask(
          name: name,
          statusId: widget.statusId,
          taskStatusId: widget.statusId,
          startDate: startDate,
          endDate: endDate,
          description: description,
          filePath: selectedFile, // Передаем путь к файлу
          setPush: setPush, // Add this line
          localizations: localizations,
        ));
  }
}
/*class _MyTaskAddScreenState extends State<MyTaskAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  // Переменные для файла
 List<String> selectedFiles = [];
List<String> fileNames = [];
List<String> fileSizes = [];
  bool isEndDateInvalid = false;
  bool setPush = false;
  bool _showAdditionalFields = false;

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    // Устанавливаем значения по умолчанию
    _setDefaultValues();
    // Подписываемся на изменения в блоках
  }

  void _setDefaultValues() {
    // Устанавливаем приоритет по умолчанию (Обычный)
    // Устанавливаем текущую дату в поле "От"
    // final now = DateTime.now();
    // startDateController.text = DateFormat('dd/MM/yyyy').format(now);
  }
  void _toggleAdditionalFields() {
    setState(() {
      _showAdditionalFields = true;
    });
  }

  Future<void> _pickFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      setState(() {
        for (var file in result.files) {
          selectedFiles.add(file.path!);
          fileNames.add(file.name);
          fileSizes.add('${(file.size / 1024).toStringAsFixed(3)}KB');
        }
      });
    }
  } catch (e) {
    print('Ошибка при выборе файла!');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            AppLocalizations.of(context)!.translate('file_selection_error')),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  Widget _buildPushNotificationCheckbox() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Checkbox(
            value: setPush,
            onChanged: (bool? value) {
              setState(() {
                setPush = value ?? true;
              });
            },
            activeColor: const Color(0xff1E2E52),
          ),
          Text(
            AppLocalizations.of(context)!.translate('set_push_notification'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
        ],
      ),
    );
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
      const SizedBox(height: 4),
      ...fileNames.map((fileName) {
        return Column(
          children: [
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF4F7FD)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fileName,
                        style: TextStyle(
                          color: const Color(0xff1E2E52),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.attach_file,
                      color: const Color(0xff99A4BA),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
      GestureDetector(
        onTap: _pickFile,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF4F7FD)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.translate('select_file'),
                  style: TextStyle(
                    color: const Color(0xff99A4BA),
                  ),
                ),
              ),
              Icon(
                Icons.attach_file,
                color: const Color(0xff99A4BA),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

  // Стиль для полей ввода
  // InputDecoration _inputDecoration() {
  //   return InputDecoration(
  //     border: OutlineInputBorder(
  //       borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     enabledBorder: OutlineInputBorder(
  //       borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     focusedBorder: OutlineInputBorder(
  //       borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //   );
  // }

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
              Navigator.pop(context, widget.statusId);
              context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
            }),
        title: Text(
          AppLocalizations.of(context)!.translate('new_task'),
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        // elevation: 5,
        centerTitle: false,
      ),
      body: BlocListener<MyTaskBloc, MyTaskState>(
        listener: (context, state) {
          if (state is MyTaskError) {
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
                backgroundColor: Colors.red,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state is MyTaskSuccess) {
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
            Navigator.pop(context, widget.statusId);
            context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: nameController,
                        hintText: AppLocalizations.of(context)!
                            .translate('enter_name_list'),
                        label: AppLocalizations.of(context)!
                            .translate('name_list'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .translate('field_required');
                          }
                          return null;
                        },
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
                        _buildPushNotificationCheckbox(), // Add this line
                      ],
                    ],
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
    if (_formKey.currentState!.validate()) {
      _createMyTask();
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
  }

  void _createMyTask() {
  final String name = nameController.text;
  final String? startDateString =
      startDateController.text.isEmpty ? null : startDateController.text;
  final String? endDateString =
      endDateController.text.isEmpty ? null : endDateController.text;
  final String? description =
      descriptionController.text.isEmpty ? null : descriptionController.text;

  DateTime? startDate;
  if (startDateString != null && startDateString.isNotEmpty) {
    try {
      startDate = DateFormat('dd/MM/yyyy').parse(startDateString);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
          AppLocalizations.of(context)!.translate('fill_required_fields'),
        )),
      );
      return;
    }
  }

  DateTime? endDate;
  if (endDateString != null && endDateString.isNotEmpty) {
    try {
      endDate = DateFormat('dd/MM/yyyy').parse(endDateString);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
          AppLocalizations.of(context)!.translate('enter_valid_date'),
        )),
      );
      return;
    }
  }
  if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
    setState(() {
      isEndDateInvalid = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!
              .translate('start_date_after_end_date'),
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
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
        statusId: widget.statusId,
        taskStatusId: widget.statusId,
        startDate: startDate,
        endDate: endDate,
        description: description,
        filePaths: selectedFiles, // Передаем список путей к файлам
        setPush: setPush,
        localizations: localizations,
      ));
}
}*/ 