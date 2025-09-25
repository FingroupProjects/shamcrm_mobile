import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../money/widgets/error_dialog.dart';

class DeleteDocumentDialog extends StatefulWidget {
  final int documentId;

  DeleteDocumentDialog({required this.documentId});

  @override
  _DeleteDocumentDialogState createState() => _DeleteDocumentDialogState();
}

class _DeleteDocumentDialogState extends State<DeleteDocumentDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<IncomingBloc, IncomingState>(
      listener: (context, state) {
        // Проверяем, что виджет все еще активен
        if (!mounted) return;
        
        if (state is IncomingDeleteError) {
          setState(() {
            _isDeleting = false;
          });
          
          // Дополнительная проверка перед показом SnackBar
          if (mounted && context.mounted) {
            final localizations = AppLocalizations.of(context)!;
            if (state.statusCode == 409) {
              showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
              return;
            }

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
          }
        } else if (state is IncomingDeleteSuccess) {
          // Просто закрываем диалог без показа SnackBar здесь
          // SnackBar будет показан в IncomingScreen
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (state is IncomingDeleteLoading) {
          setState(() {
            _isDeleting = true;
          });
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('delete_document') ?? 'Удалить документ',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        content: _isDeleting 
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                ),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.translate('deleting') ?? 'Удаление...',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ],
            )
          : Text(
              AppLocalizations.of(context)!.translate('delete_document_confirm') ?? 'Вы уверены, что хотите удалить этот документ?',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
        actions: _isDeleting 
          ? [] // Скрываем кнопки во время удаления
          : [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomButton(
                      buttonText: AppLocalizations.of(context)!.translate('cancel') ?? 'Отмена',
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
                      buttonText: AppLocalizations.of(context)!.translate('delete') ?? 'Удалить',
                      onPressed: () {
                        final localizations = AppLocalizations.of(context)!;
                        context.read<IncomingBloc>().add(DeleteIncoming(widget.documentId, localizations));
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