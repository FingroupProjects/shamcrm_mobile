import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class StatusSelector extends StatefulWidget {
  final Function(bool?) onStatusChanged; // Callback для передачи is_active

  const StatusSelector({super.key, required this.onStatusChanged});

  @override
  State<StatusSelector> createState() => _StatusSelectorState();
}

class _StatusSelectorState extends State<StatusSelector> {
  bool isActive = true;
  bool isInactive = true;

  void _handleActiveChanged(bool? value) {
    if (value == false && !isInactive) {
      // Нельзя выключить оба — включаем isInactive
      setState(() {
        isActive = false;
        isInactive = true;
      });
      widget.onStatusChanged(null); // Оба активны
    } else {
      setState(() {
        isActive = value ?? false;
      });
      widget.onStatusChanged(isActive && !isInactive ? true : isInactive && !isActive ? false : null);
    }
  }

  void _handleInactiveChanged(bool? value) {
    if (value == false && !isActive) {
      // Нельзя выключить оба — включаем isActive
      setState(() {
        isInactive = false;
        isActive = true;
      });
      widget.onStatusChanged(null); // Оба активны
    } else {
      setState(() {
        isInactive = value ?? false;
      });
      widget.onStatusChanged(isActive && !isInactive ? true : isInactive && !isActive ? false : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCheckboxTile(
            title: AppLocalizations.of(context)!.translate('active'),
            value: isActive,
            onChanged: _handleActiveChanged,
          ),
          _buildCheckboxTile(
            title: AppLocalizations.of(context)!.translate('inactive'),
            value: isInactive,
            onChanged: _handleInactiveChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? ChatSmsStyles.messageBubbleSenderColor : Colors.grey,
              size: 30,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontFamily: 'Gilroy',
              ),
            ),
          ],
        ),
      ),
    );
  }
}