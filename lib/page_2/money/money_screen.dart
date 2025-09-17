import 'package:crm_task_manager/bloc/money_references/money_references_bloc.dart';
import 'package:crm_task_manager/page_2/money/money_income/money_income_screen.dart';
import 'package:crm_task_manager/page_2/money/money_references/cash_desk/cash_desk_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../bloc/money_income/money_income_bloc.dart';
import '../../screens/profile/languages/app_localizations.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  List<_MoneySection> _getSections(BuildContext context) => [
        _MoneySection(
          title: AppLocalizations.of(context)!.translate('income'),
          description:
              AppLocalizations.of(context)!.translate('add_income_money'),
          icon: Icons.arrow_downward,
          color: const Color(0xff4CAF50),
          background: const Color(0xffEAF7F0),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => MoneyIncomeBloc(),
                  child: const MoneyIncomeScreen(),
                ),
              ),
            );
          },
        ),
        _MoneySection(
          title: AppLocalizations.of(context)!.translate('expense'),
          description:
              AppLocalizations.of(context)!.translate('add_expense_money'),
          icon: Icons.arrow_upward,
          color: const Color(0xffFF9800),
          background: const Color(0xffFFF5E5),
          onTap: () {},
        ),
        _MoneySection(
          title: AppLocalizations.of(context)!.translate('references'),
          description:
              AppLocalizations.of(context)!.translate('list_references'),
          icon: Icons.menu_book,
          color: const Color(0xff2196F3),
          background: const Color(0xffEAF2FB),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => MoneyReferencesBloc(),
                  child: const MoneyReferencesScreen(),
                ),
              ),
            );
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final sections = _getSections(context);

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: AppBar(
        forceMaterialTransparency: true,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context)!.translate('money'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xff1E2E52),
            fontFamily: 'Gilroy',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              AppLocalizations.of(context)!.translate('sections'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...sections.map(_buildSectionCard).toList(),
        ],
      ),
    );
  }

  Widget _buildSectionCard(_MoneySection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: section.onTap,
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
                    color: section.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      section.icon,
                      size: 28,
                      color: section.color,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        section.description,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xff99A4BA),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoneySection {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  _MoneySection({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });
}
