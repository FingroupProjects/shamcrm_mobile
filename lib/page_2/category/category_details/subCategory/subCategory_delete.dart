import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';

class DeleteSubCategoryDialog extends StatelessWidget {
  final int categoryId;
  
  const DeleteSubCategoryDialog({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryDeleted) {
          Navigator.of(context).pop(true);
          showCustomSnackBar(
            context: context,
            message: AppLocalizations.of(context)!.translate(state.message),
            isSuccess: true,
          );
        } else if (state is CategoryError) {
          Navigator.of(context).pop();
          showCustomSnackBar(
            context: context,
            message: AppLocalizations.of(context)!.translate(state.message),
            isSuccess: false,
          );
        }
      },
      child: AlertDialog(
        backgroundColor: colors.surfacePrimary,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppLocalizations.of(context)!.translate('delete_subcategory'),
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppLocalizations.of(context)!.translate('confirm_delete_subcategory'),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
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
                  buttonColor: colors.buttonDangerBg,
                  textColor: colors.surfacePrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('delete'),
                  onPressed: () {
                    context.read<CategoryBloc>().add(DeleteCategory(categoryId));
                  },
                  buttonColor: colors.buttonPrimaryBg,
                  textColor: colors.surfacePrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}