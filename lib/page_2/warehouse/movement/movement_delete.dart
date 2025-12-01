import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../money/widgets/error_dialog.dart';

class MovementDeleteDocumentDialog extends StatefulWidget {
  final int documentId;
  
  const MovementDeleteDocumentDialog({super.key, required this.documentId});

  @override
  State<MovementDeleteDocumentDialog> createState() => _MovementDeleteDocumentDialogState();
}

class _MovementDeleteDocumentDialogState extends State<MovementDeleteDocumentDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return BlocListener<MovementBloc, MovementState>(
      listener: (context, state) {
        if (!mounted) return;

        if (state is MovementDeleteSuccess) {
          setState(() => _isDeleting = false);
          
          // Успешное сообщение
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.green,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          );
          
          // Закрываем диалог и экран деталей
          Navigator.of(context).pop();
          Navigator.of(context).pop(true);
          
          // Обновляем список документов
          context.read<MovementBloc>().add(const FetchMovements(forceRefresh: true));
          
        } else if (state is MovementDeleteError) {
          setState(() => _isDeleting = false);
          if (state.statusCode == 409) {
            final localizations = AppLocalizations.of(context)!;
            showSimpleErrorDialog(
              context,
              localizations.translate('error') ?? 'Ошибка',
              state.message,
              errorDialogEnum: ErrorDialogEnum.goodsMovementDelete,
            );
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            localizations.translate('delete_document') ?? 'Удалить документ',
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        content: Text(
          localizations.translate('delete_document_confirm') ??
              'Вы уверены, что хотите удалить этот документ?',
          style: const TextStyle(
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
                  buttonText: localizations.translate('close') ?? 'Отмена',
                  onPressed: () {
                    if (!_isDeleting) {
                      Navigator.of(context).pop();
                    }
                  },
                  buttonColor: Colors.grey,
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  buttonText: _isDeleting 
                    ? (localizations.translate('deleting') ?? 'Удаление...') 
                    : (localizations.translate('delete') ?? 'Удалить'),
                  onPressed: _isDeleting 
                      ? () {} 
                      : () {
                          setState(() => _isDeleting = true);
                          context.read<MovementBloc>().add(
                            DeleteMovementDocument(widget.documentId, localizations),
                          );
                        },
                  buttonColor: const Color(0xff1E2E52),
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
