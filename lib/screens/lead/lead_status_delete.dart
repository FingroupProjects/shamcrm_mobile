import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteLeadStatusDialog extends StatelessWidget {
  final int leadStatusId; // ID удаляемого статуса

  DeleteLeadStatusDialog({required this.leadStatusId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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

                  // Закрываем диалог после удаления
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
    );
  }
}
