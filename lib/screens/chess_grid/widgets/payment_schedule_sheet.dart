import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class PaymentScheduleSheet extends StatelessWidget {
  final Order order;

  const PaymentScheduleSheet({super.key, required this.order});

  static Future<void> show({
    required BuildContext context,
    required Order order,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentScheduleSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = ChessGridController.instance;
    final req = controller.requisites;
    final apt = controller.findApartmentById(order.apartmentId);
    final park = controller.findParkingById(order.parkingId);
    final pay = order.paymentDetails;
    final schedule = pay?.schedule ?? [];

    final dateFormat = DateFormat('dd.MM.yyyy');
    final today = dateFormat.format(DateTime.now());

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'График платежей по рассрочке',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 16.5,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: colors.iconSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable document content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.buttonPrimaryBg.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.apartment_rounded, color: colors.buttonPrimaryBg, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.name,
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${req.address}\nТелефон: ${req.phone}\nEmail: ${req.email}\n${req.inn}',
                                style: TextStyle(
                                  fontFamily: 'Golos',
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Document Title & Meta
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'ГРАФИК ПЛАТЕЖЕЙ ПО РАССРОЧКЕ',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.4,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Номер графика: ${order.id} · Дата: $today\nОснование: договор № ${order.id.replaceAll('З', 'ДП')} от $today',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Golos',
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 1: Buyer & Object Info
                    _buildSectionHeader(context, '1. Сведения о покупателе и объекте'),
                    const SizedBox(height: 8),
                    _buildDocTable(context, [
                      ['Покупатель', order.buyerName],
                      ['Жилой комплекс', controller.complex.name],
                      if (apt != null) ...[
                        ['Корпус', apt.buildingName],
                        ['Подъезд', '${apt.entrance}'],
                        ['Этаж', '${apt.floor}'],
                        ['Квартира', '№ ${apt.number}'],
                        ['Общая площадь', '${apt.totalArea} м²'],
                      ] else if (park != null) ...[
                        ['Парковочное место', park.number],
                        ['Тип парковки', park.type],
                        ['Площадь', '${park.area} м²'],
                      ],
                    ]),
                    const SizedBox(height: 16),

                    // Section 2: Terms of Payment
                    _buildSectionHeader(context, '2. Условия оплаты'),
                    const SizedBox(height: 8),
                    _buildDocTable(context, [
                      ['Общая стоимость объекта', '${order.price.toStringAsFixed(2)} \$'],
                      ['Первоначальный взнос', '${(pay?.downPayment ?? 0).toStringAsFixed(2)} \$'],
                      if (pay?.barterSubject != null && (pay?.barterAmount ?? 0) > 0)
                        ['Бартер (${pay!.barterSubject})', '${pay.barterAmount.toStringAsFixed(2)} \$'],
                      ['Остаток в рассрочку', '${(pay?.installmentSum ?? 0).toStringAsFixed(2)} \$'],
                      ['Срок рассрочки', '${pay?.months ?? 12} мес.'],
                      if (schedule.isNotEmpty) ...[
                        ['Дата первого платежа', dateFormat.format(schedule.first.date)],
                        ['Дата последнего платежа', dateFormat.format(schedule.last.date)],
                        ['Плановый ежемесячный платёж', '${schedule.first.paymentAmount.toStringAsFixed(2)} \$'],
                      ],
                      ['Валюта платежей', 'USD (\$)'],
                    ]),
                    const SizedBox(height: 16),

                    // Section 3: Payment Schedule Table
                    _buildSectionHeader(context, '3. График платежей'),
                    const SizedBox(height: 8),
                    if (schedule.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Сделка без рассрочки (наличный расчёт)',
                          style: TextStyle(fontFamily: 'Golos', fontSize: 12, color: colors.textSecondary),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.borderSubtle),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Table(
                            border: TableBorder.symmetric(
                              inside: BorderSide(color: colors.borderSubtle, width: 0.8),
                            ),
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(2.2),
                              2: FlexColumnWidth(2.2),
                              3: FlexColumnWidth(2.5),
                            },
                            children: [
                              // Table Header
                              TableRow(
                                decoration: BoxDecoration(color: colors.surfaceElevated),
                                children: [
                                  _buildTh(context, '№'),
                                  _buildTh(context, 'Дата'),
                                  _buildTh(context, 'Платёж'),
                                  _buildTh(context, 'Остаток'),
                                ],
                              ),
                              // Table Rows
                              for (final row in schedule)
                                TableRow(
                                  children: [
                                    _buildTd(context, '${row.number}', isCenter: true),
                                    _buildTd(context, dateFormat.format(row.date)),
                                    _buildTd(context, '${row.paymentAmount.toStringAsFixed(2)} \$', isBold: true),
                                    _buildTd(context, '${row.remainingDebt.toStringAsFixed(2)} \$'),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Section 4: Terms
                    _buildSectionHeader(context, '4. Порядок оплаты'),
                    const SizedBox(height: 6),
                    Text(
                      '• Покупатель осуществляет платежи в размерах и сроки, указанные в настоящем графике, с учётом условий договора.\n'
                      '• Первоначальный взнос учитывается отдельно и не включается повторно в сумму платежей по рассрочке.\n'
                      '• Последний платёж может незначительно отличаться в связи с округлением сумм.\n'
                      '• Фактическое исполнение определяется по поступившим платежам. Наличие графика не подтверждает факт оплаты.',
                      style: TextStyle(
                        fontFamily: 'Golos',
                        fontSize: 11,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 5: Signatures
                    _buildSectionHeader(context, '5. Подтверждение и подписи сторон'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Продавец:\n${req.name}\n\nПодпись: _____________\nДата: $today',
                                style: TextStyle(
                                  fontFamily: 'Golos',
                                  fontSize: 11,
                                  color: colors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Покупатель:\n${order.buyerName}\n\nПодпись: _____________\nДата: $today',
                                style: TextStyle(
                                  fontFamily: 'Golos',
                                  fontSize: 11,
                                  color: colors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'Документ сформирован в мобильной системе shamCRM',
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontSize: 10,
                          color: colors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final text = 'График платежей по рассрочке для заказа ${order.id}\n'
                          'Покупатель: ${order.buyerName}\n'
                          'Общая сумма: ${order.price} \$\n'
                          'Первоначальный взнос: ${pay?.downPayment ?? 0} \$\n'
                          'Ежемесячный платёж: ${pay?.monthlyPayment.toStringAsFixed(2) ?? 0} \$\n'
                          'Срок: ${pay?.months ?? 12} месяцев.\n'
                          'Сформировано в shamCRM.';
                      Share.share(text, subject: 'График платежей ${order.id}');
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Поделиться'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.buttonPrimaryBg,
                      foregroundColor: colors.buttonPrimaryFg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.borderSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Закрыть'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = context.appColors;
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
        color: colors.buttonPrimaryBg,
      ),
    );
  }

  Widget _buildDocTable(BuildContext context, List<List<String>> rows) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i][0],
                    style: TextStyle(
                      fontFamily: 'Golos',
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    rows[i][1],
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Divider(height: 1, color: colors.borderSubtle.withValues(alpha: 0.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildTh(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: context.appColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTd(BuildContext context, String text, {bool isBold = false, bool isCenter = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        text,
        textAlign: isCenter ? TextAlign.center : TextAlign.right,
        style: TextStyle(
          fontFamily: 'Golos',
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          fontSize: 10.5,
          color: context.appColors.textPrimary,
        ),
      ),
    );
  }
}

