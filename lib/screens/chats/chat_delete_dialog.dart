import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteChatDialog extends StatelessWidget {
  final int chatId; // ID удаляемого чата

  DeleteChatDialog({required this.chatId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatsBloc, ChatsState>(
  listener: (context, state) {
    if (state is ChatsError) {
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
          backgroundColor: Colors.red,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (state is ChatsDeleted) {
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
          duration: Duration(seconds: 2),
        ),
      );
    }
  },

      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            'Удалить чат',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        content: Text(
          'Вы уверены, что хотите удалить этот чат?',
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
                    context.read<ChatsBloc>().add(DeleteChat(chatId));
                    Navigator.of(context).pop();
                  },
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


//  Expanded(
//   child: CustomButton(
//     buttonText: 'Удалить',
//     onPressed: () {
//       // Сохраняем текущий контекст родителя
//       final parentContext = context;

//       // Отправляем событие для удаления чата
//       context.read<ChatsBloc>().add(DeleteChat(chatId));

//       // Закрываем диалоговое окно
//       Navigator.of(context).pop();

//       // Показываем сообщение после закрытия диалога
//       Future.microtask(() {
//         ScaffoldMessenger.of(parentContext).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Чат успешно удалён!', // Сообщение об успешном удалении
//               style: TextStyle(
//                 fontFamily: 'Gilroy',
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.white,
//               ),
//             ),
//             behavior: SnackBarBehavior.floating,
//             margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             backgroundColor: Colors.green,
//             elevation: 3,
//             padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       });
//     },
//     buttonColor: Color(0xff1E2E52),
//     textColor: Colors.white,
//   ),
// ),