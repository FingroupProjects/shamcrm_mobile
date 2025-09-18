import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
import 'package:crm_task_manager/models/page_2/price_type_model.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/page_2/warehouse/price_type/edit_pricetype_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/price_type/pricetype_deletion.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/edit_supplier_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/supplier_deletion.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class PriceTypeCard extends StatefulWidget {
  final PriceTypeModel supplier;
  final VoidCallback? onDelete;

  const PriceTypeCard({
    Key? key,
    required this.supplier,
    this.onDelete,
  }) : super(key: key);

  @override
  State<PriceTypeCard> createState() => _PriceTypeCardState();
}

class _PriceTypeCardState extends State<PriceTypeCard> {
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return AppLocalizations.of(context)!.translate('no_date') ?? 'Нет даты';
    }
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd.MM.yyyy').format(parsedDate);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('no_date') ?? 'Нет даты';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EditPriceTypeScreen(supplier: widget.supplier),
            ));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDF5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${localization!.translate('empty_0') ?? 'Поставщик'}${widget.supplier.name ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1E2E52),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  child: Image.asset(
                    'assets/icons/delete.png',
                    width: 24,
                    height: 24,
                  ),
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (_) => BlocProvider.value(
                              value: context.read<
                                  PriceTypeScreenBloc>(), // reuse the same instance
                              child: PriceTypesDeleteDialog(
                                  documentId: widget.supplier.id),
                            ));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${localization.translate('created_at_details') ?? 'Дата создания'}: ${_formatDate(widget.supplier.createdAt?.toIso8601String())}',
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
    );
  }
}
