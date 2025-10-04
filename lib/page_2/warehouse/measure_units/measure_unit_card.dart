import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_event.dart';
import 'package:crm_task_manager/models/page_2/measure_unit_model.dart';
import 'package:crm_task_manager/page_2/warehouse/measure_units/edit_measure_unit_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/measure_units/measure_unit_deletion.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MeasureUnitCard extends StatefulWidget {
  final MeasureUnitModel supplier;
  final VoidCallback? onDelete;
  // НОВОЕ: Параметры прав доступа
  final bool hasUpdatePermission;
  final bool hasDeletePermission;
  final VoidCallback? onUpdate;

  const MeasureUnitCard({
    Key? key,
    required this.supplier,
    this.onDelete,
    this.hasUpdatePermission = false,
    this.hasDeletePermission = false,
    this.onUpdate,
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
      // ИЗМЕНЕНО: Открываем редактирование только если есть право
      onTap: widget.hasUpdatePermission
          ? () {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditMeasureUnitScreen(measureUnit: widget.supplier),
                  ),
                ).then((_) {
                  if (widget.onUpdate != null) {
                    widget.onUpdate!();
                  } else {
                    context.read<MeasureUnitsBloc>().add(const FetchMeasureUnits());
                  }
                });
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDF5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
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
                    '${localization!.translate('empty_0') ?? 'Единица измерения'} ${widget.supplier.name ?? 'N/A'}',
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
                // ИЗМЕНЕНО: Показываем кнопку удаления только если есть право
                if (widget.hasDeletePermission)
                  GestureDetector(
                    child: Image.asset(
                      'assets/icons/delete.png',
                      width: 24,
                      height: 24,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => MeasureUnitDeleteDialog(measureUnitId: widget.supplier.id),
                      ).then((value) {
                        if (widget.onUpdate != null) {
                          widget.onUpdate!();
                        } else {
                          context.read<MeasureUnitsBloc>().add(const FetchMeasureUnits());
                        }
                      });
                    },
                  ),
              ],
            ),
            if (widget.supplier.shortName != null && widget.supplier.shortName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${localization.translate('shortName') ?? 'Краткое название'}: ${widget.supplier.shortName}',
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
              '${localization.translate('created_at_details') ?? 'Дата создания'}: ${_formatDate(widget.supplier.createdAt.toIso8601String())}',
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