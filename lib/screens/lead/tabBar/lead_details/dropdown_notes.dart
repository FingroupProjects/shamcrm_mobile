import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:crm_task_manager/bloc/notes/notes_state.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/notes_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_notes.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/delete_notes.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/edit_notes.dart';
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
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    context.read<NotesBloc>().add(FetchNotes(widget.leadId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !context.read<NotesBloc>().allNotesFetched) {
      context
          .read<NotesBloc>()
          .add(FetchMoreNotes(widget.leadId, (notes.length / 20).ceil()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesBloc, NotesState>(
      builder: (context, state) {
        if (state is NotesLoading) {
          // return const Center(child: CircularProgressIndicator());
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow('Заметки'),
        SizedBox(height: 8),
        if (notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Пусто',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xfff1E2E52),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 300,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return _buildNoteItem(notes[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNoteItem(Notes note) {
    final formattedDate = note.date != null
        ? DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(note.date!))
        : 'Не указано';

    return GestureDetector(
      onTap: () {
        _showEditNoteDialog(note);
      },
      child: Padding(
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
                        note.title,
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
                IconButton(
                  icon: Icon(Icons.delete, color: Color(0xff1E2E52)),
                  onPressed: () {
                    _showDeleteNoteDialog(note);
                  },
                ),
              ],
            ),
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
            _showAddNoteDialog();
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

  void _showAddNoteDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return CreateNotesDialog(leadId: widget.leadId);
      },
    );
  }

  void _showEditNoteDialog(Notes note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return EditNotesDialog(leadId: widget.leadId, note: note);
      },
    );
  }

  void _showDeleteNoteDialog(Notes note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteNoteDialog(note: note, leadId: widget.leadId);
      },
    );
  }
}
