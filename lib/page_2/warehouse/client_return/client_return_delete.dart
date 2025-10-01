import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_return/client_return_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../money/widgets/error_dialog.dart';

class ClientReturnDeleteDocumentDialog extends StatelessWidget {
  final int documentId;

  const ClientReturnDeleteDocumentDialog({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientReturnBloc, ClientReturnState>(
      listener: (context, state) {
        if (state is ClientReturnError) {
          final localizations = AppLocalizations.of(context)!;
          if (state.statusCode == 409) {
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
            AppLocalizations.of(context)!.translate('delete_return_document') ?? 'Удалить возврат',
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
                  ?.translate('delete_return_document_confirm') ??
              'Вы уверены, что хотите удалить этот документ возврата?',
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
                    final localizations = AppLocalizations.of(context)!;
                    context
                        .read<ClientReturnBloc>()
                        .add(DeleteClientReturnDocument(documentId, shouldReload: true));
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
      ),
    );
  }
}