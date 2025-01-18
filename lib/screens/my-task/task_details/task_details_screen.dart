import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/my-task_by_id/taskById_event.dart';
import 'package:crm_task_manager/bloc/my-task_by_id/taskById_state.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/models/my-taskbyId_model.dart';
import 'package:crm_task_manager/screens/my-task/task_details/task_delete.dart';
import 'package:crm_task_manager/screens/my-task/task_details/task_edit_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dropdown_history_task.dart';

class MyTaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final String taskName;
  final String taskStatus;
  final int statusId;
  final String? description;
  final String? startDate;
  final String? endDate;
  final List<MyTaskCustomField> taskCustomFields;
  final String? taskFile; // Добавлено поле для файла

  MyTaskDetailsScreen({
    required this.taskId,
    required this.taskName,
    required this.taskStatus,
    required this.statusId,
    this.description,
    this.startDate,
    this.endDate,
    // this.projectName,
    required this.taskCustomFields,
    this.taskFile, // Инициализация опционального параметра
  });

  @override
  _MyTaskDetailsScreenState createState() => _MyTaskDetailsScreenState();
}

class _MyTaskDetailsScreenState extends State<MyTaskDetailsScreen> {
  List<Map<String, String>> details = [];
  MyTaskById? currentMyTask;
  bool _canEditMyTask = false;
  bool _canDeleteMyTask = false;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    context
        .read<MyTaskByIdBloc>()
        .add(FetchMyTaskByIdEvent(taskId: int.parse(widget.taskId)));
  }

  // Метод для проверки разрешений
  Future<void> _checkPermissions() async {
    final canEdit = await _apiService.hasPermission('task.update');
    final canDelete = await _apiService.hasPermission('task.delete');
    setState(() {
      _canEditMyTask = canEdit;
      _canDeleteMyTask = canDelete;
    });
  }
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Неверный формат';
    }
  }
  // Обновление данных задачи
  void _updateDetails(MyTaskById? task) {
    if (task == null) {
      currentMyTask = null;
      details.clear();
      return;
    }
    currentMyTask = task;
    details = [
      {'label': 'Название задачи:', 'value': task?.name ?? ""},
      {
        'label': 'От:',
        'value': task.startDate != null && task.startDate!.isNotEmpty
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.startDate!))
            : ''
      },
      {
        'label': 'До:',
        'value': task.endDate != null && task.endDate!.isNotEmpty
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.endDate!))
            : ''
      },
      {
        'label': 'Описание:',
        'value': task.description?.isNotEmpty == true ? task.description! : ''
      },
      {
        'label': 'Статус:',
        'value': task.taskStatus?.taskStatus.name ?? '',
      },
    ];

    for (var field in task.taskCustomFields) {
      details.add({'label': '${field.key}:', 'value': field.value});
    }

    // Вывод каждой детали в консоль
    for (var detail in details) {
      print("${detail['label']} ${detail['value']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(context, 'Просмотр задачи'),
        backgroundColor: Colors.white,
        body: BlocListener<MyTaskByIdBloc, MyTaskByIdState>(
          listener: (context, state) {
            if (state is MyTaskByIdLoaded) {
              print("Задача Data: ${state.task.toString()}");
            } else if (state is MyTaskByIdError) {
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
            }
          },
          child: BlocBuilder<MyTaskByIdBloc, MyTaskByIdState>(
            builder: (context, state) {
              if (state is MyTaskByIdLoading) {
                return Center(
                  child: CircularProgressIndicator(color: Color(0xff1E2E52)),
                );
              } else if (state is MyTaskByIdLoaded) {
                if (state.task == null) {
                  return Center(child: Text('Данные о задаче недоступны.'));
                }
                MyTaskById task = state.task!;
                _updateDetails(task);

                return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ListView(
                      children: [
                        _buildDetailsList(),
                        const SizedBox(height: 16),
                        ActionHistoryWidgetMyTask(
                            taskId: int.parse(widget.taskId)),
                      ],
                    ));
              } else if (state is MyTaskByIdError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
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
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      duration: Duration(seconds: 3),
                    ),
                  );
                });
              }
              return Center(child: Text(''));
            },
          ),
        ));
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Image.asset(
          'assets/icons/arrow-left.png',
          width: 24,
          height: 24,
        ),
        onPressed: () {
          Navigator.pop(context, widget.statusId);
          // context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
        },
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      actions: [
        if (_canEditMyTask || _canDeleteMyTask)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canEditMyTask)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Image.asset(
                    'assets/icons/edit.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () async {

                    if (currentMyTask != null) {
                      final shouldUpdate = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyTaskEditScreen(
                            taskId: currentMyTask!.id,
                            taskName: currentMyTask!.name,
                            taskStatus: currentMyTask!.taskStatus?.taskStatus
                                    .toString() ??
                                '',                           
                            statusId: currentMyTask!.statusId,
                            description: currentMyTask!.description,
                            startDate: currentMyTask!.startDate,
                            endDate: currentMyTask!.endDate,
                            taskCustomFields: currentMyTask!.taskCustomFields,
                            file: currentMyTask!.taskFile,
                          ),
                        ),
                      );

                      if (shouldUpdate == true) {
                        context
                            .read<MyTaskByIdBloc>()
                            .add(FetchMyTaskByIdEvent(taskId: currentMyTask!.id));
                        context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
                      }
                    }
                  },
                ),
              if (_canDeleteMyTask)
                IconButton(
                  padding: EdgeInsets.only(right: 8),
                  constraints: BoxConstraints(),
                  icon: Image.asset(
                    'assets/icons/delete.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          DeleteMyTaskDialog(taskId: currentMyTask!.id),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }

  // Построение списка деталей задачи
  Widget _buildDetailsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildDetailItem(
            details[index]['label']!,
            details[index]['value']!,
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {

    if (label == 'Файл:') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (currentMyTask?.taskFile != null) {
                _showFile(currentMyTask!.taskFile!);
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
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        SizedBox(width: 8),
        Expanded(
          child: _buildValue(value),
        ),
      ],
    );
  }

  void _showFile(String fileUrl) async {
    try {
      print('Входящий fileUrl: $fileUrl');

      // Получаем базовый домен из ApiService
      final domain = await _apiService.getEnteredDomain();
      print('Полученный базовый домен: $domain');

      // Формируем полный URL файла
      final fullUrl =
          Uri.parse('https://$domain-back.sham360.com/storage/$fileUrl');
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
      print('Ошибка при скачивании или открытии файла!');
      _showErrorSnackBar('Произошла ошибка при скачивании или открытии файла.');
    }
  }

// Функция для показа ошибки
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
  }

  // Построение метки
  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xff99A4BA),
      ),
    );
  }

  // Построение значения
  Widget _buildValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
      overflow: TextOverflow.visible,
    );
  }