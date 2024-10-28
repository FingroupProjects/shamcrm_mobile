import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/notes_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteNoteDialog extends StatelessWidget {
  final Notes note;
  final int leadId;

  DeleteNoteDialog({required this.note, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Center(
          child: Text(
        'Удалить заметку',
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      )),
      content: Text(
        'Вы уверены, что хотите удалить эту заметку?',
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
                buttonText: 'Удалить',
                onPressed: () {
                  context.read<NotesBloc>().add(DeleteNote(note.id, leadId));
                  Navigator.of(context).pop();
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







// import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
// import 'package:crm_task_manager/bloc/notes/notes_event.dart';
// import 'package:flutter/material.dart';
// import 'package:crm_task_manager/models/notes_model.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:crm_task_manager/custom_widget/custom_button.dart';

// class DeleteNoteDialog extends StatelessWidget {
//   final Notes note;
//   final int leadId;

//   DeleteNoteDialog({required this.note, required this.leadId});

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(
//         'Удалить заметку',
//         style: TextStyle(
//           fontSize: 18,
//           fontFamily: 'Gilroy',
//           fontWeight: FontWeight.w600,
//           color: Color(0xff1E2E52),
//         ),
//       ),
//       content: Text(
//         'Вы уверены, что хотите удалить эту заметку?',
//         style: TextStyle(
//           fontSize: 16,
//           fontFamily: 'Gilroy',
//           color: Colors.black,
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop(); // Закрыть диалог
//           },
//           child: Text(
//             'Отмена',
//             style: TextStyle(
//               color: Color(0xff1E2E52),
//             ),
//           ),
//         ),
//         CustomButton(
//           buttonText: 'Удалить',
//           onPressed: () {
//             context.read<NotesBloc>().add(DeleteNote(note.id, leadId));
//             Navigator.of(context).pop(); // Закрыть диалог
//           },
//           buttonColor: Color(0xff1E2E52),
//           textColor: Colors.white,
//         ),
//       ],
//     );
//   }
// }
