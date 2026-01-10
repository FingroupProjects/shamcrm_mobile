import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/models/user_data_response.dart'; // ✅ ДОБАВИТЬ ИМПОРТ
import 'package:crm_task_manager/screens/task/task_details/user_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ ДОБАВИТЬ ИМПОРТ

class CreateStatusDialog extends StatefulWidget {
  CreateStatusDialog({Key? key}) : super(key: key);

  @override
  _CreateStatusDialogState createState() => _CreateStatusDialogState();
}

class _CreateStatusDialogState extends State<CreateStatusDialog> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _notificationMessageController = TextEditingController();
  String? _errorMessage;
  String? _dayErrorMessage;
  bool _isTextExpanded = false;
  bool _isExpandedMessage = false;
  bool _showOnMainPage = false;
  bool _isSuccess = false;
  bool _isFailure = false;
  bool _isMultiSelectEnabled = false; // ✅ НОВОЕ: флаг мультивыбора
  List<UserData> _selectedUsers = []; // ✅ НОВОЕ: выбранные пользователи
    List<UserData> _selectedChangeStatusUsers = []; // ✅ НОВОЕ: пользователи, которые могут ИЗМЕНЯТЬ статус
 bool _isExpandedViewUsers = false; // ✅ НОВОЕ: для expandable текста первого поля
  bool _isExpandedChangeUsers = false; // ✅ НОВОЕ: для expandable текста второго поля

  @override
  void initState() {
    super.initState();
    _loadMultiSelectSetting(); // ✅ НОВОЕ: загружаем настройку
  }

  // ✅ ОБНОВЛЁННАЯ ЛОГИКА
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
    
    debugPrint('CreateStatusDialog: managing_deal_status_visibility = $managingVisibility');
    debugPrint('CreateStatusDialog: change_deal_to_multiple_statuses = $changeMultiple');
    debugPrint('CreateStatusDialog: _isMultiSelectEnabled = $value');
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

  TextStyle _textStyle() => const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color.fromARGB(255, 0, 0, 0),
        overflow: TextOverflow.ellipsis,
      );

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocListener<DealBloc, DealState>(
      listener: (context, state) {
        if (state is DealSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.translate('status_created_successfully'),
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
          Navigator.of(context).pop(true);
        } else if (state is DealError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
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
      child: Dialog(
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
                      localizations.translate('add_status'),
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 24, color: Colors.grey[600]),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Основной контент
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextFieldWithLabel(
                          label: localizations.translate('event_name'),
                          controller: _controller,
                          isRequired: true,
                          hintText: localizations.translate('enter_title'),
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        
                        // ✅ НОВОЕ: Поле выбора пользователей (только если включен мультивыбор)
                        // ✅ НОВОЕ: Поле выбора пользователей (только если включен мультивыбор)
if (_isMultiSelectEnabled) ...[
  // 1️⃣ ПЕРВОЕ ПОЛЕ: Пользователи, которые могут ВИДЕТЬ сделки
  GestureDetector(
    onTap: () {
      setState(() {
        _isExpandedViewUsers = !_isExpandedViewUsers;
      });
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('users_who_can_view_deals'),
          style: _textStyle(),
          overflow: _isExpandedViewUsers ? TextOverflow.visible : TextOverflow.ellipsis,
          maxLines: _isExpandedViewUsers ? null : 1,
        ),
      ],
    ),
  ),
  // const SizedBox(height: 8),
  UserMultiSelectWidget(
    selectedUsers: null,
    customLabelText: '', // ✅ Пустая строка, чтобы скрыть дефолтный заголовок
    onSelectUsers: (List<UserData> users) {
      setState(() {
        _selectedUsers = users;
      });
      debugPrint('CreateStatusDialog: Выбрано пользователей (просмотр): ${users.length}');
    },
  ),
  const SizedBox(height: 20),
  
  // 2️⃣ ВТОРОЕ ПОЛЕ: Пользователи, которые могут ИЗМЕНЯТЬ статус
  GestureDetector(
    onTap: () {
      setState(() {
        _isExpandedChangeUsers = !_isExpandedChangeUsers;
      });
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('users_who_can_change_status'),
          style: _textStyle(),
          overflow: _isExpandedChangeUsers ? TextOverflow.visible : TextOverflow.ellipsis,
          maxLines: _isExpandedChangeUsers ? null : 1,
        ),
      ],
    ),
  ),
  // const SizedBox(height: 8),
  UserMultiSelectWidget(
    selectedUsers: null,
    customLabelText: '', // ✅ Пустая строка, чтобы скрыть дефолтный заголовок
    onSelectUsers: (List<UserData> users) {
      setState(() {
        _selectedChangeStatusUsers = users;
      });
      debugPrint('CreateStatusDialog: Выбрано пользователей (изменение): ${users.length}');
    },
  ),
  const SizedBox(height: 20),
],
                        
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isTextExpanded = !_isTextExpanded;
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.translate('how_many_days_in_status'),
                                style: _textStyle(),
                                overflow: _isTextExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                maxLines: _isTextExpanded ? null : 1,
                              ),
                            ],
                          ),
                        ),
                        // const SizedBox(height: 0),
                        _buildTextFieldWithLabel(
                          label: '',
                          controller: _dayController,
                          isRequired: false,
                          keyboardType: TextInputType.number,
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                          hintText: localizations.translate('enter_number_day'),
                        ),
                        if (_dayErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _dayErrorMessage!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                       
                        // const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpandedMessage = !_isExpandedMessage;
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.translate('notification_message_label'),
                                style: _textStyle(),
                                overflow: _isExpandedMessage ? TextOverflow.visible : TextOverflow.ellipsis,
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
                          hintText: localizations.translate('enter_notification_message'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                if (_notificationMessageController.text.isNotEmpty) {
                                  setState(() {
                                    _notificationMessageController.text += ' %deal_number%';
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff1E2E52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                localizations.translate('deal_number'),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (_notificationMessageController.text.isNotEmpty) {
                                  setState(() {
                                    _notificationMessageController.text += ' %sum%';
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff1E2E52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                localizations.translate('sum'),
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
                                localizations.translate('successful'),
                                _isSuccess,
                                (v) {
                                  if (v != null) {
                                    setState(() {
                                      _isSuccess = v;
                                      if (_isSuccess) _isFailure = false;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildCheckbox(
                                localizations.translate('unsuccessful'),
                                _isFailure,
                                (v) {
                                  if (v != null) {
                                    setState(() {
                                      _isFailure = v;
                                      if (_isFailure) _isSuccess = false;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCheckbox(
                          localizations.translate('show_on_main_page'),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xff1E2E52),
                        ),
                        child: TextButton(
                          onPressed: () {
                            final title = _controller.text;
                            final dayString = _dayController.text;

                            if (title.isNotEmpty) {
                              setState(() {
                                _errorMessage = null;
                                _dayErrorMessage = null;
                              });

                              final day = dayString.isNotEmpty ? int.tryParse(dayString) : null;

                              if (dayString.isNotEmpty && day == null) {
                                setState(() {
                                  _dayErrorMessage = localizations.translate('enter_valid_number_day');
                                });
                                return;
                              }

                              // ✅ НОВОЕ: Получаем список ID пользователей
                              final userIds = _selectedUsers.map((user) => user.id).toList();
                                  final changeStatusUserIds = _selectedChangeStatusUsers.map((user) => user.id).toList();

                              
                              debugPrint('CreateStatusDialog: Отправка статуса с пользователями: $userIds');
    debugPrint('CreateStatusDialog: Пользователи (изменение): $changeStatusUserIds');

                              context.read<DealBloc>().add(
                                    CreateDealStatus(
                                      title: title,
                                      color: '#000',
                                      day: day,
                                      notificationMessage: _notificationMessageController.text,
                                      showOnMainPage: _showOnMainPage,
                                      isSuccess: _isSuccess,
                                      isFailure: _isFailure,
                                      userIds: userIds.isNotEmpty ? userIds : null, // ✅ НОВОЕ
                                              changeStatusUserIds: changeStatusUserIds.isNotEmpty ? changeStatusUserIds : null, // ✅ НОВОЕ

                                      localizations: localizations,
                                    ),
                                  );
                            } else {
                              setState(() {
                                _errorMessage = localizations.translate('enter_textfield');
                              });
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          ),
                          child: Text(
                            localizations.translate('add'),
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
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
}