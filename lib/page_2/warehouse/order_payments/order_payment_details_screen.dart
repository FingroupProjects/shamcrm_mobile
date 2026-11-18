import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/models/page_2/order_payment_model.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/styled_action_button.dart';
import 'package:crm_task_manager/page_2/warehouse/order_payments/create_order_payment_screen.dart';
import 'package:crm_task_manager/page_2/widgets/document_confirm_dialog.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrderPaymentDetailsScreen extends StatefulWidget {
  final OrderPayment payment;
  final VoidCallback? onPaymentUpdated;
  final bool hasUpdatePermission;
  final bool hasDeletePermission;
  final bool hasApprovePermission;

  const OrderPaymentDetailsScreen({
    super.key,
    required this.payment,
    this.onPaymentUpdated,
    this.hasUpdatePermission = true,
    this.hasDeletePermission = true,
    this.hasApprovePermission = true,
  });

  @override
  State<OrderPaymentDetailsScreen> createState() => _OrderPaymentDetailsScreenState();
}

class _OrderPaymentDetailsScreenState extends State<OrderPaymentDetailsScreen> {
  final ApiService _api = ApiService();
  late OrderPayment _payment;
  bool _isButtonLoading = false;
  bool _isPrinting = false;
  bool _updated = false;

  @override
  void initState() {
    super.initState();
    _payment = widget.payment;
  }

  Future<void> _approvePayment() async {
    setState(() => _isButtonLoading = true);
    try {
      final allocation = _payment.allocations.isNotEmpty
          ? _payment.allocations.map((a) => a.toJson()).toList()
          : [
              {
                'amount': _payment.amount,
                'type': 'unallocated',
                'obligation_id': null,
                'schedule_line_id': null,
              }
            ];
      await _api.confirmInstallmentPayment(
        orderId: _payment.orderId,
        paymentId: _payment.id,
        allocations: allocation,
      );
      if (!mounted) return;
      setState(() {
        _payment = _payment.copyWith(status: 'confirmed', confirmedAt: DateTime.now().toIso8601String());
        _updated = true;
      });
      showCustomSnackBar(context: context, message: 'Платёж успешно проведён', isSuccess: true);
      widget.onPaymentUpdated?.call();
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    } finally {
      if (mounted) setState(() => _isButtonLoading = false);
    }
  }

  Future<void> _unapprovePayment() async {
    setState(() => _isButtonLoading = true);
    try {
      await _api.reverseInstallmentPayment(
        orderId: _payment.orderId,
        paymentId: _payment.id,
        reason: 'Отмена проведения из складского учёта',
      );
      if (!mounted) return;
      setState(() {
        _payment = _payment.copyWith(status: 'reversed');
        _updated = true;
      });
      showCustomSnackBar(context: context, message: 'Проведение платежа отменено', isSuccess: true);
      widget.onPaymentUpdated?.call();
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    } finally {
      if (mounted) setState(() => _isButtonLoading = false);
    }
  }

  Future<void> _deletePayment() async {
    final confirmed = await DocumentConfirmDialog.showDeleteConfirmation(
      context,
      _payment.documentNumber ?? _payment.id.toString(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isButtonLoading = true);
    try {
      await _api.deleteOrderPayment(orderId: _payment.orderId, paymentId: _payment.id);
      if (!mounted) return;
      showCustomSnackBar(context: context, message: 'Платёж удалён', isSuccess: true);
      widget.onPaymentUpdated?.call();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context: context, message: e.toString().replaceFirst('Exception: ', ''), isSuccess: false);
    } finally {
      if (mounted) setState(() => _isButtonLoading = false);
    }
  }

  Future<void> _editPayment() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderPaymentScreen(existingPayment: _payment),
      ),
    );
    if (result == true && mounted) {
      _updated = true;
      widget.onPaymentUpdated?.call();
      Navigator.pop(context, true);
    }
  }

  Future<void> _printReceipt() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      final regular = await rootBundle.load('assets/fonts/Gilroy-Regular.ttf');
      final bold = await rootBundle.load('assets/fonts/Gilroy-Bold.ttf');
      final font = pw.Font.ttf(regular);
      final fontBold = pw.Font.ttf(bold);

      final doc = pw.Document();
      final docNumber = _payment.documentNumber != null && _payment.documentNumber!.trim().isNotEmpty
          ? _payment.documentNumber!
          : _payment.id.toString();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'КВИТАНЦИЯ К ПРИХОДНОМУ ОРДЕРУ',
                      style: pw.TextStyle(font: fontBold, fontSize: 16),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      '№ $docNumber от ${_payment.formattedPaidAt}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  _pdfRow(fontBold, 'Принято от:', _payment.buyer ?? '—'),
                  _pdfRow(fontBold, 'Основание:', 'Оплата по сделке №${_payment.orderNumber ?? _payment.orderId}${_payment.object != null ? " (${_payment.object})" : ""}'),
                  _pdfRow(fontBold, 'Способ оплаты:', _payment.methodLabel),
                  _pdfRow(fontBold, 'Сумма к зачислению:', '${_payment.formattedAmount} ${_payment.allocationsSummary}'),
                  if (_payment.comment != null && _payment.comment!.trim().isNotEmpty)
                    _pdfRow(fontBold, 'Примечание:', _payment.comment!),
                  _pdfRow(fontBold, 'Кассир / Менеджер:', _payment.manager ?? '—'),
                  pw.SizedBox(height: 32),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('М.П.', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('Подпись: __________________', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.sharePdf(bytes: await doc.save(), filename: 'receipt-$docNumber.pdf');
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context: context, message: 'Не удалось подготовить печать', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  pw.Widget _pdfRow(pw.Font fontBold, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 140, child: pw.Text(label, style: pw.TextStyle(font: fontBold, fontSize: 11))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildTopActionButtons(dynamic colors) {
    if (_isButtonLoading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: colors.buttonPrimaryBg),
        ),
      );
    }

    final buttons = <Widget>[];

    if (_payment.isDraft && widget.hasApprovePermission) {
      buttons.add(
        StyledActionButton(
          text: 'Провести',
          icon: Icons.check_circle_outline,
          color: const Color(0xFF16A34A),
          onPressed: _approvePayment,
        ),
      );
    } else if (_payment.isConfirmed && widget.hasApprovePermission) {
      buttons.add(
        StyledActionButton(
          text: 'Отменить проведение',
          icon: Icons.cancel_outlined,
          color: const Color(0xFFDC2626),
          onPressed: _unapprovePayment,
        ),
      );
    }

    buttons.add(
      StyledActionButton(
        text: _isPrinting ? 'Печатаем…' : 'Печатать',
        icon: Icons.print_outlined,
        color: colors.buttonPrimaryBg,
        onPressed: _isPrinting ? () {} : _printReceipt,
      ),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: buttons,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final docTitle = _payment.documentNumber != null && _payment.documentNumber!.trim().isNotEmpty
        ? '№${_payment.documentNumber}'
        : 'Платёж №${_payment.id}';

    final details = [
      {'label': 'Документ:', 'value': docTitle},
      {'label': 'Статус:', 'value': _payment.statusLabel, 'color': _payment.statusColor(colors)},
      {'label': 'Дата платежа:', 'value': _payment.formattedPaidAt},
      {'label': 'Сумма:', 'value': _payment.formattedAmount, 'strong': true},
      {'label': 'Способ оплаты:', 'value': _payment.methodLabel},
      {'label': 'Клиент:', 'value': _payment.buyer ?? '—'},
      {'label': 'Сделка:', 'value': 'Сделка №${_payment.orderNumber ?? _payment.orderId}'},
      if (_payment.object != null && _payment.object!.trim().isNotEmpty)
        {'label': 'Объект:', 'value': _payment.object!},
      if (_payment.orderSum != null)
        {'label': 'Сумма сделки:', 'value': _payment.formattedOrderSum},
      {'label': 'Менеджер:', 'value': _payment.manager ?? '—'},
      {'label': 'Распределение:', 'value': _payment.allocationsSummary},
      if (_payment.comment != null && _payment.comment!.trim().isNotEmpty)
        {'label': 'Примечание:', 'value': _payment.comment!},
      if (_payment.confirmedAt != null)
        {'label': 'Проведён:', 'value': _payment.confirmedAt!},
    ];

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _updated && widget.onPaymentUpdated != null) {
          widget.onPaymentUpdated!();
        }
      },
      child: Scaffold(
        backgroundColor: colors.surfacePrimary,
        appBar: AppBar(
          backgroundColor: colors.surfacePrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context, _updated),
          ),
          title: Text(
            'Платёж $docTitle',
            style: TextStyle(fontFamily: 'Gilroy', fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          actions: [
            IconButton(
              tooltip: 'Печатать',
              icon: Icon(Icons.print_outlined, color: colors.iconPrimary),
              onPressed: _isPrinting ? null : _printReceipt,
            ),
            if (widget.hasUpdatePermission)
              IconButton(
                tooltip: 'Редактировать',
                icon: Image.asset('assets/icons/edit.png', width: 22, height: 22, color: colors.iconPrimary),
                onPressed: _editPayment,
              ),
            if (widget.hasDeletePermission)
              IconButton(
                tooltip: 'Удалить',
                icon: Image.asset('assets/icons/delete.png', width: 22, height: 22, color: const Color(0xFFDC2626)),
                onPressed: _deletePayment,
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTopActionButtons(colors),
            ),
            _buildDetailsCard(
              details.map((d) {
                return {
                  'label': d['label']?.toString() ?? '',
                  'value': d['value']?.toString() ?? '',
                };
              }).toList(),
              colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(List<Map<String, String>> details, AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          for (int i = 0; i < details.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details[i]['label'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      details[i]['value'] ?? '',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < details.length - 1)
              Divider(height: 1, color: colors.borderSubtle.withValues(alpha: 0.5)),
          ],
        ],
      ),
    );
  }
}
