import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:intl/intl.dart'; // For date formatting

class CreateNotesDialog extends StatefulWidget {
  final int leadId;

  CreateNotesDialog({required this.leadId});

  @override
  _CreateNotesDialogState createState() => _CreateNotesDialogState();
}

class _CreateNotesDialogState extends State<CreateNotesDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Добавить заметку',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: bodyController,
              hintText: 'Введите название',
              label: 'Название',
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Поле обязательно для заполнения';
                }
                return null; 
              },
            ),
            SizedBox(height: 16),
            CustomTextFieldDate(
              controller: dateController,
              label: 'Дата',
            ),
            SizedBox(height: 16),
            CustomButton(
              buttonText: 'Сохранить',
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final String body = bodyController.text;
                  final String? dateString = dateController.text.isEmpty
                      ? null
                      : dateController.text;

                  DateTime? date;
                  if (dateString != null && dateString.isNotEmpty) {
                    try {
                      date = DateFormat('dd/MM/yyyy').parse(dateString);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Введите корректную дату в формате ДД/ММ/ГГГГ'),
                        ),
                      );
                      return; 
                    }
                  }
                  context.read<NotesBloc>().add(CreateNotes(
                        leadId: widget.leadId,
                        body: body,
                        date: date,
                      ));

                  Navigator.pop(context); 
                }
              },
              buttonColor: Color(0xff1E2E52),
              textColor: Colors.white,
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
