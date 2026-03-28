import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
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
    final localization = AppLocalizations.of(context);

    return GestureDetector(
      // ИЗМЕНЕНО: Открываем редактирование только если есть право
      onTap: widget.hasUpdatePermission
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditSupplierScreen(supplier: widget.supplier),
                ),
              ).then((_) {
                if (widget.onUpdate != null) {
                  widget.onUpdate!();
                } else {
                  // BLoC использует сохраненный query
                  context.read<SupplierBloc>().add(FetchSupplier());
                }
              });
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
                    '${localization!.translate('empty_0') ?? 'Поставщик'} ${widget.supplier.name ?? 'N/A'}',
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
                        builder: (context) => SupplierDeleteDialog(documentId: widget.supplier.id),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: Color(0xff99A4BA),
                ),
              ),
            ],

            if (widget.supplier.inn != null) ...[
              const SizedBox(height: 8),
              Text(
                '${localization.translate('inn') ?? 'ИНН'}: ${widget.supplier.inn ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: Color(0xff99A4BA),
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
