import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart'; // Для обработки состояния ошибок
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteLeadStatusDialog extends StatelessWidget {
  final int leadStatusId; // ID удаляемого статуса

  DeleteLeadStatusDialog({required this.leadStatusId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) {
        if (state is LeadError) {
          // Показываем сообщение об ошибке через SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(
                 '${state.message}',
                 style: TextStyle(
                   fontFamily: 'Gilroy',
                   fontSize: 16, // Размер шрифта совпадает с CustomTextField
                   fontWeight: FontWeight.w500, // Жирность текста
                   color: Colors.white, // Цвет текста для читаемости
                 ),
               ),
               behavior: SnackBarBehavior.floating,
               margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(12), // Радиус, как у текстового поля
               ),
               backgroundColor: Colors.red, // Цвет фона, как у текстового поля
               elevation: 3,
               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Паддинг для комфортного восприятия
             ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            'Удалить статус лида',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        content: Text(
          'Вы уверены, что хотите удалить этот статус лида?',
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
                  Navigator.of(context).pop(); // Закрываем диалог
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
                  // Отправляем событие на удаление статуса
                  context.read<LeadBloc>().add(DeleteLeadStatuses(leadStatusId));

                  // Закрываем диалог после отправки события
                  Navigator.of(context).pop();

                  // После удаления, загружаем обновленные статусы
                  context.read<LeadBloc>().add(FetchLeadStatuses());
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