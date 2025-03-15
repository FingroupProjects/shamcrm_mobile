import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class CategoryAddBottomSheet {
  static void show(BuildContext context) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController categoryNameController = TextEditingController();
    final TextEditingController categoryDescriptionController = TextEditingController();

    showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (context) {
    return FractionallySizedBox(
      heightFactor: 0.7, 
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('Новая категория'),
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: categoryNameController,
                        hintText: AppLocalizations.of(context)!.translate('Введите название'),
                        label: AppLocalizations.of(context)!.translate('Название'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.translate('field_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: categoryDescriptionController,
                        hintText: AppLocalizations.of(context)!.translate('enter_description'),
                        label: AppLocalizations.of(context)!.translate('description_list'),
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('cancel'),
                    buttonColor: const Color(0xffF4F7FD),
                    textColor: Colors.black,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('add'),
                    buttonColor: const Color(0xff4759FF),
                    textColor: Colors.white,
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        _createCategory(categoryNameController.text, categoryDescriptionController.text, context);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  },
);

  }

  static void _createCategory(String name, String description, BuildContext context) {
    final String? desc = description.isEmpty ? null : description;
    print('Название категории: $name');
    print('Описание категории: $desc');
    Navigator.pop(context);
  }
}
