import 'package:crm_task_manager/bloc/page_2_BLOC/document/write_off/write_off_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/page_2/money/widgets/error_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WriteOffDeleteDocumentDialog extends StatelessWidget {
  final int documentId;

  const WriteOffDeleteDocumentDialog({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<WriteOffBloc, WriteOffState>(
      listener: (context, state) {
        if (state is WriteOffError) {
          if (state.statusCode  == 409) {
            final localizations = AppLocalizations.of(context)!;
            showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
            return;
          }
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
            ),
          );
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
        content: Text(
          AppLocalizations.of(context)
                  ?.translate('delete_document_confirm') ??
              'Вы уверены, что хотите удалить этот документ?',
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
                  buttonText:
                      AppLocalizations.of(context)!.translate('close') ?? 'Отмена',
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
                  buttonText:
                      AppLocalizations.of(context)!.translate('delete') ?? 'Удалить',
                  onPressed: () {
                    context
                        .read<WriteOffBloc>()
                        .add(DeleteWriteOffDocument(documentId));
                    Navigator.of(context).pop();
                    Navigator.pop(context, true);
                  },
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ));
  }
}