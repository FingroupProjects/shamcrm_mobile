import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

class ChessGridSettingsView extends StatefulWidget {
  final ChessGridController controller;

  const ChessGridSettingsView({super.key, required this.controller});

  @override
  State<ChessGridSettingsView> createState() => _ChessGridSettingsViewState();
}

class _ChessGridSettingsViewState extends State<ChessGridSettingsView> {
  late TextEditingController _limController;
  late TextEditingController _compNameController;
  late TextEditingController _compAddrController;
  late TextEditingController _compTelController;
  late TextEditingController _compMailController;
  late TextEditingController _compInnController;

  final List<TextEditingController> _roleDurationControllers = [];

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _limController = TextEditingController(text: '${c.monthlyBookingLimit}');
    _compNameController = TextEditingController(text: c.requisites.name);
    _compAddrController = TextEditingController(text: c.requisites.address);
    _compTelController = TextEditingController(text: c.requisites.phone);
    _compMailController = TextEditingController(text: c.requisites.email);
    _compInnController = TextEditingController(text: c.requisites.inn);

    for (final r in c.roleSettings) {
      _roleDurationControllers.add(TextEditingController(text: '${r.durationDays}'));
    }
  }

  @override
  void dispose() {
    _limController.dispose();
    _compNameController.dispose();
    _compAddrController.dispose();
    _compTelController.dispose();
    _compMailController.dispose();
    _compInnController.dispose();
    for (final c in _roleDurationControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = widget.controller;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Roles & Duration
          _buildCard(
            title: 'Срок бронирования по ролям',
            subtitle: 'Срок начинается при создании заказа. Когда он истекает, заказ получает статус «Неуспешно», а квартира снова становится свободной.',
            child: Column(
              children: [
                for (int i = 0; i < controller.roleSettings.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.roleSettings[i].roleName,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _roleDurationControllers[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (val) {
                              final d = int.tryParse(val) ?? 1;
                              controller.updateRoleDuration(i, d);
                            },
                            decoration: InputDecoration(
                              suffixText: 'дн.',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < controller.roleSettings.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Monthly Limit
          _buildCard(
            title: 'Лимит бронирований в месяц',
            subtitle: 'Сколько раз в месяц одну и ту же квартиру можно брать в бронь.',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Лимит на 1 квартиру:',
                  style: TextStyle(fontFamily: 'Golos', fontSize: 13, color: colors.textPrimary),
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _limController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (val) {
                      final l = int.tryParse(val) ?? 3;
                      controller.updateMonthlyLimit(l);
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Automatic Status Rules (TZ table)
          _buildCard(
            title: 'Автоматические статусы',
            subtitle: 'Правила синхронизации статусов заказа и квартиры согласно ТЗ.',
            child: Table(
              border: TableBorder.all(color: colors.borderSubtle),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: colors.surfaceElevated),
                  children: [
                    _buildTh('Событие'),
                    _buildTh('Заказ'),
                    _buildTh('Квартира'),
                  ],
                ),
                _buildRuleRow('Создание заказа', 'В работе', 'Бронь'),
                _buildRuleRow('Заказ успешно завершён', 'Успешно', 'Продано'),
                _buildRuleRow('Заказ закрыт без продажи', 'Неуспешно', 'Свободно'),
                _buildRuleRow('Истёк срок бронирования', 'Неуспешно', 'Свободно'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Company Requisites for Document
          _buildCard(
            title: 'Реквизиты в шаблоне графика',
            subtitle: 'Заполняются администратором и подставляются в шапку печатного графика.',
            child: Column(
              children: [
                _buildTextField(_compNameController, 'Название компании'),
                const SizedBox(height: 10),
                _buildTextField(_compAddrController, 'Юридический адрес'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_compTelController, 'Телефон')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_compMailController, 'Email')),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField(_compInnController, 'ИНН / регистрация'),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      controller.updateCompanyRequisites(CompanyRequisites(
                        name: _compNameController.text.trim(),
                        address: _compAddrController.text.trim(),
                        phone: _compTelController.text.trim(),
                        email: _compMailController.text.trim(),
                        inn: _compInnController.text.trim(),
                      ));
                      showCustomSnackBar(context: context, message: 'Реквизиты сохранены', isSuccess: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.buttonPrimaryBg,
                      foregroundColor: colors.buttonPrimaryFg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Сохранить реквизиты'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildRuleRow(String event, String orderSt, String aptSt) {
    return TableRow(
      children: [
        _buildTd(event),
        _buildTd(orderSt, isBold: true),
        _buildTd(aptSt, isBold: true),
      ],
    );
  }

  Widget _buildTh(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 11.5),
      ),
    );
  }

  Widget _buildTd(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Golos',
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required String subtitle, required Widget child}) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 15, color: colors.textPrimary),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(fontFamily: 'Golos', fontSize: 11.5, color: colors.textSecondary),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    final colors = context.appColors;
    return TextField(
      controller: controller,
      style: TextStyle(fontFamily: 'Golos', fontSize: 13, color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: colors.surfaceElevated.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

