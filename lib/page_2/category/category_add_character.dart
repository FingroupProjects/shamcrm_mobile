import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/page_2/category/character_list.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class AddCustomCharacterFieldDialog extends StatefulWidget {
  final Function(String, bool) onAddField;

  AddCustomCharacterFieldDialog({required this.onAddField});

  @override
  _AddCustomCharacterFieldDialogState createState() => _AddCustomCharacterFieldDialogState();
}

class _AddCustomCharacterFieldDialogState extends State<AddCustomCharacterFieldDialog> {
  String? selectedCharacter;
  bool _isDropdownVisible = false;
  bool _isKeyboardVisible = false;
  bool isCommonActive = true;
  bool isUniqueActive = false;
  bool showOnWebsite = false;

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
    final colors = context.appColors;
    final double dialogHeight = _isDropdownVisible
        ? MediaQuery.of(context).size.height * 0.60
        : MediaQuery.of(context).size.height * 0.40;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: dialogHeight,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('add_characteristic'),
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              CharacteristicSelectionWidget(
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
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Switch(
                    value: isCommonActive,
                    onChanged: (value) {
                      setState(() {
                        isCommonActive = value;
                        if (isCommonActive) {
                          isUniqueActive = false;
                          showOnWebsite = false;
                        }
                      });
                    },
                    activeColor: colors.surfacePrimary,
                    inactiveTrackColor: colors.textMuted.withValues(alpha: 0.5),
                    activeTrackColor: colors.buttonPrimaryBg,
                    inactiveThumbColor: colors.surfacePrimary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.translate('common'),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Switch(
                    value: isUniqueActive,
                    onChanged: (value) {
                      setState(() {
                        isUniqueActive = value;
                        if (isUniqueActive) {
                          isCommonActive = false;
                        } else {
                          showOnWebsite = false;
                        }
                      });
                    },
                    activeColor: colors.surfacePrimary,
                    inactiveTrackColor: colors.textMuted.withValues(alpha: 0.5),
                    activeTrackColor: colors.buttonPrimaryBg,
                    inactiveThumbColor: colors.surfacePrimary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.translate('individual'),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (isUniqueActive)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Switch(
                      value: showOnWebsite,
                      onChanged: (value) {
                        setState(() {
                          showOnWebsite = value;
                        });
                      },
                      activeColor: colors.surfacePrimary,
                      inactiveTrackColor: colors.textMuted.withValues(alpha: 0.5),
                      activeTrackColor: colors.buttonPrimaryBg,
                      inactiveThumbColor: colors.surfacePrimary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.translate('show_on_website'),
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
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
                      buttonColor: colors.buttonDangerBg,
                      textColor: colors.buttonPrimaryFg,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      buttonText: AppLocalizations.of(context)!.translate('add'),
                      onPressed: () {
                        if (selectedCharacter != null && selectedCharacter!.isNotEmpty) {
                          widget.onAddField(selectedCharacter!, isUniqueActive);
                          Navigator.of(context).pop();
                        } else {
                          showCustomSnackBar(
                            context: context,
                            message: AppLocalizations.of(context)!.translate('select_characteristic'),
                            isSuccess: false,
                          );
                        }
                      },
                      buttonColor: colors.buttonPrimaryBg,
                      textColor: colors.buttonPrimaryFg,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
