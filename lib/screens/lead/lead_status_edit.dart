import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class EditLeadStatusScreen extends StatefulWidget {
  final String initialTitle;
  final bool isSuccess;
  final bool isFailure;
  final int leadStatusId;

  EditLeadStatusScreen({
    required this.initialTitle,
    this.isSuccess = false,
    this.isFailure = false,
    required this.leadStatusId,
  });

  @override
  _EditLeadStatusScreenState createState() => _EditLeadStatusScreenState();
}

class _EditLeadStatusScreenState extends State<EditLeadStatusScreen> {
  late TextEditingController _titleController;
  bool _isSuccess = false;
  bool _isFailure = false;
  late LeadBloc _leadBloc;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _isSuccess = widget.isSuccess;
    _isFailure = widget.isFailure;
    _leadBloc = LeadBloc(ApiService());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _leadBloc.close();
    super.dispose();
  }

  void _saveChanges() {
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      _leadBloc.add(
        UpdateLeadStatusEdit(
          widget.leadStatusId,
          _titleController.text,
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

  Widget _buildCheckbox(bool value, Function(bool?) onChanged) => Transform.scale(
    scale: 0.9,
    child: Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue[600],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );

  TextStyle _checkTextStyle() => TextStyle(
    fontSize: 14,
    fontFamily: 'Gilroy',
    fontWeight: FontWeight.w500,
    color: Colors.grey[800],
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadBloc, LeadState>(
      bloc: _leadBloc,
      listener: (context, state) {
        if (state is LeadStatusUpdatedEdit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.of(context).pop();
        } else if (state is LeadError) {
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
              Text(
                'Название',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
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
                  Text('Успешно', style: _checkTextStyle()),
                  SizedBox(width: 24),
                  _buildCheckbox(
                    _isFailure,
                    (v) => setState(() {
                      _isFailure = v!;
                      if (_isFailure) _isSuccess = false;
                    }),
                  ),
                  Text('Не успешно', style: _checkTextStyle()),
                ],
              ),
              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.blue[600],
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
                        fontWeight: FontWeight.w600,
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
  }
}