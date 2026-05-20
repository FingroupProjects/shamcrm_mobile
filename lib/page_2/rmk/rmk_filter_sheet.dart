import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:flutter/material.dart';

Future<int?> showRmkFilterSheet({
  required BuildContext context,
  required List<RmkCategory> categories,
  required int? selectedCategoryId,
}) {
  return showModalBottomSheet<int?>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          itemCount: categories.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              final isSelected = selectedCategoryId == null;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Все товары',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xff1E2E52))
                    : null,
                onTap: () => Navigator.pop(context),
              );
            }

            final category = categories[index - 1];
            final leftPadding = (category.level * 14).clamp(0, 42).toDouble();
            return ListTile(
              contentPadding: EdgeInsets.only(left: leftPadding),
              dense: true,
              title: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: selectedCategoryId == category.id
                  ? const Icon(Icons.check, color: Color(0xff1E2E52))
                  : null,
              onTap: () => Navigator.pop(context, category.id),
            );
          },
        ),
      );
    },
  );
}
