import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class EditLeadStatusScreen extends StatefulWidget {
  final int leadStatusId;

  const EditLeadStatusScreen({
    Key? key,
    required this.leadStatusId,
  }) : super(key: key);

  @override
  _EditLeadStatusScreenState createState() => _EditLeadStatusScreenState();
}

class _EditLeadStatusScreenState extends State<EditLeadStatusScreen> {
  late TextEditingController _titleController;
  bool _isSuccess = false;
  bool _isFailure = false;
  bool _isUnassembled = false;
  late LeadBloc _leadBloc;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _leadBloc = LeadBloc(ApiService());
    _loadLeadStatus();
  }

  void _loadLeadStatus() {
    _leadBloc.add(FetchLeadStatus(widget.leadStatusId));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _leadBloc.close();
    super.dispose();
  }

  void _saveChanges() {
    final leadBloc = BlocProvider.of<LeadBloc>(context);
    leadBloc.add(FetchLeadStatuses());
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      _leadBloc.add(
        UpdateLeadStatusEdit(
          widget.leadStatusId,
          _titleController.text,
          _isSuccess,
          _isFailure,
          _isUnassembled,
          localizations,
        ),
      );
    }
  }

  // Метод для показа диалога редактирования
  static Future<void> show(BuildContext context, int leadStatusId) {
    return showDialog(
      context: context,
      builder: (context) => EditLeadStatusScreen(
        leadStatusId: leadStatusId,
      ),
    ).then((_) {
      // После закрытия диалога обновляем данные
      final dealBloc = BlocProvider.of<LeadBloc>(context, listen: false);
      // Обновляем список статусов
      dealBloc.add(FetchLeadStatuses());
      // Обновляем сделки для текущего статуса
      dealBloc.add(FetchLeads(leadStatusId));
    });
  }

  Widget _buildCheckbox(
    BuildContext context,
    String label,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: context.appColors.buttonPrimaryBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Text(label, style: _textStyle(context)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LeadBloc, LeadState>(
      bloc: _leadBloc,
      listener: (context, state) {
        if (state is LeadStatusLoaded && !_dataLoaded) {
          setState(() {
            _titleController.text = state.leadStatus.title;
            _isSuccess = state.leadStatus.isSuccess;
            _isFailure = state.leadStatus.isFailure;
            _isUnassembled = state.leadStatus.isUnassembled;
            _dataLoaded = true;
          });
        } else if (state is LeadStatusUpdatedEdit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Статус успешно обновлен!",
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.success,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
          // После успешного обновления статуса
          final dealBloc = BlocProvider.of<LeadBloc>(context, listen: false);
          // Обновляем список статусов
          dealBloc.add(FetchLeadStatuses());
          // Обновляем сделки для текущего статуса
          dealBloc.add(FetchLeads(widget.leadStatusId));

          Navigator.of(context).pop();
        } else if (state is LeadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Ошибка обновления статуса!",
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.error,
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
            height: 360,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: context.appColors.textInverse,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Изменение статуса',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                          size: 24, color: context.appColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: state is LeadLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: context.appColors.buttonPrimaryBg,
                            ),
                          )
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildCheckbox(
                                        context,
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
                                        context,
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
                                  context,
                                  'Неразобранные',
                                  _isUnassembled,
                                  (v) {
                                    if (v != null) {
                                      setState(() {
                                        _isUnassembled = v;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                  ),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: context.appColors.buttonPrimaryBg,
                      ),
                      child: TextButton(
                        onPressed: _saveChanges,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'Сохранить',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: context.appColors.backgroundPrimary,
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

  TextStyle _textStyle(BuildContext context) => TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: context.appColors.textPrimary,
        overflow: TextOverflow.ellipsis,
      );
}
