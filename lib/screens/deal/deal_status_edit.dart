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
  final String initialTitle;
  final int? day;
  final bool isSuccess;
  final bool isFailure;
  final int dealStatusId;

  EditDealStatusScreen({
    required this.initialTitle,
    this.day,
    this.isSuccess = false,
    this.isFailure = false,
    required this.dealStatusId,
  });

  @override
  _EditDealStatusScreenState createState() => _EditDealStatusScreenState();
}

class _EditDealStatusScreenState extends State<EditDealStatusScreen> {
  late TextEditingController _titleController;
  late TextEditingController _daysController;
  bool _isSuccess = false;
  bool _isFailure = false;
  late DealBloc _dealBloc;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _daysController = TextEditingController(text: widget.day?.toString() ?? '');
    _isSuccess = widget.isSuccess;
    _isFailure = widget.isFailure;
    _dealBloc = DealBloc(ApiService());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _daysController.dispose();
    _dealBloc.close();
    super.dispose();
  }

// В методе сохранения
void _saveChanges() {
  final localizations = AppLocalizations.of(context);
  if (localizations != null) {
    _dealBloc.add(
      UpdateDealStatusEdit(
        widget.dealStatusId,
        _titleController.text,
        _daysController.text.isNotEmpty 
            ? int.tryParse(_daysController.text) ?? 0 // Всегда возвращает int
            : 0, // Значение по умолчанию
        _isSuccess,
        _isFailure,
        localizations,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка локализации: не удалось загрузить переводы.'),
      ),
    );
  }
}
  Widget _buildCheckbox(bool value, Function(bool?) onChanged) =>
      Transform.scale(
        scale: 0.9,
        child: Checkbox(
          value: value,
          onChanged: onChanged,
            activeColor: const Color(0xff1E2E52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocListener<DealBloc, DealState>(
      bloc: _dealBloc,
      listener: (context, state) {
        if (state is DealStatusUpdatedEdit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.of(context).pop();
        } else if (state is DealError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: EdgeInsets.all(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
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
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24, color: Colors.grey[600]),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildTextFieldWithLabel(
                label: 'Название',
                controller: _titleController,
                isRequired: true,
              ),
              SizedBox(height: 20),
              _buildTextFieldWithLabel(
                label: 'Укажите сколько дней может находиться сделка в этом статусе',
                controller: _daysController,
                isRequired: false,
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                hintText: 'Введите количество дней',
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  _buildCheckbox(
                    _isSuccess,
                    (v) => setState(() {
                      _isSuccess = v!;
                      if (_isSuccess) _isFailure = false;
                    }),
                  ),
                  Text('Успешно', style: _textStyle()),
                  SizedBox(width: 24),
                  _buildCheckbox(
                    _isFailure,
                    (v) => setState(() {
                      _isFailure = v!;
                      if (_isFailure) _isSuccess = false;
                    }),
                  ),
                  Text('Не успешно', style: _textStyle()),
                ],
              ),
              SizedBox(height: 24),
              Align(
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  color: Color(0xff1E2E52),
                  ),
                  child: TextButton(
                    onPressed: _saveChanges,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: Text(
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
  }Widget _buildTextFieldWithLabel({
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
      // УДАЛИТЕ RichText, если CustomTextField уже отображает label
      CustomTextField(
        controller: controller,
        hintText: hintText ?? '',
        label: label, // Передаем метку только сюда
        validator: isRequired
            ? (value) => value!.isEmpty ? 'Поле обязательно' : null
            : null,
        keyboardType: keyboardType ?? TextInputType.text,
        inputFormatters: formatters,
      ),
    ],
  );
}
  TextStyle _textStyle() => TextStyle(
    fontSize: 16,
    fontFamily: 'Gilroy',
    fontWeight: FontWeight.w500,
    color: const Color.fromARGB(255, 0, 0, 0),
  );
}