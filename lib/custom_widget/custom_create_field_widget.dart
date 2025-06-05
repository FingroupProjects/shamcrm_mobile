import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class CustomFieldWidget extends StatelessWidget {
  final String fieldName;
  final TextEditingController valueController;
  final VoidCallback onRemove;
  final bool isDirectory;

  const CustomFieldWidget({
    Key? key,
    required this.fieldName,
    required this.valueController,
    required this.onRemove,
    this.isDirectory = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fieldName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 8),
              if (!isDirectory)
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.translate('enter_textfield_text'),
                    hintStyle: const TextStyle(
                      fontFamily: 'Gilroy',
                      color: Color(0xff99A4BA),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xffF4F7FD),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xffF4F7FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    fieldName,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.remove_circle,
            color: Color.fromARGB(255, 236, 64, 16),
          ),
          onPressed: onRemove,
        ),
      ],
    );
  }
}