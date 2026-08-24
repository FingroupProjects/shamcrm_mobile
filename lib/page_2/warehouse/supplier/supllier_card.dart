import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/edit_supplier_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/supplier_deletion.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SupplierCard extends StatefulWidget {
  final Supplier supplier;
  final VoidCallback? onDelete;

  // НОВОЕ: Параметры прав доступа
  final bool hasUpdatePermission;
  final bool hasDeletePermission;
  final VoidCallback? onUpdate;

  const SupplierCard({
    Key? key,
    required this.supplier,
    this.onDelete,
    this.hasUpdatePermission = false,
    this.hasDeletePermission = false,
    this.onUpdate,
  }) : super(key: key);

  @override
  State<SupplierCard> createState() => _SupplierCardState();
}

class _SupplierCardState extends State<SupplierCard> {
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
    final localization = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return GestureDetector(
      // ИЗМЕНЕНО: Открываем редактирование только если есть право
      onTap: widget.hasUpdatePermission
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditSupplierScreen(supplier: widget.supplier),
                ),
              ).then((wasUpdated) {
                // Перезагружаем список только если были сохранены изменения
                if (wasUpdated == true) {
                  if (widget.onUpdate != null) {
                    widget.onUpdate!();
                  } else {
                    // BLoC использует сохраненный query
                    context.read<SupplierBloc>().add(FetchSupplier());
                  }
                }
              });
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
                    widget.supplier.name ?? 'N/A',
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
                        builder: (context) => SupplierDeleteDialog(
                            documentId: widget.supplier.id),
                      ).then((value) {
                        // BLoC сам обновляет список после удаления с сохранением query
                        if (widget.onUpdate != null) {
                          widget.onUpdate!();
                        }
                      });
                    },
                  ),
              ],
            ),
            if (widget.supplier.phone != null) ...[
              const SizedBox(height: 8),
              Text(
                '${localization.translate('phone') ?? 'Телефон'}: ${widget.supplier.phone ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                ),
              ),
            ],

            if (widget.supplier.inn != null) ...[
              const SizedBox(height: 8),
              Text(
                '${localization.translate('inn') ?? 'ИНН'}: ${widget.supplier.inn ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                ),
              ),
            ]
            // if (widget.supplier.note != null && widget.supplier.note!.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 8),
            //     child: Text(
            //       '${localization.translate('note') ?? 'Примечание'}: ${widget.supplier.note}',
            //       style: const TextStyle(
            //         fontSize: 14,
            //         fontFamily: 'Gilroy',
            //         fontWeight: FontWeight.w400,
            //         color: Color(0xff99A4BA),
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}
