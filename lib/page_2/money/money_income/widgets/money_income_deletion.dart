import 'package:crm_task_manager/bloc/money_income/money_income_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MoneyIncomeDeleteDialog extends StatelessWidget {
  final int documentId;
  final Function(int)? onDelete;

  const MoneyIncomeDeleteDialog({super.key, required this.documentId, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MoneyIncomeBloc, MoneyIncomeState>(
      listener: (context, state) {
        if (state is MoneyIncomeDeleteError) {
          showCustomSnackBar(context: context, message: state.message, isSuccess: false);
        } else if (state is MoneyIncomeDeleteSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('delete_money_income'),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        content: Text(
          AppLocalizations.of(context)?.translate('delete_money_income_confirm') ??
              AppLocalizations.of(context)?.translate('confirm_delete_income_document') ?? 'Вы уверены, что хотите удалить этот документ дохода?',
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
