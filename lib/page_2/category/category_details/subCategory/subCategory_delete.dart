import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryDeleted) {
          Navigator.of(context).pop(true); 
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                AppLocalizations.of(context)!.translate(state.message),
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
              backgroundColor: Colors.green,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
        } else if (state is CategoryError) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                AppLocalizations.of(context)!.translate(state.message),
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
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppLocalizations.of(context)!.translate('Удалить подкатегорию'),
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppLocalizations.of(context)!.translate('Подтвердите удаление подкатегории!'),
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
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
                  buttonColor: Colors.red,
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('delete'),
                  onPressed: () {
                    context.read<CategoryBloc>().add(DeleteCategory(categoryId));
                  },
                  buttonColor: const Color(0xff1E2E52),
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