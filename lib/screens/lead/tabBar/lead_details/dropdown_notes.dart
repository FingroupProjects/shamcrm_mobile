import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:crm_task_manager/bloc/notes/notes_state.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/notes_model.dart';
import 'package:crm_task_manager/screens/event/event_details/event_details_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_notes.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/delete_notes.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class NotesWidget extends StatefulWidget {
  final int leadId;

  NotesWidget({Key? key, required this.leadId}) : super(key: key);

  @override
  _NotesWidgetState createState() => _NotesWidgetState();
}

class _NotesWidgetState extends State<NotesWidget> {
  List<Notes> notes = [];
  late ScrollController _scrollController;
  bool _canCreateNotes = false;
  bool _canUpdateNotes = false;
  bool _canDeleteNotes = false;
  final ApiService _apiService = ApiService();

  Future<void> _checkPermissions() async {
    final canCreate = await _apiService.hasPermission('notice.create');
    final canUpdate = await _apiService.hasPermission('notice.update');
    final canDelete = await _apiService.hasPermission('notice.delete');
    setState(() {
      _canCreateNotes = canCreate;
      _canUpdateNotes = canUpdate;
      _canDeleteNotes = canDelete;
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _checkPermissions();
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
          // Можно добавить индикатор загрузки, если нужно
        } else if (state is NotesLoaded) {
          notes = state.notes;
        } else if (state is NotesError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.translate(state.message),
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
                backgroundColor: Colors.red,
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
          });
        }

        return _buildNotesList(notes);
      },
    );
  }

  Widget _buildNotesList(List<Notes> notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(AppLocalizations.of(context)!.translate('notice')),
        SizedBox(height: 8),
        if (notes.isEmpty)
          _buildEmptyState()
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: TaskCardStyles.taskCardDecoration,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 0),
                Text(
                  AppLocalizations.of(context)!.translate('empty'),
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1E2E52),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteItem(Notes note) {
    final formattedDate = note.date != null
        ? DateFormat('dd.MM.yyyy HH:mm')
            .format(DateTime.parse(note.date!).add(Duration(hours: 5)))
        : AppLocalizations.of(context)!.translate('not_specified');
    final createDate = note.createDate != null
        ? DateFormat('dd.MM.yyyy HH:mm')
            .format(DateTime.parse(note.createDate!).add(Duration(hours: 5)))
        : AppLocalizations.of(context)!.translate('not_specified');
    return GestureDetector(
      onTap: _canUpdateNotes ? () => _showEditNoteDialog(note) : null,
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
                        AppLocalizations.of(context)!.translate('date') +" "+ formattedDate,
                        style: TaskCardStyles.priorityStyle.copyWith(
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.translate('created_at_contact') + createDate,
                        style: TaskCardStyles.priorityStyle.copyWith(
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_canDeleteNotes)
                  IconButton(
                    icon: Icon(Icons.delete, color: Color(0xff1E2E52)),
                    onPressed: () => _showDeleteNoteDialog(note),
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
        if (_canCreateNotes)
          TextButton(
            onPressed: _showAddNoteDialog,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Color(0xff1E2E52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('add'),
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
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: CreateNotesDialog(leadId: widget.leadId),
        );
      },
    );
  }

  void _showEditNoteDialog(Notes note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(
          noticeId: note.id,
          source: 'Lead', // Добавляем параметр source
        ),
      ),
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