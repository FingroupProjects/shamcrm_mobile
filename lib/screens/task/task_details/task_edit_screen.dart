import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_event.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_create_field.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list.dart';
import 'package:crm_task_manager/screens/task/task_details/task_add_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class TaskEditScreen extends StatefulWidget {
  final int taskId;
  final String taskName;
  final String taskStatus;
  final int statusId;
  final String? project;
  final List<int>? user;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? description;
  final int? priority;
  final String? file;
  final List<TaskCustomFieldsById> taskCustomFields;

  TaskEditScreen({
    required this.taskId,
    required this.taskName,
    required this.taskStatus,
    required this.statusId,
    this.project,
    this.user,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.description,
    this.priority,
    this.file,
    required this.taskCustomFields,
  });

  @override
  _TaskEditScreenState createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedProject;
  List<String>? selectedUsers;
  int? selectedPriority;
  List<CustomField> customFields = [];
  // Добавьте эти переменные в класс _TaskEditScreenState
  String? selectedFile;
  String? fileName;
  String? fileSize;
  final ApiService _apiService = ApiService();

  final Map<int, String> priorityLevels = {
    1: 'Обычный',
    2: 'Критический',
    3: 'Сложный'
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
    // Инициализируем информацию о файле, если он есть
    if (widget.file != null) {
      fileName = widget.file;
    }
  }

  void _initializeControllers() {
    nameController.text = widget.taskName;
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
    selectedProject = widget.project;
    selectedUsers = widget.user?.map((e) => e.toString()).toList() ?? [];

    selectedPriority = widget.priority ?? 1;
    for (var customField in widget.taskCustomFields) {
      customFields.add(CustomField(fieldName: customField.key)
        ..controller.text = customField.value);
    }
  }

  void _loadInitialData() {
    context.read<GetAllProjectBloc>().add(GetAllProjectEv());
    context.read<UserTaskBloc>().add(FetchUsers());
    context.read<TaskBloc>().add(FetchTaskStatuses());
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

  InputDecoration _inputDecoration() {
    return const InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: InputBorder.none,
      filled: true,
      fillColor: Color(0xFFF4F7FD),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
        color: Color(0xff1E2E52),
      ),
    );
  }

  Widget _buildFileSelection(TaskEditScreen task) {
    if (task.file != null && task.file!.isNotEmpty) {
      // Если файл уже существует, показываем ссылку
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Файл',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildLabel('Файл:'),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (task.file != null) {
                    _showFile(task
                        .file!); // Обработчик для скачивания и открытия файла
                  }
                },
                child: Text(
                  'Ссылка',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1E2E52),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Если файл не выбран, показываем обычный виджет для выбора файла
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Файл',
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
                      fileName ?? 'Выберите файл',
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
              children: [
                if (fileName != null)
                  IconButton(
                    icon: Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        fileName = null;
                        selectedFile = null;
                      });
                    },
                  ),
              ],
            ),
          ],
        ],
      );
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = result.files.single.path;
        fileName = result.files.single.name;
        fileSize = '${(result.files.single.size / 1024).toStringAsFixed(2)} KB';
      });
    }
  }

  void _showFile(String fileUrl) async {
    try {
      print('Входящий fileUrl: $fileUrl');

      // Получаем базовый домен из ApiService
      final domain = await _apiService.getEnteredDomain();
      print('Полученный базовый домен: $domain');

      // Формируем полный URL файла
      final fullUrl =
          Uri.parse('https://$domain-back.shamcrm.com/storage/$fileUrl');
      print('Сформированный полный URL: $fullUrl');

      // Путь для сохранения файла
      final directory = await getApplicationDocumentsDirectory();
      final fileName = fileUrl.split('/').last;
      final filePath = '${directory.path}/$fileName';

      // Загружаем файл
      final dio = Dio();
      await dio.download(fullUrl.toString(), filePath);

      print('Файл успешно скачан в $filePath');

      // Открываем файл
      final result = await OpenFile.open(filePath);
      if (result.type == ResultType.error) {
        print('Не удалось открыть файл: ${result.message}');
        _showErrorSnackBar('Не удалось открыть файл.');
      } else {
        print('Файл открыт успешно.');
      }
    } catch (e) {
      print('Ошибка при скачивании или открытии файла: $e');
      _showErrorSnackBar('Произошла ошибка при скачивании или открытии файла.');
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

  Widget _buildPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Уровень приоритета',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.white,
            ),
            child: DropdownButtonFormField<int>(
              value: selectedPriority ?? 1,
              items: priorityLevels.entries.map((entry) {
                final priorityColor = entry.key == 2
                    ? Colors.red
                    : entry.key == 3
                        ? Colors.yellow
                        : Colors.green;
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.value,
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
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  selectedPriority = newValue;
                });
              },
              decoration: _inputDecoration(),
              validator: (value) =>
                  value == null ? 'Поле обязательно для заполнения' : null,
            ),
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
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: const Text(
          'Редактирование задачи',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          // if (state is TaskError) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text(state.message),
          //       duration: const Duration(seconds: 3),
          //       backgroundColor: Colors.red,
          //     ),
          //   );
          // } else
          if (state is TaskSuccess) {
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
                duration: Duration(seconds: 2), // Установлено на 2 секунды
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: nameController,
                        hintText: 'Введите название',
                        label: 'Название',
                        validator: (value) => value!.isEmpty
                            ? 'Поле обязательно для заполнения'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildPriorityDropdown(),
                      const SizedBox(height: 16),
                      CustomTextFieldDate(
                        controller: startDateController,
                        label: 'От',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextFieldDate(
                        controller: endDateController,
                        label: 'До',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      ProjectRadioGroupWidget(
                        selectedProject: selectedProject,
                        onSelectProject: (Project selectedProjectData) {
                          setState(() {
                            selectedProject = selectedProjectData.id.toString();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      UserMultiSelectWidget(
                        selectedUsers: selectedUsers,
                        onSelectUsers: (List<UserData> selectedUsersData) {
                          setState(() {
                            // Update selected user IDs
                            selectedUsers = selectedUsersData
                                .map((user) => user.id.toString())
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: descriptionController,
                        hintText: 'Введите описание',
                        label: 'Описание',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 16),
                      _buildFileSelection(widget),
                      // Добавляем виджет выбора файла
                      const SizedBox(height: 20),
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
                      CustomButton(
                        buttonText: 'Добавить поле',
                        buttonColor: Color(0xff1E2E52),
                        textColor: Colors.white,
                        onPressed: _showAddFieldDialog,
                      ),
                    ],
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
                        buttonText: 'Отмена',
                        buttonColor: const Color(0xffF4F7FD),
                        textColor: Colors.black,
                        onPressed: () => Navigator.pop(context, null),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<TaskBloc, TaskState>(
                        builder: (context, state) {
                          if (state is TaskLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff1E2E52),
                              ),
                            );
                          } else {
                            return CustomButton(
                              buttonText: 'Сохранить',
                              buttonColor: const Color(0xff4759FF),
                              textColor: Colors.white,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  DateTime? startDate;
                                  DateTime? endDate;

                                  try {
                                    if (startDateController.text.isNotEmpty) {
                                      startDate = DateFormat('dd/MM/yyyy')
                                          .parseStrict(
                                              startDateController.text);
                                    }
                                    if (endDateController.text.isNotEmpty) {
                                      endDate = DateFormat('dd/MM/yyyy')
                                          .parseStrict(endDateController.text);
                                    }
                                    List<Map<String, String>> customFieldList =
                                        [];
                                    for (var field in customFields) {
                                      String fieldName = field.fieldName.trim();
                                      String fieldValue =
                                          field.controller.text.trim();
                                      if (fieldName.isNotEmpty &&
                                          fieldValue.isNotEmpty) {
                                        customFieldList
                                            .add({fieldName: fieldValue});
                                      }
                                    }
                                    context.read<TaskBloc>().add(
                                          UpdateTask(
                                            taskId: widget.taskId,
                                            name: nameController.text,
                                            statusId: widget.statusId,
                                            taskStatusId: widget.statusId,
                                            startDate: startDate,
                                            endDate: endDate,
                                            projectId: selectedProject != null
                                                ? int.parse(selectedProject!)
                                                : null,
                                            userId: selectedUsers != null
                                                ? selectedUsers!
                                                    .map((id) => int.parse(id))
                                                    .toList()
                                                : null,
                                            priority:
                                                selectedPriority?.toString(),
                                            description:
                                                descriptionController.text,
                                            customFields: customFieldList,
                                            filePath:
                                                selectedFile, // Добавляем путь к файлу
                                          ),
                                        );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Ошибка в формате даты: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Пожалуйста, заполните все обязательные поля'),
                                      backgroundColor: Colors.red,
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
