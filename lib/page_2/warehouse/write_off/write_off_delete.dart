import 'package:crm_task_manager/bloc/page_2_BLOC/document/write_off/write_off_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/page_2/money/widgets/error_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WriteOffDeleteDocumentDialog extends StatelessWidget {
  final int documentId;

  const WriteOffDeleteDocumentDialog({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<WriteOffBloc, WriteOffState>(
      listener: (context, state) {
        if (state is WriteOffDeleteSuccess) {
          debugPrint("WriteOffDeleteDialogListener: Document deleted successfully");
          Navigator.of(context).pop(true); // Return true on success
        }
        else if (state is WriteOffError) {
          debugPrint("WriteOffDeleteDialogListener: Error deleting document");
          if (state.statusCode  == 409) {
            final localizations = AppLocalizations.of(context)!;
            Navigator.of(context).pop(false); // Return false on error
            showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
            return;
          }
         showCustomSnackBar(context: context, message: state.message, isSuccess: false);
         Navigator.of(context).pop(false); // Return false on error
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
                    Navigator.of(context).pop(false); // Return false on cancel
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
                    context.read<WriteOffBloc>().add(DeleteWriteOffDocument(documentId, AppLocalizations.of(context)!, shouldReload: true));
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