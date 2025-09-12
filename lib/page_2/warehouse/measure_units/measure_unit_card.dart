import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
import 'package:crm_task_manager/models/page_2/measure_unit_model.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/page_2/warehouse/measure_units/edit_measure_unit_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/measure_units/measure_unit_deletion.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/edit_supplier_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/supplier_deletion.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MeasureUnitCard extends StatefulWidget {
  final MeasureUnitModel supplier;
  final VoidCallback? onDelete;

  const MeasureUnitCard({
    Key? key,
    required this.supplier,
    this.onDelete,
  }) : super(key: key);

  @override
  State<MeasureUnitCard> createState() => _MeasureUnitCardState();
}

class _MeasureUnitCardState extends State<MeasureUnitCard> {
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
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EditMeasureUnitScreen(measureUnit: widget.supplier),
            ),
          ).then((_) {
            context.read<MeasureUnitsBloc>().add(FetchMeasureUnits());
          });
        }
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
                    '${localization!.translate('units_of_measurement') ?? 'Единицы измерения'}: ${widget.supplier.name ?? 'N/A'}',
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
                        builder: (context) => MeasureUnitDeleteDialog(
                            measureUnitId: widget.supplier.id)).then(
                      (value) {
                        context
                            .read<MeasureUnitsBloc>()
                            .add(FetchMeasureUnits());
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.supplier.shortName != null &&
                widget.supplier.shortName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${localization.translate('shortName') ?? 'Примечание'}: ${widget.supplier.shortName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff99A4BA),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${localization.translate('created_at') ?? 'Дата создания'}: ${_formatDate(widget.supplier.createdAt.toIso8601String())}',
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
