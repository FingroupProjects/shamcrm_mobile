import 'package:flutter/material.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoutButtonWidget extends StatelessWidget {
  const LogoutButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Получаем экземпляр SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Удаляем данные userName, userNameProfile и userImage
        bool isUserNameRemoved = await prefs.remove('userName');
        bool isUserNameProfileRemoved = await prefs.remove('userNameProfile');
        bool isUserImageRemoved = await prefs.remove('userImage');

        // Проверяем успешность удаления
        if (isUserNameRemoved &&
            isUserNameProfileRemoved &&
            isUserImageRemoved) {
          print('Данные успешно очищены.');
        } else {
          print('Ошибка при очистке данных.');
        }

        // Логика выхода (например, вызов logout API)
        ApiService apiService = ApiService();
        await apiService.logout();

        // Перенаправление на экран входа после выхода
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      },
      child: _buildProfileOption(
        iconPath: 'assets/icons/Profile/logout.png',
        text: 'Выйти',
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
          Image.asset(
            'assets/icons/arrow-right.png',
            width: 16,
            height: 16,
          ),
        ],
      ),
    );
  }
}
