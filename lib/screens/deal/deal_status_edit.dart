import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/models/user_data_response.dart'; // ✅ ДОБАВИТЬ
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ ДОБАВИТЬ

class EditDealStatusScreen extends StatefulWidget {
  final int dealStatusId;

  const EditDealStatusScreen({
    Key? key,
    required this.dealStatusId,
  }) : super(key: key);

  @override
  _EditDealStatusScreenState createState() => _EditDealStatusScreenState();
}

class _EditDealStatusScreenState extends State<EditDealStatusScreen> {
  late TextEditingController _titleController;
  late TextEditingController _daysController;
  late TextEditingController _notificationMessageController;
  bool _isSuccess = false;
  bool _isFailure = false;
  bool _showOnMainPage = false;
  late DealBloc _dealBloc;
  bool _dataLoaded = false;
  bool _isExpanded = false;
  bool _isExpandedMessage = false;

  // ✅ НОВОЕ
  bool _isMultiSelectEnabled = false;
  List<UserData> _selectedUsers = [];
  List<UserData> _selectedChangeStatusUsers =
      []; // ✅ НОВОЕ: пользователи, которые могут ИЗМЕНЯТЬ

  List<String>? _initialUserIds; // Для хранения начальных ID пользователей
  List<String>?
      _initialChangeStatusUserIds; // ✅ НОВОЕ: для хранения ID (изменение статуса)

  bool _isExpandedViewUsers = false; // ✅ НОВОЕ: expandable для первого поля
  bool _isExpandedChangeUsers = false; // ✅ НОВОЕ: expandable для второго поля

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _daysController = TextEditingController();
    _notificationMessageController = TextEditingController();
    _dealBloc = DealBloc(ApiService());
    _loadMultiSelectSetting(); // ✅ НОВОЕ
    _loadDealStatus();
  }

  // ✅ НОВОЕ: Загрузка настройки
 Future<void> _loadMultiSelectSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final managingVisibility = prefs.getBool('managing_deal_status_visibility') ?? false;
    final changeMultiple = prefs.getBool('change_deal_to_multiple_statuses') ?? false;
    
    // Если хотя бы один флаг true, включаем мультивыбор
    final value = managingVisibility || changeMultiple;
    
    if (mounted) {
      setState(() {
        _isMultiSelectEnabled = value;
      });
    }
    
    print('EditDealStatusScreen: managing_deal_status_visibility = $managingVisibility');
    print('EditDealStatusScreen: change_deal_to_multiple_statuses = $changeMultiple');
    print('EditDealStatusScreen: _isMultiSelectEnabled = $value');
  }

  void _loadDealStatus() {
    _dealBloc.add(FetchDealStatus(widget.dealStatusId));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _daysController.dispose();
    _notificationMessageController.dispose();
    _dealBloc.close();
    super.dispose();
  }

  void _saveChanges() {
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      // ✅ НОВОЕ: Получаем оба списка ID пользователей
      final userIds = _selectedUsers.map((user) => user.id).toList();
      final changeStatusUserIds =
          _selectedChangeStatusUsers.map((user) => user.id).toList();

      print(
          'EditDealStatusScreen: Сохранение пользователей (просмотр): $userIds');
      print(
          'EditDealStatusScreen: Сохранение пользователей (изменение): $changeStatusUserIds');

      _dealBloc.add(
        UpdateDealStatusEdit(
          widget.dealStatusId,
          _titleController.text,
          _daysController.text.isNotEmpty
              ? int.tryParse(_daysController.text) ?? 0
              : 0,
          _isSuccess,
          _isFailure,
          _notificationMessageController.text,
          _showOnMainPage,
          localizations,
          userIds.isNotEmpty ? userIds : null,
          changeStatusUserIds.isNotEmpty
              ? changeStatusUserIds
              : null, // ✅ НОВОЕ
        ),
      );
    }
  }

  static Future<void> show(BuildContext context, int dealStatusId) {
    return showDialog(
      context: context,
      builder: (context) => EditDealStatusScreen(
        dealStatusId: dealStatusId,
      ),
    ).then((_) {
      final dealBloc = BlocProvider.of<DealBloc>(context, listen: false);
      dealBloc.add(FetchDealStatuses());
      dealBloc.add(FetchDeals(dealStatusId));
    });
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xff1E2E52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Text(label, style: _textStyle()),
      ],
    );
  }

  Widget _buildTextFieldWithLabel({
    required String label,
    required TextEditingController controller,
    bool isRequired = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: controller,
          hintText: hintText ?? '',
          label: label,
          validator: isRequired
              ? (value) => value!.isEmpty ? 'Поле обязательно' : null
              : null,
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: formatters,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DealBloc, DealState>(
      bloc: _dealBloc,
      listener: (context, state) {
        if (state is DealStatusLoaded && !_dataLoaded) {
          setState(() {
            _titleController.text = state.dealStatus.title;
            _daysController.text = state.dealStatus.day?.toString() ?? '';
            _isSuccess = state.dealStatus.isSuccess;
            _isFailure = state.dealStatus.isFailure;
            _notificationMessageController.text =
                state.dealStatus.notificationMessage ?? '';
            _showOnMainPage = state.dealStatus.showOnMainPage;

            // ✅ ОБНОВЛЕНО: Загружаем пользователей для ПРОСМОТРА
            _initialUserIds = state.dealStatus.users
                ?.map((user) => user.userId.toString())
                .toList();

            // ✅ НОВОЕ: Загружаем пользователей для ИЗМЕНЕНИЯ СТАТУСА
            _initialChangeStatusUserIds = state.dealStatus.changeStatusUsers
                ?.map((user) => user.userId.toString())
                .toList();

            print(
                'EditDealStatusScreen: Загружены пользователи (просмотр): $_initialUserIds');
            print(
                'EditDealStatusScreen: Загружены пользователи (изменение): $_initialChangeStatusUserIds');

            _dataLoaded = true;
          });
        } else if (state is DealStatusUpdatedEdit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Статус успешно обновлен!",
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
          final dealBloc = BlocProvider.of<DealBloc>(context, listen: false);
          dealBloc.add(FetchDealStatuses());
          dealBloc.add(FetchDeals(widget.dealStatusId));
          Navigator.of(context).pop();
        } else if (state is DealError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Ошибка обновления статуса!",
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
      builder: (context, state) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 400,
            height: 600,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Изменение статуса',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 24, color: Colors.grey[600]),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Основной контент
                  Expanded(
                    child: state is DealLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xff1E2E52)))
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextFieldWithLabel(
                                  label: 'Название',
                                  controller: _titleController,
                                  isRequired: true,
                                ),
                                const SizedBox(height: 20),

                                // ✅ ОБНОВЛЕНО: Два поля для выбора пользователей
                                if (_isMultiSelectEnabled) ...[
                                  // 1️⃣ ПЕРВОЕ ПОЛЕ: Пользователи, которые могут ВИДЕТЬ сделки
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isExpandedViewUsers =
                                            !_isExpandedViewUsers;
                                      });
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!
                                              .translate(
                                                  'users_who_can_view_deals'),
                                          style: _textStyle(),
                                          overflow: _isExpandedViewUsers
                                              ? TextOverflow.visible
                                              : TextOverflow.ellipsis,
                                          maxLines:
                                              _isExpandedViewUsers ? null : 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // const SizedBox(height: 8),
                                  UserMultiSelectWidget(
                                    selectedUsers: _initialUserIds,
                                    customLabelText:
                                        '', // ✅ Пустая строка, чтобы скрыть дефолтный заголовок
                                    onSelectUsers: (List<UserData> users) {
                                      setState(() {
                                        _selectedUsers = users;
                                      });
                                      print(
                                          'EditDealStatusScreen: Выбрано пользователей (просмотр): ${users.length}');
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // 2️⃣ ВТОРОЕ ПОЛЕ: Пользователи, которые могут ИЗМЕНЯТЬ статус
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isExpandedChangeUsers =
                                            !_isExpandedChangeUsers;
                                      });
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!
                                              .translate(
                                                  'users_who_can_change_status'),
                                          style: _textStyle(),
                                          overflow: _isExpandedChangeUsers
                                              ? TextOverflow.visible
                                              : TextOverflow.ellipsis,
                                          maxLines:
                                              _isExpandedChangeUsers ? null : 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // const SizedBox(height: 8),
                                  UserMultiSelectWidget(
                                    selectedUsers:
                                        _initialChangeStatusUserIds, // ✅ НОВОЕ: начальные данные
                                    customLabelText: '', // ✅ Пустая строка
                                    onSelectUsers: (List<UserData> users) {
                                      setState(() {
                                        _selectedChangeStatusUsers = users;
                                      });
                                      print(
                                          'EditDealStatusScreen: Выбрано пользователей (изменение): ${users.length}');
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isExpanded = !_isExpanded;
                                    });
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Укажите сколько дней может находиться сделка в этом статусе',
                                        style: _textStyle(),
                                        overflow: _isExpanded
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                        maxLines: _isExpanded ? null : 1,
                                      ),
                                    ],
                                  ),
                                ),
                                // const SizedBox(height: 0),
                                _buildTextFieldWithLabel(
                                  label: '',
                                  controller: _daysController,
                                  isRequired: false,
                                  keyboardType: TextInputType.number,
                                  formatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  hintText: 'Введите количество дней',
                                ),

                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isExpandedMessage = !_isExpandedMessage;
                                    });
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Введите текст который получит клиент при переходе его заказа в этот статус',
                                        style: _textStyle(),
                                        overflow: _isExpandedMessage
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                        maxLines: _isExpandedMessage ? null : 1,
                                      ),
                                    ],
                                  ),
                                ),
                                // const SizedBox(height: 0),
                                _buildTextFieldWithLabel(
                                  label: '',
                                  controller: _notificationMessageController,
                                  isRequired: false,
                                  hintText: 'Введите текст уведомления',
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_notificationMessageController
                                            .text.isNotEmpty) {
                                          setState(() {
                                            _notificationMessageController
                                                .text += ' %deal_number%';
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xff1E2E52),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: const Text(
                                        'Номер сделки',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_notificationMessageController
                                            .text.isNotEmpty) {
                                          setState(() {
                                            _notificationMessageController
                                                .text += ' %sum%';
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xff1E2E52),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: const Text(
                                        'Сумма',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildCheckbox(
                                        'Успешно',
                                        _isSuccess,
                                        (v) {
                                          if (v != null) {
                                            setState(() {
                                              _isSuccess = v;
                                              if (_isSuccess)
                                                _isFailure = false;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildCheckbox(
                                        'Не успешно',
                                        _isFailure,
                                        (v) {
                                          if (v != null) {
                                            setState(() {
                                              _isFailure = v;
                                              if (_isFailure)
                                                _isSuccess = false;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildCheckbox(
                                  'Показать на карточке лида',
                                  _showOnMainPage,
                                  (v) {
                                    if (v != null) {
                                      setState(() {
                                        _showOnMainPage = v;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xff1E2E52),
                      ),
                      child: TextButton(
                        onPressed: _saveChanges,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TextStyle _textStyle() => const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color.fromARGB(255, 0, 0, 0),
        overflow: TextOverflow.ellipsis,
      );
}
