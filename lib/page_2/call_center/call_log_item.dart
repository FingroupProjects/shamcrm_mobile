import 'package:flutter/material.dart';
import 'package:crm_task_manager/page_2/call_center/operator_details.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class CallReportList extends StatelessWidget {
  const CallReportList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> callReports = [
      {
        'name': 'Алексей Петров',
        'phone': '+7 (999) 123-45-67',
        'date': '24.07.2025 14:37',
        'status': 'Позвонили',
        'rating': '4',
        'operatorName': 'Анна Кузнецова', // Добавлено имя оператора
      },
      {
        'name': 'Мария Смирнова',
        'phone': '+7 (999) 234-56-78',
        'date': '23.07.2025 09:15',
        'status': 'Не отвечено',
        'rating': '2',
        'operatorName': 'Игорь Соколов', // Добавлено имя оператора
      },
      {
        'name': 'Дмитрий Козлов',
        'phone': '+7 (999) 345-67-89',
        'date': '22.07.2025 16:20',
        'status': 'Позвонили',
        'rating': '5',
        'operatorName': 'Ольга Иванова', // Добавлено имя оператора
      },
      {
        'name': 'Елена Иванова',
        'phone': '+7 (999) 456-78-90',
        'date': '21.07.2025 11:30',
        'status': 'В процессе',
        'rating': '3',
        'operatorName': 'Павел Лебедев', // Добавлено имя оператора
      },
      {
        'name': 'Сергей Волков',
        'phone': '+7 (999) 567-89-01',
        'date': '20.07.2025 13:45',
        'status': 'Не отвечено',
        'rating': '1',
        'operatorName': 'Екатерина Орлова', // Добавлено имя оператора
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: callReports.length,
        itemBuilder: (context, index) {
          final report = callReports[index];
          final int rating = int.parse(report['rating']!);
          return InkWell(
            onTap: report['operatorName'] != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OperatorDetailsScreen(
                          operatorName: report['operatorName']!,
                        ),
                      ),
                    );
                  }
                : null,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6C5CE7),
                  child: const Icon(Icons.phone, color: Colors.white, size: 20),
                ),
                title: Text(
                  report['name']!,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      report['phone']!,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      report['date']!,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (starIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 2.0),
                          child: Image.asset(
                            starIndex < rating
                                ? 'assets/icons/AppBar/star_on.png'
                                : 'assets/icons/AppBar/star_off.png',
                            width: 16,
                            height: 16,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                // trailing: Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                //   decoration: BoxDecoration(
                //     color: report['status'] == 'Позвонили'
                //         ? Colors.green.withOpacity(0.1)
                //         : report['status'] == 'Не отвечено'
                //             ? Colors.red.withOpacity(0.1)
                //             : Colors.yellow.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Text(
                //     report['status']!,
                //     style: TextStyle(
                //       fontFamily: 'Gilroy',
                //       fontWeight: FontWeight.w500,
                //       fontSize: 12,
                //       color: report['status'] == 'Позвонили'
                //           ? Colors.green
                //           : report['status'] == 'Не отвечено'
                //               ? Colors.red
                //               : Colors.yellow.shade800,
                //     ),
                //   ),
                // ),
              ),
            ),
          );
        },
      ),
    );
  }
}