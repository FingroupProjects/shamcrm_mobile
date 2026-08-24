import 'package:crm_task_manager/bloc/page_2_BLOC/employee_bloc/employee_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/employee_bloc/employee_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/employee_bloc/employee_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeeDeleteDialog extends StatelessWidget {
  final int employeeId;

  const EmployeeDeleteDialog({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<EmployeeBloc, EmployeeState>(
      listener: (context, state) {
        if (state is EmployeeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.translate(state.message),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: colors.error,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                l10n.translate('delete_employee'),
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
          l10n.translate('delete_employee_confirm'),
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
            children: [
              Expanded(
                child: CustomButton(
                  buttonText: l10n.translate('cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                  buttonColor: colors.buttonSecondaryBg,
                  textColor: colors.buttonSecondaryFg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  buttonText: l10n.translate('delete'),
                  onPressed: () {
                    context
                        .read<EmployeeBloc>()
                        .add(DeleteEmployee(employeeId));
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
