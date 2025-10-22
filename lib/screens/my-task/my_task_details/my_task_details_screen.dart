import 'dart:convert';
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/bloc/my-task_by_id/taskById_bloc.dart';
import 'package:crm_task_manager/bloc/my-task_by_id/taskById_event.dart';
import 'package:crm_task_manager/bloc/my-task_by_id/taskById_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/file_utils.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/my-taskbyId_model.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_delete.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_edit_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_dropdown_history_task.dart';

class MyTaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final String taskName;
  final int? taskNumber;
  final String taskStatus;
  final int statusId;
  final String? description;
  final String? startDate;
  final String? endDate;
  final String? taskFile; // Добавлено поле для файла
  final List<MyTaskFiles>? files; // вместо String? taskFile
  final DateTime? initialDate;

  MyTaskDetailsScreen(
      {required this.taskId,
      required this.taskName,
      this.taskNumber,
      required this.taskStatus,
      required this.statusId,
      this.description,
      this.startDate,
      this.endDate,
      // this.projectName,
      this.taskFile, // Инициализация опционального параметра
      this.initialDate,
      this.files});

  @override
  _MyTaskDetailsScreenState createState() => _MyTaskDetailsScreenState();
}

class FileCacheManager {
  static final FileCacheManager _instance = FileCacheManager._internal();
  factory FileCacheManager() => _instance;
  FileCacheManager._internal();

  static const String CACHE_INFO_KEY = 'file_cache_info';
  late SharedPreferences _prefs;
  final Map<int, String> _cachedFiles = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadCacheInfo();
    _initialized = true;
  }

  Future<void> _loadCacheInfo() async {
    final String? cacheInfo = _prefs.getString(CACHE_INFO_KEY);
    if (cacheInfo != null) {
      final Map<String, dynamic> cacheMap = json.decode(cacheInfo);
      cacheMap.forEach((key, value) {
        _cachedFiles[int.parse(key)] = value.toString();
      });
    }
  }

  Future<void> _saveCacheInfo() async {
    final Map<String, dynamic> cacheMap = {};
    _cachedFiles.forEach((key, value) {
      cacheMap[key.toString()] = value;
    });
    await _prefs.setString(CACHE_INFO_KEY, json.encode(cacheMap));
  }

  Future<String?> getCachedFilePath(int fileId) async {
    await init();
    if (_cachedFiles.containsKey(fileId)) {
      final file = File(_cachedFiles[fileId]!);
      if (await file.exists()) {
        return _cachedFiles[fileId];
      } else {
        _cachedFiles.remove(fileId);
        await _saveCacheInfo();
      }
    }
    return null;
  }

  Future<void> cacheFile(int fileId, String filePath) async {
    await init();
    _cachedFiles[fileId] = filePath;
    await _saveCacheInfo();
  }

  Future<void> clearCache() async {
    await init();
    for (var filePath in _cachedFiles.values) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _cachedFiles.clear();
    await _saveCacheInfo();
  }

  // Метод для получения размера кэша
  Future<int> getCacheSize() async {
    await init();
    int totalSize = 0;
    for (var filePath in _cachedFiles.values) {
      final file = File(filePath);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }
    return totalSize;
  }
}

class _MyTaskDetailsScreenState extends State<MyTaskDetailsScreen> {
  List<Map<String, String>> details = [];
  MyTaskById? currentMyTask;
  
  // Конфигурация полей
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;
  
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isDownloading = false;
  Map<int, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    
    // Загружаем конфигурацию после того как виджет построен
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFieldConfiguration();
      }
    });
    
    context
        .read<MyTaskByIdBloc>()
        .add(FetchMyTaskByIdEvent(taskId: int.parse(widget.taskId)));
  }

  Future<void> _loadFieldConfiguration() async {
    if (kDebugMode) {
      print('MyTaskDetailsScreen: Loading field configuration');
    }
    
    if (mounted) {
      context.read<FieldConfigurationBloc>().add(
        FetchFieldConfiguration('tasks')  // Используем ту же конфигурацию что и для обычных задач
      );
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('invalid_format');
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
    
    if (kDebugMode) {
      print('=== MyTaskDetailsScreen: _updateDetails START ===');
      print('MyTaskDetailsScreen: isConfigurationLoaded = $isConfigurationLoaded');
      print('MyTaskDetailsScreen: fieldConfigurations.length = ${fieldConfigurations.length}');
    }
    
    // Если конфигурация загружена, строим детали на её основе
    if (isConfigurationLoaded && fieldConfigurations.isNotEmpty) {
      if (kDebugMode) {
        print('MyTaskDetailsScreen: Using configuration-based details');
      }
      _buildDetailsFromConfiguration(task);
    } else {
      if (kDebugMode) {
        print('MyTaskDetailsScreen: Using LEGACY method (fallback)');
      }
      _buildDetailsLegacy(task);
    }
    
    if (kDebugMode) {
      print('MyTaskDetailsScreen: Total details built: ${details.length}');
      print('=== MyTaskDetailsScreen: _updateDetails END ===');
    }
  }

  // Новый метод для построения деталей на основе конфигурации
  void _buildDetailsFromConfiguration(MyTaskById task) {
    details = [];
    
    if (kDebugMode) {
      print('=== _buildDetailsFromConfiguration START ===');
      print('MyTaskDetailsScreen: fieldConfigurations count: ${fieldConfigurations.length}');
    }
    
    // Проходим по конфигурации в правильном порядке
    for (var config in fieldConfigurations) {
      if (!config.isActive) continue;
      
      String? value = _getFieldValue(task, config);
      if (value != null && value.isNotEmpty) {
        String label = _getFieldLabel(config);
        details.add({'label': label, 'value': value});
      }
    }
    
    // Добавляем дополнительные поля
    _addExtraFields(task);
    
    // Добавляем файлы если есть
    if (task.files != null && task.files!.isNotEmpty) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('files_details'),
        'value': task.files!.length.toString() + ' ' + AppLocalizations.of(context)!.translate('files'),
      });
    }
    
    if (kDebugMode) {
      print('=== _buildDetailsFromConfiguration END ===');
    }
  }

  // Получение значения поля из задачи
  String? _getFieldValue(MyTaskById task, FieldConfiguration config) {
    switch (config.fieldName) {
      case 'name':
        return task.name;
      case 'description':
        return task.description?.isNotEmpty == true ? task.description : null;
      case 'status_id':
        return task.taskStatus?.title;
      case 'end_date':
        return task.endDate != null && task.endDate!.isNotEmpty
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.endDate!))
            : null;
      default:
        return null;
    }
  }

  // Получение лейбла для поля
  String _getFieldLabel(FieldConfiguration config) {
    if (config.isCustomField || config.isDirectory) {
      return '${config.fieldName}:';
    }
    
    switch (config.fieldName) {
      case 'name':
        return AppLocalizations.of(context)!.translate('task_name');
      case 'description':
        return AppLocalizations.of(context)!.translate('description_details');
      case 'status_id':
        return AppLocalizations.of(context)!.translate('Статус:');
      case 'end_date':
        return AppLocalizations.of(context)!.translate('deadLine');
      default:
        return '${config.fieldName}:';
    }
  }

  // Добавление дополнительных полей
  void _addExtraFields(MyTaskById task) {
    // Дата создания
    if (task.startDate != null && task.startDate!.isNotEmpty) {
      bool alreadyAdded = details.any((d) => d['label'] == AppLocalizations.of(context)!.translate('created_at_details'));
      if (!alreadyAdded) {
        details.add({
          'label': AppLocalizations.of(context)!.translate('created_at_details'),
          'value': formatDate(task.startDate)
        });
      }
    }
  }

  // Legacy метод для построения деталей (fallback)
  void _buildDetailsLegacy(MyTaskById task) {
    details = [
      {
        'label': AppLocalizations.of(context)!.translate('task_name'),
        'value': task.name
      },
      {
        'label': AppLocalizations.of(context)!.translate('description_details'),
        'value': task.description ?? ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('created_at_details'),
        'value': task.startDate != null
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.startDate!))
            : ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('deadLine'),
        'value': task.endDate != null
            ? DateFormat('dd.MM.yyyy').format(DateTime.parse(task.endDate!))
            : ''
      },
      if (task.files != null && task.files!.isNotEmpty)
        {
          'label': AppLocalizations.of(context)!.translate('files_details'),
          'value':
              '${task.files!.length} ${AppLocalizations.of(context)!.translate('files')}'
        },
      {
        'label': AppLocalizations.of(context)!.translate('Статус:'),
        'value': task.taskStatus!.title.toString()
      },
    ];
  }

// Функция для показа диалогового окна с полным текстом
  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(maxHeight: 400),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    textAlign: TextAlign.justify, // Выровнять текст по ширине

                    style: TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('close'),
                  onPressed: () => Navigator.pop(context),
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FieldConfigurationBloc, FieldConfigurationState>(
          listener: (context, configState) {
            if (kDebugMode) {
              print('MyTaskDetailsScreen: FieldConfigurationBloc state changed: ${configState.runtimeType}');
            }
            
            if (configState is FieldConfigurationLoaded) {
              if (kDebugMode) {
                print('MyTaskDetailsScreen: Configuration loaded with ${configState.fields.length} fields');
              }
              
              if (mounted) {
                setState(() {
                  fieldConfigurations = configState.fields;
                  isConfigurationLoaded = true;
                });
                
                // Перестраиваем детали если задача уже загружена
                if (currentMyTask != null) {
                  setState(() {
                    _updateDetails(currentMyTask);
                  });
                }
              }
            } else if (configState is FieldConfigurationError) {
              if (kDebugMode) {
                print('MyTaskDetailsScreen: Configuration error: ${configState.message}');
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
      child: BlocBuilder<MyTaskByIdBloc, MyTaskByIdState>(
        builder: (context, state) {
          if (state is MyTaskByIdLoading) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xff1E2E52)),
              ),
            );
          } else if (state is MyTaskByIdLoaded) {
            if (state.task == null) {
              return Scaffold(
                body: Center(
                  child: Text(
                    AppLocalizations.of(context)!
                        .translate('task_data_unavailable'),
                  ),
                ),
              );
            }
            MyTaskById task = state.task!;
            _updateDetails(task);

          return Scaffold(
            appBar: _buildAppBar(context,
                "${AppLocalizations.of(context)!.translate('view_task')} №${task.taskNumber ?? ''}"),
            backgroundColor: Colors.white,
            body: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListView(
                  children: [
                    _buildDetailsList(),
                    const SizedBox(height: 16),
                    ActionHistoryWidgetMyTask(taskId: int.parse(widget.taskId)),
                  ],
                )),
          );
        }
        return Scaffold(
          body: Center(child: Text('')),
        );
      },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true, // Добавлено
      elevation: 0,
      centerTitle: false,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Transform.translate(
          offset: const Offset(
              0, -2), // Добавлен правильный offset как в первом варианте
          child: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              context.read<CalendarBloc>().add(FetchCalendarEvents(
                  widget.initialDate?.month ?? DateTime.now().month,
                  widget.initialDate?.year ?? DateTime.now().year));
              Navigator.pop(context, widget.statusId);
            },
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(
            -10, 0), // Добавлен правильный offset как в первом варианте
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                        taskStatus:
                            currentMyTask!.taskStatus?.taskStatus.toString() ??
                                '',
                        statusId: currentMyTask!.taskStatus?.id ?? 0,
                        // statusId: widget.statusId,
                        description: currentMyTask!.description,
                        startDate: currentMyTask!.startDate,
                        endDate: currentMyTask!.endDate,
                        files: currentMyTask!.files,
                      ),
                    ),
                  );

                  if (shouldUpdate == true) {
                    context
                        .read<MyTaskByIdBloc>()
                        .add(FetchMyTaskByIdEvent(taskId: currentMyTask!.id));
                    context.read<MyTaskBloc>().add(FetchMyTaskStatuses());

                    context.read<CalendarBloc>().add(FetchCalendarEvents(
                        widget.initialDate?.month ?? DateTime.now().month,
                        widget.initialDate?.year ?? DateTime.now().year));
                  }
                }
              },
            ),
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
    // Специальная обработка для названия и описания
    if (label == AppLocalizations.of(context)!.translate('task_name') ||
        label ==
            AppLocalizations.of(context)!.translate('description_details')) {
      return GestureDetector(
        onTap: () {
          if (value.isNotEmpty) {
            _showFullTextDialog(
              label.replaceAll(':', ''),
              value,
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                  decoration:
                      value.isNotEmpty ? TextDecoration.underline : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (label == AppLocalizations.of(context)!.translate('files_details')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          SizedBox(height: 8),
          Container(
            height: 120, // Высота контейнера для файлов
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currentMyTask?.files?.length ?? 0,
              itemBuilder: (context, index) {
                final file = currentMyTask!.files![index];
                final fileExtension = file.name.split('.').last.toLowerCase();

                return Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      if (!_isDownloading) {
                        FileUtils.showFile(
                          context: context,
                          fileUrl: file.path,
                          fileId: file.id,
                          setState: setState,
                          downloadProgress: _downloadProgress,
                          isDownloading: _isDownloading,
                          apiService: _apiService,
                        );
                      }
                    },
                    child: Container(
                      width: 100,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Иконка файла
                              Image.asset(
                                'assets/icons/files/$fileExtension.png',
                                width: 60,
                                height: 60,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/icons/files/file.png', // Дефолтная иконка
                                    width: 60,
                                    height: 60,
                                  );
                                },
                              ),
                              // Индикатор загрузки
                              if (_downloadProgress.containsKey(file.id))
                                CircularProgressIndicator(
                                  value: _downloadProgress[file.id],
                                  strokeWidth: 3,
                                  backgroundColor: Colors.grey.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xff1E2E52),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            file.name,
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
                  ),
                );
              },
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



// Функция для показа ошибки
 
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
