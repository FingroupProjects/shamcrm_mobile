import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateWidget1C extends StatefulWidget {
  const UpdateWidget1C({super.key});

  @override
  _UpdateWidget1CState createState() => _UpdateWidget1CState();
}

class _UpdateWidget1CState extends State<UpdateWidget1C> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  String? lastUpdated;
  bool is1cIntegration = false;  
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _loadPreferences();  
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      is1cIntegration = prefs.getBool('is1cIntegration') ?? false;
      lastUpdated = prefs.getString('last1cUpdate');
    });
  }

  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (lastUpdated != null) {
      prefs.setString('last1cUpdate', lastUpdated!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!; 

    return GestureDetector(
      onTap: () async {
        if (!is1cIntegration) {
          return;  
        }

        setState(() {
          isLoading = true;
        });

        _controller.repeat();

        await Future.delayed(const Duration(seconds: 3));

        setState(() {
          isLoading = false;
          lastUpdated = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
        });

        _controller.stop();
        await _savePreferences();  

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.translate('data_updated_successfully'), 
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (is1cIntegration)  
            _buildProfileOption(
              iconPath: 'assets/icons/1c/5.png',
              text: localizations.translate('update_1c_data'),
            ),
          if (lastUpdated != null && !is1cIntegration)
            Center(
              child: Text(
                '${localizations.translate('last_update')}: $lastUpdated', 
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Gilroy',
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({required String iconPath, required String text}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          isLoading
              ? RotationTransition(
                  turns: Tween<double>(begin: 0, end: -1).animate(_controller), 
                  child: Image.asset(
                    iconPath,
                    width: 60,
                    height: 60,
                  ),
                )
              : Image.asset(
                  iconPath,
                  width: 40,
                  height: 40,
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
