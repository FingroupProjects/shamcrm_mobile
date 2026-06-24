import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SupplierDeleteDialog extends StatelessWidget {
  final int documentId;

  const SupplierDeleteDialog({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<SupplierBloc, SupplierState>(
      listener: (context, state) {
        if (state is SupplierError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: colors.error,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: colors.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderSubtle),
        ),
        title: Center(
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.buttonDangerBg.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: colors.buttonDangerBg,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.translate('delete_supplier'),
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        content: Text(
          AppLocalizations.of(context)?.translate('delete_supplier_confirm') ??
              'Вы уверены, что хотите удалить этот документ?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: CustomButton(
                  buttonText:
                      AppLocalizations.of(context)!.translate('cancel') ??
                          'Отмена',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  buttonColor: colors.buttonSecondaryBg,
                  textColor: colors.buttonSecondaryFg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  buttonText:
                      AppLocalizations.of(context)!.translate('delete') ??
                          'Удалить',
                  onPressed: () {
                    context
                        .read<SupplierBloc>()
                        .add(DeleteSupplier(documentId));
                    Navigator.of(context).pop(true);
                  },
                  buttonColor: colors.buttonDangerBg,
                  textColor: colors.buttonDangerFg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
