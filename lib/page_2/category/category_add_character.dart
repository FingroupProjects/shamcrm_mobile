import 'package:crm_task_manager/page_2/category/character_list.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class AddCustomCharacterFieldDialog extends StatefulWidget {
  final Function(String) onAddField;

  AddCustomCharacterFieldDialog({required this.onAddField});

  @override
  _AddCustomCharacterFieldDialogState createState() => _AddCustomCharacterFieldDialogState();
}

class _AddCustomCharacterFieldDialogState extends State<AddCustomCharacterFieldDialog> {
  String? selectedCharacter;
  bool _isDropdownVisible = false;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewInsets = MediaQuery.of(context).viewInsets;
      setState(() {
        _isKeyboardVisible = viewInsets.bottom > 0;
      });
    });
  }

  @override
void didChangeDependencies() {
  super.didChangeDependencies();
  final viewInsets = MediaQuery.of(context).viewInsets;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      setState(() {
        _isKeyboardVisible = viewInsets.bottom > 0;
      });
    }
  });
}

  @override
  Widget build(BuildContext context) {
final double dialogHeight = _isDropdownVisible
    ? MediaQuery.of(context).size.height * 0.56
    : MediaQuery.of(context).size.height * 0.22;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: dialogHeight, 
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('Добавить характеристику'),
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
            ),
            ),
            SizedBox(height: 4),
            Expanded(
              child: CharacteristicSelectionWidget(
                selectedCharacteristic: selectedCharacter,
                onSelectCharacteristic: (String character) {
                  setState(() {
                    selectedCharacter = character;
                  });
                },
                onDropdownVisibilityChanged: (bool isVisible) {
                  setState(() {
                    _isDropdownVisible = isVisible;
                  });
                },
              ),
            ),
            SizedBox(height: 16),
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
                    buttonText: AppLocalizations.of(context)!.translate('add'),
                    onPressed: () {
                      if (selectedCharacter != null && selectedCharacter!.isNotEmpty) {
                        widget.onAddField(selectedCharacter!);
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.translate('Выберите характеристику')),
                        )
                        );
                      }
                    },
                    buttonColor: Color(0xff1E2E52),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}