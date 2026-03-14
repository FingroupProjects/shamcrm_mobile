import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_settings_tile.dart';
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
    //print('ToggleFeatureButton: switchContact set to: $_isFeatureEnabled'); // Новый лог
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSettingsTile(
      title: _isFeatureEnabled
          ? AppLocalizations.of(context)!.translate('import_contact_on')
          : AppLocalizations.of(context)!.translate('import_contact_off'),
      icon: Icons.contacts_outlined,
      trailing: Switch(
        value: _isFeatureEnabled,
        onChanged: _toggleFeature,
      ),
    );
  }
}
