import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController titleController = TextEditingController(); 
  bool _sendPushNotification = false;

  @override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Padding(
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
            SizedBox(height: 8),
            CustomTextField(
              controller: titleController,
              hintText: 'Введите заголовок',
              label: 'Заголовок',
              maxLines: 1,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Поле обязательно для заполнения';
                }
                return null;
              },
            ),
            SizedBox(height: 8),
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
            SizedBox(height: 8),
            CustomTextFieldDate(
              controller: dateController,
              label: 'Дата',
              withTime: true,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _sendPushNotification = !_sendPushNotification;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xff1E2E52)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: Icon(
                        _sendPushNotification ? Icons.check : Icons.clear,
                        color: _sendPushNotification
                            ? Color(0xff1E2E52)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _sendPushNotification = !_sendPushNotification;
                      });
                    },
                    child: Text(
                      'Отправить пуш уведомления',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            CustomButton(
              buttonText: 'Сохранить',
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final String title = titleController.text;
                  final String body = bodyController.text;
                  final String? dateString =
                      dateController.text.isEmpty ? null : dateController.text;

                  DateTime? date;
                  if (dateString != null && dateString.isNotEmpty) {
                    try {
                      date = DateFormat('dd/MM/yyyy HH:mm').parse(dateString);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Введите корректную дату и время в формате ДД/ММ/ГГГГ ЧЧ:ММ'),
                        ),
                      );
                      return;
                    }
                  }
                  context.read<NotesBloc>().add(CreateNotes(
                        leadId: widget.leadId,
                        title: title,
                        body: body,
                        date: date,
                        sendNotification: _sendPushNotification,
                      ));

                  Navigator.pop(context);
                }
              },
              buttonColor: Color(0xff1E2E52),
              textColor: Colors.white,
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
}