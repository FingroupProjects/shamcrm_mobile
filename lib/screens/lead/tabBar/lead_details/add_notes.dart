import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:crm_task_manager/bloc/notes/notes_state.dart';
import 'package:crm_task_manager/screens/event/event_details/managers_event.dart';
import 'package:crm_task_manager/screens/event/event_details/notice_subject_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
  List<int> selectedManagers = [];
  String? selectedSubject;

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotesBloc, NotesState>(
      listener: (context, state) {
        if (state is NotesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!
                    .translate(state.message), // Локализация сообщения
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
        child: GestureDetector(
        onTap: () {
            FocusScope.of(context).unfocus();
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
                  AppLocalizations.of(context)!.translate('add_note'),
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
                SizedBox(height: 8),
                SubjectSelectionWidget(
                  selectedSubject: selectedSubject,
                  onSelectSubject: (String subject) {
                    setState(() {
                      selectedSubject = subject;
                    });
                  },
                ),
                SizedBox(height: 8),
                CustomTextField(
                  controller: bodyController,
                  hintText:
                      AppLocalizations.of(context)!.translate('enter_text'),
                  label: AppLocalizations.of(context)!
                      .translate('description_list'),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.translate('field_required');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                CustomTextFieldDate(
                  controller: dateController,
                  label: AppLocalizations.of(context)!.translate('reminder'),
                  withTime: true,
                ),
                const SizedBox(height: 8),
                ManagerMultiSelectWidget(
                  selectedManagers: selectedManagers, 
                  onSelectManagers: (List<int> managers) {
                    setState(() {
                      selectedManagers = managers;
                    });
                  },
                ),
                SizedBox(height: 8),
                CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('save'),
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
                              AppLocalizations.of(context)!
                                  .translate('enter_valid_datetime'),
                            )),
                          );
                          return;
                        }
                      }

                      context.read<NotesBloc>().add(CreateNotes(
                            leadId: widget.leadId,
                            title: selectedSubject!.trim(), 
                            body: body,
                            date: date,
                            users: selectedManagers,
                          ));

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.translate('note_created_successfully'),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin:EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.green,
                          elevation: 3,
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
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
      ),
    );
  }
}
