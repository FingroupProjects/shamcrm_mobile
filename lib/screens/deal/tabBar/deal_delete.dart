import 'package:crm_task_manager/bloc/deal/deal_bloc.dart'; // Путь к bloc для сделок
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteDealDialog extends StatelessWidget {
  final int dealId;
  final int leadId;

  DeleteDealDialog({required this.dealId, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DealBloc, DealState>(
      listener: (context, state) {
        if (state is DealDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!
                    .translate('deal_deleted_successfully'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.buttonPrimaryFg,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.success,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );

          Navigator.of(context).pop(true);
        } else if (state is DealError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.buttonPrimaryFg,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.error,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: context.appColors.surfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('delete_deal'),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('confirm_delete_deal'),
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: context.appColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  buttonColor: context.appColors.backgroundPrimary
                      .withValues(alpha: 0.9),
                  textColor: context.appColors.textPrimary,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: BlocBuilder<DealBloc, DealState>(
                  builder: (context, state) {
                    if (state is DealLoading) {
                      return Center(
                        child: PlayStoreImageLoading(
                          size: 40,
                          duration: const Duration(milliseconds: 900),
                        ),
                      );
                    }
                    return CustomButton(
                      buttonText:
                          AppLocalizations.of(context)!.translate('delete'),
                      onPressed: () {
                        final localizations = AppLocalizations.of(context)!;
                        context
                            .read<DealBloc>()
                            .add(DeleteDeal(dealId, localizations));
                      },
                      buttonColor: context.appColors.error,
                      textColor: context.appColors.buttonPrimaryFg,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
