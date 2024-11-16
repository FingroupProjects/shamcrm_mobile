import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateStatusDialog extends StatefulWidget {
  CreateStatusDialog({Key? key}) : super(key: key);

  @override
  _CreateStatusDialogState createState() => _CreateStatusDialogState();
}

class _CreateStatusDialogState extends State<CreateStatusDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        'Добавить статуса',
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xfff1E2E52),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Введите название',
              hintStyle: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xfff1E2E52),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Color(0xffF4F7FD),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
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
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: CustomButton(
                buttonText: 'Отмена',
                onPressed: () {
                  Navigator.of(context).pop();
                },
                buttonColor: Colors.red,
                textColor: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                buttonText: 'Добавить',
                onPressed: () {
                  final title = _controller.text;
                  final color = '#000';
                  if (title.isNotEmpty) {
                    setState(() {
                      _errorMessage = null;
                    });
                    context
                        .read<LeadBloc>()
                        .add(CreateLeadStatus(title: title, color: color));
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      _errorMessage = 'Заполните поля';
                    });
                  }
                },
                buttonColor: Color(0xff1E2E52),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
