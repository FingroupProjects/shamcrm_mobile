import 'package:flutter/material.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('Деньги',
            style:
                TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xffF8F9FB),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'Разделы',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildSectionCard(
                'Приход', Icons.arrow_downward, Color(0xff4CAF50)),
            _buildSectionCard('Расход', Icons.arrow_upward, Color(0xffFF9800)),
            _buildSectionCard(
                'Справочники', Icons.menu_book, Color(0xff2196F3)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // TODO: Add navigation logic
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: const Color(0xffE5E9F2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xff99A4BA),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
