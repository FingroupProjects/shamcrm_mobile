import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ToggleFeatureButton extends StatefulWidget {
  const ToggleFeatureButton({super.key});

  @override
  _ToggleFeatureButtonState createState() => _ToggleFeatureButtonState();
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

  Future<void> _toggleFeature() async {
    setState(() {
      _isFeatureEnabled = !_isFeatureEnabled;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('switchContact', _isFeatureEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFeature,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              _isFeatureEnabled ? Icons.toggle_on : Icons.toggle_off,
              color: _isFeatureEnabled ? Colors.green : Colors.grey,
              size: 42,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _isFeatureEnabled
                    ? 'Функция импорта из контакта включена'
                    : 'Функция импорта из контакта выключена',
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
      ),
    );
  }
}
