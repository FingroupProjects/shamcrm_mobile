// order_status_add.dart
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
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

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    final colors = context.appColors;
    return Row(
      children: [
        Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: colors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Text(label, style: TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: colors.textPrimary,
          overflow: TextOverflow.ellipsis,
        )),
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
    final localizations = AppLocalizations.of(context);
    final colors = context.appColors;

    return BlocProvider.value(
      value: widget.orderBloc,
      child: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderStatusCreated) {
            showCustomSnackBar(
              context: context,
              message: 'status_created_successfully',
              isSuccess: true,
              aboveDialogs: true,
            );
            Navigator.of(context).pop(true);
          } else if (state is OrderError) {
            showCustomSnackBar(
              context: context,
              message: 'Ошибка создания статуса!',
              isSuccess: false,
              aboveDialogs: true,
            );
          }
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 400,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: colors.surfacePrimary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.borderSubtle.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations!.translate('add_status'),
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 24, color: colors.iconSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
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
                          const SizedBox(height: 16),
                          _buildTextFieldWithLabel(
                            label:
                                'Введите текст который получит клиент при переходе его заказа в этот статус',
                            controller: _messageController,
                            isRequired: true,
                            hintText: localizations.translate('Введите текст'),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
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
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _buildActionButton(
                        label: localizations.translate('cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                        backgroundColor: colors.buttonSecondaryBg,
                        foregroundColor: colors.buttonSecondaryFg,
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        label: localizations.translate('add'),
                        onPressed: () {
                          final title = _titleController.text.trim();
                          final message = _messageController.text.trim();

                          if (title.isNotEmpty && message.isNotEmpty) {
                            widget.orderBloc.add(CreateOrderStatus(
                              title: title,
                              notificationMessage: message,
                              isSuccess: _isSuccess,
                              isFailed: _isFailed,
                            ));
                          } else {
                            showCustomSnackBar(
                              context: context,
                              message: 'fill_all_required_fields',
                              isSuccess: false,
                              aboveDialogs: true,
                            );
                          }
                        },
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
