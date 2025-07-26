import 'package:flutter/material.dart';
import 'package:crm_task_manager/page_2/call_center/operator_chart_1.dart';
import 'package:crm_task_manager/page_2/call_center/operator_chart_2.dart';
import 'package:crm_task_manager/page_2/call_center/operator_chart_3.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class OperatorDetailsScreen extends StatelessWidget {
  final String operatorName;
  final int rating;

  const OperatorDetailsScreen({
    Key? key,
    required this.operatorName,
    required this.rating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          operatorName,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: List.generate(5, (starIndex) {
                return Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: Image.asset(
                    starIndex < rating && rating > 0
                        ? 'assets/icons/AppBar/star_on.png'
                        : 'assets/icons/AppBar/star_off.png',
                    width: 20,
                    height: 20,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:  [
            OperatorChartRating(),
            Divider(thickness: 1, color: Colors.grey[300]),
            SizedBox(height: 16),
            OperatorChart2(),
            Divider(thickness: 1, color: Colors.grey[300]),
            SizedBox(height: 16),
            OperatorChart3(),

          ],
        ),
      ),
    );
  }
}