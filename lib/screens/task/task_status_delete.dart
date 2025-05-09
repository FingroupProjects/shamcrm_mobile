import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteTaskStatusDialog extends StatelessWidget {
  final int taskStatusId; // ID удаляемого статуса

  DeleteTaskStatusDialog({required this.taskStatusId});
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskError) {
          // Показываем сообщение об ошибке через SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.translate(state.message), // Локализация сообщения
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
                borderRadius:
                    BorderRadius.circular(12), // Радиус, как у текстового поля
              ),
              backgroundColor: Colors.red, // Цвет фона, как у текстового поля
              elevation: 3,
              padding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16), // Паддинг для комфортного восприятия
              duration: Duration(seconds: 3), // Установлено на 2 секунды
            ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('delete_task_status'), 
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('confirm_delete_task_status'),
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
                    Navigator.of(context).pop(); // Закрываем диалог
                  },
                  buttonColor: Colors.red,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
  child: CustomButton(
    buttonText: AppLocalizations.of(context)!.translate('delete'),
    onPressed: () async {
      final _apiService = ApiService();
      final hasLeads = await _apiService.checkIfStatusHasTasks(taskStatusId);

      if (hasLeads) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('remove_cards_first'), // Локализованный текст
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
        Navigator.of(context).pop(); 
      } else {
          final localizations = AppLocalizations.of(context)!;

        context.read<TaskBloc>().add(DeleteTaskStatuses(taskStatusId,localizations));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('status_deleted_successfully'), 
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
        Navigator.of(context).pop(true);
        context.read<TaskBloc>().add(FetchTaskStatuses());
      }
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
