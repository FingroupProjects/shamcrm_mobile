import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ToggleFeatureButton extends StatefulWidget {
  const ToggleFeatureButton({super.key});
  
  @override
  State<ToggleFeatureButton> createState() => _ToggleFeatureButtonState();
}

class _ToggleFeatureButtonState extends State<ToggleFeatureButton> {
  bool _isFeatureEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadFeatureState();
  }

  Future<void> _loadFeatureState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFeatureEnabled = prefs.getBool('switchContact') ?? false;
    });
  }

  Future<void> _toggleFeature(bool value) async {
    setState(() {
      _isFeatureEnabled = value;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('switchContact', _isFeatureEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      height: 80, // Increased height
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Switch(
            value: _isFeatureEnabled,
            onChanged: _toggleFeature,
            activeColor: const Color.fromARGB(255, 255, 255, 255),
            inactiveTrackColor: const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
            activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
            inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isFeatureEnabled
                  ? AppLocalizations.of(context)!.translate('import_contact_on')
                  : AppLocalizations.of(context)!.translate('import_contact_off'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xFF1E1E1E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}