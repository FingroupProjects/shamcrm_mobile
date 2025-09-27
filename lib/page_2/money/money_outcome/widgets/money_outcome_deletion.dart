import '../../../../bloc/page_2_BLOC/money_outcome/money_outcome_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MoneyOutcomeDeleteDialog extends StatelessWidget {
  final int documentId;
  final Function(int)? onDelete;

  const MoneyOutcomeDeleteDialog({super.key, required this.documentId, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MoneyOutcomeBloc, MoneyOutcomeState>(
      listener: (context, state) {
        if (state is MoneyOutcomeDeleteError || state is MoneyOutcomeDeleteSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('delete_money_outcome'),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        content: Text(
          AppLocalizations.of(context)?.translate('delete_money_outcome_confirm') ??
              AppLocalizations.of(context)?.translate('confirm_delete_outcome_document') ?? 'Вы уверены, что хотите удалить этот документ дохода?',
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
                    Navigator.of(context).pop();
                  },
                  buttonColor: Colors.red,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('delete'),
                  onPressed: () {
                    onDelete != null ? onDelete!(documentId) : null;
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
