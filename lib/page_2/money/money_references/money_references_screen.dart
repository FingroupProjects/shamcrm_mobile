import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../custom_widget/custom_app_bar_page_2.dart';
import '../../../screens/profile/languages/app_localizations.dart';
import '../../../screens/profile/profile_screen.dart';

import '../../../bloc/cash_desk/cash_desk_bloc.dart';
import '../../../bloc/expense/expense_bloc.dart';
import '../../../bloc/income/income_bloc.dart';
import 'cash_desk/cash_desk_screen.dart';
import 'expense/expense_screen.dart';
import 'income/income_screen.dart';

class MoneyReferencesScreen extends StatefulWidget {
  const MoneyReferencesScreen({super.key});

  @override
  State<MoneyReferencesScreen> createState() => _MoneyReferencesScreenState();
}

class _MoneyReferencesScreenState extends State<MoneyReferencesScreen> {
  bool isClickAvatarIcon = false;

  List<_ReferenceSection> _getSections(BuildContext context) => [
    _ReferenceSection(
      title: AppLocalizations.of(context)?.translate('cash_desk') ?? 'Касса',
      description: AppLocalizations.of(context)?.translate('cash_desk_management') ?? 'Управление кассами',
      icon: Icons.account_balance_wallet,
      color: const Color(0xff4CAF50),
      background: const Color(0xffEAF7F0),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => CashDeskBloc(),
              child: const CashDeskScreen(),
            ),
          ),
        );
      },
    ),
    _ReferenceSection(
      title: AppLocalizations.of(context)?.translate('expense_type') ?? 'Статьи расходов',
      description: AppLocalizations.of(context)?.translate('expenses_management') ?? 'Управление расходами',
      icon: Icons.remove_circle_outline,
      color: const Color(0xffFF9800),
      background: const Color(0xffFFF5E5),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => ExpenseBloc(),
              child: const ExpenseScreen(),
            ),
          ),
        );
      },
    ),
    _ReferenceSection(
      title: AppLocalizations.of(context)?.translate('income_type') ?? 'Статьи доходов',
      description: AppLocalizations.of(context)?.translate('incomes_management') ?? 'Управление доходами',
      icon: Icons.add_circle_outline,
      color: const Color(0xff2196F3),
      background: const Color(0xffEAF2FB),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => IncomeBloc(),
              child: const IncomeScreen(),
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
        title: CustomAppBarPage2(
          title: isClickAvatarIcon
              ? AppLocalizations.of(context)?.translate('appbar_settings') ?? 'Настройки'
              : AppLocalizations.of(context)?.translate('references') ?? 'Справочники',
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
            });
          },
          clearButtonClickFiltr: (isSearching) {},
          showSearchIcon: false,
          showFilterIcon: false,
          showFilterOrderIcon: false,
          onChangedSearchInput: (input) {},
          textEditingController: TextEditingController(),
          focusNode: FocusNode(),
          clearButtonClick: (isSearching) {},
          currentFilters: {},
        ),
      ),
      body: isClickAvatarIcon ?
          ProfileScreen() :
          ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              AppLocalizations.of(context)?.translate('sections') ?? 'Разделы',
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

  Widget _buildSectionCard(_ReferenceSection section) {
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

class _ReferenceSection {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  _ReferenceSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });
}