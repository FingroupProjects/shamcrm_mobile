import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:crm_task_manager/bloc/notes/notes_state.dart';
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
  bool isNotesExpanded = false;
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

        return _buildExpandableNotesContainer(notes);
      },
    );
  }

  Widget _buildExpandableNotesContainer(List<Notes> notes) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isNotesExpanded = !isNotesExpanded;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleRow('Заметки'),
            SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child:
                  isNotesExpanded ? _buildItemList(notes) : SizedBox.shrink(),
            ),
          ],
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
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xfff1E2E52),
          ),
        ),
        Image.asset(
          'assets/icons/tabBar/dropdown.png',
          width: 16,
          height: 16,
        ),
      ],
    );
  }

  Column _buildItemList(List<Notes> notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: notes.map((note) {
        final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(note.date);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            '${note.body} - $formattedDate',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w400,
              color: Color(0xfff1E2E52),
            ),
          ),
        );
      }).toList(),
    );
  }
}
