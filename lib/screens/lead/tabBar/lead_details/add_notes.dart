import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:crm_task_manager/bloc/notes/notes_state.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotesBloc, NotesState>(
      listener: (context, state) {
        if (state is NotesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${state.message}',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.green,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      
      child: SingleChildScrollView(
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
                  hintText: 'Введите название',
                  label: 'Тематика',
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
                  hintText: 'Введите текст',
                  label: 'Описание',
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
                  label: 'Напоминание',
                  withTime: true,
                ),
                SizedBox(height: 8),
                CustomButton(
                  buttonText: 'Сохранить',
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final String title = titleController.text;
                      final String body = bodyController.text;
                      final String? dateString = dateController.text.isEmpty
                          ? null
                          : dateController.text;

                      DateTime? date;
                      if (dateString != null && dateString.isNotEmpty) {
                        try {
                          date =
                              DateFormat('dd/MM/yyyy HH:mm').parse(dateString);
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
                          ));

                        ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           content: Text(
                             'Заметка успешно создана!',
                             style: TextStyle(
                               fontFamily: 'Gilroy',
                               fontSize: 16, 
                               fontWeight: FontWeight.w500, 
                               color: Colors.white, 
                             ),
                           ),
                           behavior: SnackBarBehavior.floating,
                           margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                           ),
                           backgroundColor: Colors.green,
                           elevation: 3,
                           padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), 
                           duration: Duration(seconds: 3),
                         ),
                      );
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
      ),
    );
  }
}
