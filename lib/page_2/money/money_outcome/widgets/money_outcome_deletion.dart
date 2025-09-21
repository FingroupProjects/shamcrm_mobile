import 'package:crm_task_manager/bloc/money_outcome/money_outcome_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MoneyOutcomeDeleteDialog extends StatelessWidget {
  final int documentId;

  const MoneyOutcomeDeleteDialog({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MoneyOutcomeBloc, MoneyOutcomeState>(
      listener: (context, state) {
        if (state is MoneyOutcomeDeleteSuccess) {
          Navigator.of(context).pop(true);
        } else if (state is MoneyOutcomeDeleteError) {
          Navigator.of(context).pop(false);
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
              AppLocalizations.of(context)!.translate('confirm_delete_money_income_document') ?? 'Вы уверены, что хотите удалить этот документ денежного дохода?',
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
                    context.read<MoneyOutcomeBloc>().add(DeleteMoneyOutcome(documentId));
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
