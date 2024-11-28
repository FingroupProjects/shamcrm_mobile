import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_bloc.dart';
import 'package:crm_task_manager/bloc/project/project_event.dart';
import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/screens/task/task_details/project_list.dart';
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:intl/intl.dart';

class TaskAddScreen extends StatefulWidget {
  final int statusId;

  const TaskAddScreen({Key? key, required this.statusId}) : super(key: key);

  @override
  _TaskAddScreenState createState() => _TaskAddScreenState();
}

class _TaskAddScreenState extends State<TaskAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Переменные для файла
  String? selectedFile;
  String? fileName;
  String? fileSize;

  int? selectedPriority;
  String? selectedProject;
  String? selectedUser;

  // Карта уровней приоритета
  final Map<int, String> priorityLevels = {
    1: 'Обычный',
    3: 'Критический',
    2: 'Сложный'
  };

  @override
  void initState() {
    super.initState();
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllProjectBloc>().add(GetAllProjectEv());
    context.read<UserTaskBloc>().add(FetchUsers());
    // Устанавливаем значения по умолчанию
    _setDefaultValues();

    // Подписываемся на изменения в блоках
    _setupBlocListeners();
  }

  void _setDefaultValues() {
    // Устанавливаем приоритет по умолчанию (Обычный)
    selectedPriority = 1;

    // Устанавливаем текущую дату в поле "От"
    final now = DateTime.now();
    startDateController.text = DateFormat('dd/MM/yyyy').format(now);
  }

  void _setupBlocListeners() {
    // Слушаем изменения в ProjectBloc
    // context.read<GetAllProjectBloc>().stream.listen((state) {
    //   if (state is GetAllProjectLoaded && state.projects.isNotEmpty) {
    //     setState(() {
    //       // Выбираем первый проект по умолчанию
    //       selectedProject = state.projects.first.id.toString();
    //     });
    //   }
    // });

    // // Слушаем изменения в UserBloc
    // context.read<UserTaskBloc>().stream.listen((state) {
    //   if (state is UserTaskLoaded && state.users.isNotEmpty) {
    //     setState(() {
    //       // Выбираем первого пользователя по умолчанию
    //       selectedUser = state.users.first.id.toString();
    //     });
    //   }
    // });
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
      print('Ошибка при выборе файла: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при выборе файла'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // // Виджет выбора файла
  // Widget _buildFileSelection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Файл',
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.w500,
  //           fontFamily: 'Gilroy',
  //           color: Color(0xff1E2E52),
  //         ),
  //       ),
  //       const SizedBox(height: 4),
  //       GestureDetector(
  //         onTap: _pickFile,
  //         child: Container(
  //           padding: const EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFFF4F7FD),
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: const Color(0xFFF4F7FD)),
  //           ),
  //           child: Row(
  //             children: [
  //               Expanded(
  //                 child: Text(
  //                   fileName ?? 'Выберите файл',
  //                   style: TextStyle(
  //                     color: fileName != null
  //                         ? const Color(0xff1E2E52)
  //                         : Colors.grey,
  //                   ),
  //                 ),
  //               ),
  //               Icon(
  //                 Icons.attach_file,
  //                 color: Colors.grey[600],
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //       // if (fileName != null) ...[
  //       //   const SizedBox(height: 8),
  //       //   Row(
  //       //     children: [
  //       //       const Text(
  //       //         'Файл: ',
  //       //         style: TextStyle(
  //       //           fontSize: 14,
  //       //           fontFamily: 'Gilroy',
  //       //           color: Color(0xff1E2E52),
  //       //         ),
  //       //       ),
  //       //       GestureDetector(
  //       //         onTap: () {
  //       //           // Здесь можно добавить логику предпросмотра файла
  //       //         },
  //       //         child: Text(
  //       //           fileName!,
  //       //           style: const TextStyle(
  //       //             fontSize: 14,
  //       //             fontFamily: 'Gilroy',
  //       //             color: Color(0xff4759FF),
  //       //             decoration: TextDecoration.underline,
  //       //           ),
  //       //         ),
  //       //       ),
  //       //     ],
  //       //   ),
  //       // ],
  //     ],
  //   );
  // }

  // Построение выпадающего списка приоритетов
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
              value:
                  selectedPriority ?? 1, // Устанавливаем значение по умолчанию
              items: priorityLevels.entries.map((entry) {
                final priorityColor = entry.key == 2
                    ? Colors.yellow
                    : entry.key == 3
                        ? Colors.red
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
                      Text(entry.value),
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
            ),
          ),
        ),
      ],
    );
  }

  // Стиль для полей ввода
  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
        borderRadius: BorderRadius.circular(8),
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
              context.read<TaskBloc>().add(FetchTaskStatuses());
            }),
        title: const Text(
          'Новая задача',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        // elevation: 5,
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is TaskSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, widget.statusId);
            context.read<TaskBloc>().add(FetchTaskStatuses());
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Поле обязательно для заполнения';
                          }
                          return null;
                        },
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
                      UserWidget(
                        selectedUser: selectedUser,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedUser = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: descriptionController,
                        hintText: 'Введите описание',
                        label: 'Описание',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 16),
                      // _buildFileSelection(), // Добавляем виджет выбора файла
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
        child: Row(children: [
          Expanded(
            child: CustomButton(
              buttonText: 'Отмена',
              buttonColor: const Color(0xffF4F7FD),
              textColor: Colors.black,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              buttonText: 'Добавить',
              buttonColor: const Color(0xff4759FF),
              textColor: Colors.white,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final String name = nameController.text;
                  final String? startDateString =
                      startDateController.text.isEmpty
                          ? null
                          : startDateController.text;
                  final String? endDateString = endDateController.text.isEmpty
                      ? null
                      : endDateController.text;
                  final String? description = descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text;

                  DateTime? startDate;
                  if (startDateString != null && startDateString.isNotEmpty) {
                    try {
                      startDate =
                          DateFormat('dd/MM/yyyy').parse(startDateString);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Введите корректную дату в формате ДД/ММ/ГГГГ'),
                        ),
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
                        const SnackBar(
                          content: Text(
                              'Введите корректную дату в формате ДД/ММ/ГГГГ'),
                        ),
                      );
                      return;
                    }
                  }

                  // Подготовка данных о файле
                  TaskFile? fileData;
                  if (selectedFile != null) {
                    fileData = TaskFile(
                        name: fileName ?? "unknown", size: fileSize ?? "0KB");
                  }
                  print("fileData: $fileData");
                  print("SelectedData: $selectedFile");
                  print("Sending data to server:");
                  print("Name: $name");
                  print("Status ID: ${widget.statusId}");
                  print("Task Status ID: ${widget.statusId}");
                  print("Start Date: $startDate");
                  print("End Date: $endDate");
                  print(
                      "Project ID: ${selectedProject != null ? int.parse(selectedProject!) : null}");
                  print(
                      "User ID: ${selectedUser != null ? int.parse(selectedUser!) : null}");
                  print(
                      "Priority: ${selectedPriority != null ? priorityLevels[selectedPriority!] : null}");
                  print("Description: $description");

                  context.read<TaskBloc>().add(CreateTask(
                        name: name,
                        statusId: widget.statusId,
                        taskStatusId: widget.statusId,
                        startDate: startDate,
                        endDate: endDate,
                        projectId: selectedProject != null
                            ? int.parse(selectedProject!)
                            : null,
                        userId: selectedUser != null
                            ? int.parse(selectedUser!)
                            : null,
                        priority: selectedPriority,
                        description: description,
                        // file: fileData, // Pass the actual File object
                      ));
                }
              },
            ),
          ),
        ]));
  }
}
