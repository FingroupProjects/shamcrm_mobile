import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:crm_task_manager/bloc/notes/notes_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/notes_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class NotesWidget extends StatefulWidget {
  final int leadId;

  NotesWidget({required this.leadId});

  @override
  _NotesWidgetState createState() => _NotesWidgetState();
}

class _NotesWidgetState extends State<NotesWidget> {
  List<Notes> notes = [];

  @override
  void initState() {
    super.initState();
    context.read<NotesBloc>().add(FetchNotes(widget.leadId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesBloc, NotesState>(
      builder: (context, state) {
        if (state is NotesLoading) {
          // return Center(child: CircularProgressIndicator());
        } else if (state is NotesLoaded) {
          notes = state.notes;
        } else if (state is NotesError) {
          return Center(child: Text(state.message));
        }

        return _buildNotesList(notes);
      },
    );
  }

  Widget _buildNotesList(List<Notes> notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTitleRow('Заметки'),
        SizedBox(height: 8),
        ...notes.map((note) => _buildNoteItem(note)).toList(),
        if (notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Пока здесь нет заметок',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xfff1E2E52),
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoteItem(Notes note) {
    final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(note.date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: TaskCardStyles.taskCardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(
                'assets/icons/leads/notes.png',
                width: 24,
                height: 24,
                color: Color(0xff1E2E52),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.body,
                      style: TaskCardStyles.titleStyle,
                    ),
                    SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TaskCardStyles.priorityStyle.copyWith(
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TaskCardStyles.titleStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            // Handle button press to open the bottom dialog
            _onCreateNotePressed();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: Color(0xff1E2E52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Добавить',
            style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _onCreateNotePressed() {
    _showAddNoteDialog();
  }

  void _showAddNoteDialog() {
    final TextEditingController dateController =
        TextEditingController(); // For date input
    final TextEditingController bodyController =
        TextEditingController(); // For body input

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.white, // Set the background color of the bottom sheet
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
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
                maxLines: 5, // Set maxLines for body input
              ),
              SizedBox(height: 16),
              CustomTextFieldDate(
                controller: dateController,
                label: 'Дата', // Set the label for the date field
              ),
              SizedBox(height: 16),
              CustomButton(
                buttonText: 'Сохранить',
                onPressed: () {
                  // final newNote = Notes(
                  //   id: 0, // Adjust accordingly, you might need an ID generation mechanism
                  //   leadId: widget.leadId,
                  //   body: bodyController.text,
                  //   date: dateController.text, // Use the selected date here
                  //   date: DateTime.now(),
                  // );
                  // context.read<NotesBloc>().add(AddNote(newNote)); // Replace with your add note event
                  Navigator.pop(context); // Close the dialog
                },
                buttonColor: Color(0xff1E2E52), // Customize as needed
                textColor: Colors.white, // Customize as needed
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
