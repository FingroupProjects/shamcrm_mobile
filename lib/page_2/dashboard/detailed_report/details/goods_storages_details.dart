import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

import '../../../../models/page_2/dashboard/dashboard_goods_report.dart';

void showGoodsStoragesDetailsDialog(
  BuildContext context,
  DashboardGoods goods,
) {
  showDialog(
    context: context,
    barrierColor: context.appColors.overlay,
    builder: (dialogContext) => GoodsStoragesDetailsDialog(goods: goods),
  );
}

class GoodsStoragesDetailsDialog extends StatelessWidget {
  const GoodsStoragesDetailsDialog({
    super.key,
    required this.goods,
  });

  final DashboardGoods goods;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 980,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: context.appShadows.floating,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Остаток по складам',
                      style: textStyles.titleLg.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.close,
                        color: colors.iconPrimary,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                goods.name,
                style: textStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        '#',
                        style: textStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Название',
                        style: textStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Кол-во',
                        style: textStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Сумма',
                        style: textStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: goods.storages.isEmpty
                    ? Center(
                        child: Text(
                          'Склады не найдены',
                          style: textStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: goods.storages.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final storage = goods.storages[index];
                          final isEven = index.isEven;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: isEven
                                  ? colors.surfacePrimary
                                  : colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    '${index + 1}',
                                    style: textStyles.bodyMd.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    storage.name,
                                    style: textStyles.bodyMd.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    storage.quantity,
                                    textAlign: TextAlign.center,
                                    style: textStyles.bodyMd.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    storage.sum,
                                    textAlign: TextAlign.end,
                                    style: textStyles.bodyMd.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
