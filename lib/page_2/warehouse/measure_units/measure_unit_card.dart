import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
    final colors = context.appColors;

    return GestureDetector(
      // ИЗМЕНЕНО: Открываем редактирование только если есть право
      onTap: widget.hasUpdatePermission
          ? () {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditMeasureUnitScreen(measureUnit: widget.supplier),
                  ),
                ).then((result) {
                  if (result == true) {
                    if (widget.onUpdate != null) {
                      widget.onUpdate!();
                    } else {
                      context
                          .read<MeasureUnitsBloc>()
                          .add(const FetchMeasureUnits());
                    }
                  }
                });
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // ИЗМЕНЕНО: Показываем кнопку удаления только если есть право
                if (widget.hasDeletePermission)
                  IconButton(
                    tooltip: localization.translate('delete') ?? 'Удалить',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.buttonDangerBg,
                      size: 24,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => MeasureUnitDeleteDialog(
                            measureUnitId: widget.supplier.id),
                      ).then((result) {
                        if (result == true) {
                          // BLoC сам обновляет список после удаления с сохранением query
                          if (widget.onUpdate != null) {
                            widget.onUpdate!();
                          }
                        }
                      });
                    },
                  ),
              ],
            ),
            if (widget.supplier.shortName != null &&
                widget.supplier.shortName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${localization.translate('shortName') ?? 'Краткое название'}: ${widget.supplier.shortName}',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: colors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
