import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class CallScreen extends StatefulWidget {
  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isValidNumber = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhoneNumber);
  }

  void _validatePhoneNumber() {
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _isValidNumber = phone.length >= 7; // Минимальная длина номера
    });
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);

    // Запрашиваем разрешение для Android
    if (await Permission.phone.request().isGranted) {
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication); // Прямой вызов
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .translate('call_error') ?? 'Unable to make a call'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .translate('call_error') ?? 'Unable to make a call'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!
              .translate('call_permission_denied') ?? 'Call permission denied'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('call_screen_title') ?? 'Make a Call',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.translate('phone_number') ?? 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.phone, color: Color(0xff1E2E52)),
                filled: true,
                fillColor: Colors.grey[100],
                hintStyle: TextStyle(fontFamily: 'Gilroy', color: Colors.grey),
              ),
              style: TextStyle(fontFamily: 'Gilroy', fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isValidNumber ? _makePhoneCall : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff1E2E52),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[400],
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('call_button') ?? 'Call',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}