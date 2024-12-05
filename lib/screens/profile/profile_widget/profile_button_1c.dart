import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpdateWidget1C extends StatefulWidget {
  const UpdateWidget1C({super.key});

  @override
  _UpdateWidget1CState createState() => _UpdateWidget1CState();
}

class _UpdateWidget1CState extends State<UpdateWidget1C> {
  bool isLoading = false;
  String? lastUpdated;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          isLoading = true;
        });

        await Future.delayed(const Duration(seconds: 3));

        setState(() {
          isLoading = false;
          lastUpdated = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Данные 1С успешно обновлены',
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
    _buildProfileOption(
      iconPath: 'assets/icons/1c/update.png',
      text: 'Обновить данные 1С',
    ),
    if (lastUpdated != null)
      Center(
        child: Text(
          'Последнее обновление: $lastUpdated',
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
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Image.asset(
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
          isLoading
              ? const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E1E1E)),
                  ),
                )
              : Image.asset(
                  'assets/icons/arrow-right.png',
                  width: 16,
                  height: 16,
                ),
        ],
      ),
    );
  }
}