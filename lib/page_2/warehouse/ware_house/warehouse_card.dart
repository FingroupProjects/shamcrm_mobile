import 'package:crm_task_manager/bloc/page_2_BLOC/document/storage/bloc/storage_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/storage/bloc/storage_event.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/page_2/warehouse/ware_house/edit_storage_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/ware_house/warehaouse_deletion.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class WareHouseCard extends StatefulWidget {
  final WareHouse warehouse;
  final VoidCallback? onDelete;

  const WareHouseCard({
    Key? key,
    required this.warehouse,
    this.onDelete,
  }) : super(key: key);

  @override
  State<WareHouseCard> createState() => _WareHouseCardState();
}

class _WareHouseCardState extends State<WareHouseCard> {
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
              builder: (context) => EditWarehouseScreen(
                warehouse: widget.warehouse,
                userIds: widget.warehouse.userIds ?? [], // Get userIds from warehouse or empty list
              ),
            ),
          ).then((result) {
            // Если результат true, обновляем список
            if (result == true) {
              context.read<WareHouseBloc>().add(FetchWareHouse());
            }
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
                    '${localization!.translate('storage') ?? 'Склад'}: ${widget.warehouse.name ?? 'N/A'}',
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
                      builder: (context) =>
                          WareHouseDeletion(wareHouseId: widget.warehouse.id),
                    ).then((_) {
                      context.read<WareHouseBloc>().add(FetchWareHouse());
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${localization.translate('created_at_details') ?? 'Дата создания'}: ${_formatDate(widget.warehouse.createdAt.toString())}',
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