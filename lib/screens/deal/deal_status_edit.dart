import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _isSuccess = false;
  bool _isFailure = false;
  late DealBloc _dealBloc;
  bool _dataLoaded = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _daysController = TextEditingController();
    _dealBloc = DealBloc(ApiService());
    _loadDealStatus();
  }

  void _loadDealStatus() {
    _dealBloc.add(FetchDealStatus(widget.dealStatusId));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _daysController.dispose();
    _dealBloc.close();
    super.dispose();
  }

void _saveChanges() {
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      _dealBloc.add(
        UpdateDealStatusEdit(
          widget.dealStatusId,
          _titleController.text,
          _daysController.text.isNotEmpty
              ? int.tryParse(_daysController.text) ?? 0
              : 0,
          _isSuccess,
          _isFailure,
          localizations,
        ),
      );
    }
  }

  // Метод для показа диалога редактирования
  static Future<void> show(BuildContext context, int dealStatusId) {
    return showDialog(
      context: context,
      builder: (context) => EditDealStatusScreen(
        dealStatusId: dealStatusId,
      ),
    ).then((_) {
      // После закрытия диалога обновляем данные
      final dealBloc = BlocProvider.of<DealBloc>(context, listen: false);
      // Обновляем список статусов
      dealBloc.add(FetchDealStatuses());
      // Обновляем сделки для текущего статуса
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
          _daysController.text = state.dealStatus.day.toString();
          _isSuccess = state.dealStatus.isSuccess;
          _isFailure = state.dealStatus.isFailure;
          _dataLoaded = true;
        });
      } else if (state is DealStatusUpdatedEdit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
        final dealBloc = BlocProvider.of<DealBloc>(context, listen: false);
        dealBloc.add(FetchDealStatuses());
        dealBloc.add(FetchDeals(widget.dealStatusId));
        Navigator.of(context).pop();
      } else if (state is DealError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
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
          height: 450,
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
                  child: state is DealLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)))
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextFieldWithLabel(
                                label: 'Название',
                                controller: _titleController,
                                isRequired: true,
                              ),
                              const SizedBox(height: 20), // Уменьшили отступ
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isExpanded = !_isExpanded;
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Укажите сколько дней может находиться сделка в этом статусе',
                                      style: _textStyle(),
                                      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                      maxLines: _isExpanded ? null : 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 0), // Уменьшили отступ
                              _buildTextFieldWithLabel(
                                label: '',
                                controller: _daysController,
                                isRequired: false,
                                keyboardType: TextInputType.number,
                                formatters: [FilteringTextInputFormatter.digitsOnly],
                                hintText: 'Введите количество дней',
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
                                            if (_isSuccess) _isFailure = false;
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
                                            if (_isFailure) _isSuccess = false;
                                          });
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
