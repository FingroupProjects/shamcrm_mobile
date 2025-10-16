import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/warehouse/client_return/client_return_details.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientReturnCard extends StatefulWidget {
  final IncomingDocument document;
  final Function()? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTap;

  const ClientReturnCard({
    Key? key,
    required this.document,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<ClientReturnCard> createState() => _ClientReturnCardState();
}

class _ClientReturnCardState extends State<ClientReturnCard> {
  int? currencyId;

  @override
  void initState() {
    super.initState();
    _loadCurrencyId();
  }

  Future<void> _loadCurrencyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currencyId = prefs.getInt('currency_id') ?? 1;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null)
      return AppLocalizations.of(context)!.translate('no_date') ?? 'Нет даты';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatSum(double sum) {
    String symbol = widget.document.currency?.symbolCode ?? '\$';
    return '${NumberFormat('#,##0.00', 'ru_RU').format(sum)} $symbol';
  }

  String _getLocalizedStatus() {
    final localizations = AppLocalizations.of(context)!;
    final doc = widget.document;

    if (doc.deletedAt != null) {
      return localizations.translate('deleted_incoming') ?? 'Удален';
    }

    if (doc.approved == 1) {
      return localizations.translate('approved_incoming') ?? 'Проведен';
    } else {
      return localizations.translate('not_approved_incoming') ?? 'Не проведен';
    }
  }

  Color _getStatusColor() {
    final doc = widget.document;

    if (doc.deletedAt != null) {
      return Colors.red;
    }

    return doc.approved == 1 ? Colors.green : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      onLongPress: widget.onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFFDDE8F5)
              : const Color(0xFFE9EDF5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${AppLocalizations.of(context)!.translate('empty_0') ?? 'Возврат'}№${doc.docNumber ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getLocalizedStatus(),
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.of(context)!.translate('date') ?? 'Дата'}: ${_formatDate(doc.date)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.of(context)!.translate('client') ?? 'Клиент'}: ${doc.model?.name ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.of(context)!.translate('storage') ?? 'Склад'}: ${doc.storage?.name ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLocalizations.of(context)!.translate('author') ?? 'Автор'}: ${doc.author?.name ?? 'N/A'}',
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
            if (widget.isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  widget.isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: Color(0xff1E2E52),
                  size: 24,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}