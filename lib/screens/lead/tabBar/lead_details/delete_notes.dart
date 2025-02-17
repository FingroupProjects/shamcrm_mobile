import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:crm_task_manager/bloc/notes/notes_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/notes_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteNoteDialog extends StatelessWidget {
  final Notes note;
  final int leadId;

  DeleteNoteDialog({required this.note, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotesBloc, NotesState>(
      listener: (context, state) {
        if (state is NotesError) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(
                  AppLocalizations.of(context)!.translate(state.message), // Локализация сообщения
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
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
        AppLocalizations.of(context)!.translate('delete_note'),
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      )),
      content: Text(
        AppLocalizations.of(context)!.translate('confirm_delete_note'),
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: Color(0xff1E2E52),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('cancel'),
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
                buttonText: AppLocalizations.of(context)!.translate('delete'),
                onPressed: () {
                  context.read<NotesBloc>().add(DeleteNote(note.id, leadId));
                  ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text(
                       AppLocalizations.of(context)!.translate('note_deleted_successfully'),
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
                  Navigator.of(context).pop();
                },
                buttonColor: Color(0xff1E2E52),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
      )
    );
  }
}
