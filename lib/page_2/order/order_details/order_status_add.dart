// order_status_add.dart
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateOrderStatusDialog extends StatefulWidget {
  final OrderBloc orderBloc;

  const CreateOrderStatusDialog({super.key, required this.orderBloc});

  @override
  State<CreateOrderStatusDialog> createState() =>
      _CreateOrderStatusDialogState();
}

class _CreateOrderStatusDialogState extends State<CreateOrderStatusDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSuccess = false;
  bool _isFailed = false;
  bool _isExpanded = false;

  @override
  void dispose() {
    print('CreateOrderStatusDialog: Вызов dispose');
    _titleController.dispose();
    _messageController.dispose();
    print('CreateOrderStatusDialog: Контроллеры освобождены');
    super.dispose();
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print('CreateOrderStatusDialog: Начало build');
    final localizations = AppLocalizations.of(context);

    return BlocProvider.value(
      value: widget.orderBloc,
      child: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          // print(
          //     'CreateOrderStatusDialog: BlocListener, текущее состояние: ${state.runtimeType}');
          if (state is OrderStatusCreated) {
            // print(
            //     'CreateOrderStatusDialog: Получено состояние OrderStatusCreated, закрываем диалог');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Статус успешно создан!",
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.green,
                elevation: 3,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is OrderError) {
            // print(
            //     'CreateOrderStatusDialog: Получено состояние OrderError, сообщение об ошибке уже обрабатывается в OrderScreen');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Ошибка создания статуса!",
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.red,
                elevation: 3,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: const Duration(seconds: 3),
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
            height: 480,
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
                        localizations!.translate('add_status'),
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
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextFieldWithLabel(
                            label: localizations.translate('event_name'),
                            controller: _titleController,
                            isRequired: true,
                            hintText: 'Введите название',
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text(
                                //   localizations.translate('notification_message'),
                                //   style: _textStyle(),
                                //   overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                //   maxLines: _isExpanded ? null : 1,
                                // ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 0),
                          _buildTextFieldWithLabel(
                            label: 'Введите текст который получит клиент при переходе его заказа в этот статус',
                            controller: _messageController,
                            isRequired: true,
                            hintText:
                                localizations.translate('Введите текст'),
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
                                        if (_isSuccess) _isFailed = false;
                                      });
                                      // print(
                                      //     'CreateOrderStatusDialog: _isSuccess изменен на $_isSuccess');
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildCheckbox(
                                  localizations.translate('is_failed'),
                                  _isFailed,
                                  (v) {
                                    if (v != null) {
                                      setState(() {
                                        _isFailed = v;
                                        if (_isFailed) _isSuccess = false;
                                      });
                                      // print(
                                      //     'CreateOrderStatusDialog: _isFailed изменен на $_isFailed');
                                    }
                                  },
                                ),
                              ),
                            ],
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
                        onPressed: () {
                          // print(
                          //     'CreateOrderStatusDialog: Нажата кнопка "Добавить"');
                          final title = _titleController.text.trim();
                          final message = _messageController.text.trim();
                          // print(
                          //     'CreateOrderStatusDialog: title=$title, message=$message, isSuccess=$_isSuccess, isFailed=$_isFailed');

                          if (title.isNotEmpty && message.isNotEmpty) {
                            widget.orderBloc.add(CreateOrderStatus(
                              title: title,
                              notificationMessage: message,
                              isSuccess: _isSuccess,
                              isFailed: _isFailed,
                            ));
                            // print(
                            //     'CreateOrderStatusDialog: Добавлено событие CreateOrderStatus');
                          } else {
                            // print(
                            //     'CreateOrderStatusDialog: Поля пусты, показываем ошибку');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localizations.translate('fill_all_fields'),
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          localizations.translate('add'),
                          style: const TextStyle(
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
        ),
      ),
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
