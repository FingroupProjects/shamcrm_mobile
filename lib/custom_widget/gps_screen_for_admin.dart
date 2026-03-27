import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class GpsScreenForAdmin extends StatefulWidget {
  @override
  _GpsScreenForAdminState createState() => _GpsScreenForAdminState();
}

class _GpsScreenForAdminState extends State<GpsScreenForAdmin> {
  // Локальный список пользователей для тестирования
  List<Map<String, dynamic>> users = [
    {'id': 1, 'name': 'John Doe'},
    {'id': 2, 'name': 'Jane Smith'},
    {'id': 3, 'name': 'Alex Johnson'},
    {'id': 4, 'name': 'Maria Ivanova'},
    {'id': 5, 'name': 'Peter Brown'},
  ];
  bool isLoading = false; // Нет загрузки, так как данные локальные

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA), // Фон в стиле shamCRM
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('gps'),
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E2E52),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1E2E52)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: users.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context)!.translate('no_users_found'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8A96A8),
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF006FFD),
                      child: Text(
                        user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Text(
                      user['name'] ?? 'Unknown User',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2E52),
                      ),
                    ),
                    subtitle: Text(
                      'ID: ${user['id']}',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8A96A8),
                      ),
                    ),
                    onTap: () {
                      // В будущем здесь будет переход на экран с картой или деталями геолокации
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Выбран пользователь: ${user['name']}')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}