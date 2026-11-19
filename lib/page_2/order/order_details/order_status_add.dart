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
  final bool chessStatuses;

  const CreateOrderStatusDialog({
    super.key,
    required this.orderBloc,
    this.chessStatuses = false,
  });

  @override
  State<CreateOrderStatusDialog> createState() =>
      _CreateOrderStatusDialogState();
}

class _CreateOrderStatusDialogState extends State<CreateOrderStatusDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSuccess = false;
  bool _isFailed = false;
  bool _isBooked = false;
  bool _isReserved = false;
  bool _submitting = false;

  void _setStatusFlag({bool? success, bool? failed, bool? booked, bool? reserved}) {
    setState(() {
      if (success == true) {
        _isSuccess = true;
        _isFailed = false;
        _isBooked = false;
        _isReserved = false;
      } else if (failed == true) {
        _isFailed = true;
        _isSuccess = false;
        _isBooked = false;
        _isReserved = false;
      } else if (booked == true) {
        _isBooked = true;
        _isSuccess = false;
        _isFailed = false;
        _isReserved = false;
      } else if (reserved == true) {
        _isReserved = true;
        _isSuccess = false;
        _isFailed = false;
        _isBooked = false;
      } else {
        if (success == false) _isSuccess = false;
        if (failed == false) _isFailed = false;
        if (booked == false) _isBooked = false;
        if (reserved == false) _isReserved = false;
      }
    });
  }

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
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ),
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
            Navigator.of(context).pop(true);
          } else if (state is OrderError) {
            if (mounted) setState(() => _submitting = false);
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
                            isRequired: false,
                            hintText: localizations.translate('Введите текст'),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCheckbox(
                                        localizations.translate('successful'),
                                        _isSuccess,
                                        (v) {
                                          if (v != null) _setStatusFlag(success: v);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildCheckbox(
                                        localizations.translate('is_failed'),
                                        _isFailed,
                                        (v) {
                                          if (v != null) _setStatusFlag(failed: v);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.chessStatuses) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCheckbox(
                                          localizations.translate('chess_grid_booked'),
                                          _isBooked,
                                          (v) {
                                            if (v != null) _setStatusFlag(booked: v);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildCheckbox(
                                          localizations.translate('chess_grid_reserved'),
                                          _isReserved,
                                          (v) {
                                            if (v != null) _setStatusFlag(reserved: v);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                        onPressed: _submitting
                            ? () {}
                            : () {
                          final title = _titleController.text.trim();
                          final message = _messageController.text.trim();

                          if (title.isNotEmpty) {
                            setState(() => _submitting = true);
                            widget.orderBloc.add(CreateOrderStatus(
                              title: title,
                              notificationMessage: message,
                              isSuccess: _isSuccess,
                              isFailed: _isFailed,
                              isBooked: widget.chessStatuses ? _isBooked : null,
                              isReserved: widget.chessStatuses ? _isReserved : null,
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
