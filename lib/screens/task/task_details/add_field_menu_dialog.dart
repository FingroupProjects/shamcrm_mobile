import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/directory_group_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class AddFieldMenuDialog extends StatelessWidget {
  final VoidCallback onManualInput;
  final Function(int) onDirectorySelected;

  const AddFieldMenuDialog({
    Key? key,
    required this.onManualInput,
    required this.onDirectorySelected,
  }) : super(key: key);

  void _showDirectoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('select_directory'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 16),
              DirectoryGroupWidget(
                onSelectDirectory: (directory) {
                  onDirectorySelected(directory.id);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40), // Позиция меню относительно кнопки
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'manual',
          child: Text(
            AppLocalizations.of(context)!.translate('manual_input'),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'directory',
          child: Text(
            AppLocalizations.of(context)!.translate('directory'),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
      ],
      onSelected: (String value) {
        if (value == 'manual') {
          onManualInput();
        } else if (value == 'directory') {
          _showDirectoryDialog(context);
        }
      },
      child: Container(), // Пустой контейнер, так как вызов осуществляется через CustomButton
    );
  }
}

class AddCustomFieldDialog extends StatelessWidget {
  final Function(String) onAddField;

  AddCustomFieldDialog({Key? key, required this.onAddField}) : super(key: key);

  final TextEditingController _fieldNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      contentPadding: const EdgeInsets.all(16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('add_field'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _fieldNameController,
            hintText: AppLocalizations.of(context)!.translate('enter_field_name'),
            label: AppLocalizations.of(context)!.translate('field_name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.translate('field_required');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context)!.translate('cancel'),
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_fieldNameController.text.isNotEmpty) {
                      onAddField(_fieldNameController.text);
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4759FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('add'),
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}