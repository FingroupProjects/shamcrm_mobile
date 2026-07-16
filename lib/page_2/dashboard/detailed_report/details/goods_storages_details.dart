import 'package:flutter/material.dart';

import '../../../../models/page_2/dashboard/dashboard_goods_report.dart';

void showGoodsStoragesDetailsDialog(
  BuildContext context,
  DashboardGoods goods,
) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff1E2E52).withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
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
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xffF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xff1E2E52),
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                goods.name,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff475569),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xffDCE8F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        '#',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff5A6D96),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Название',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff5A6D96),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Количество',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff5A6D96),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Сумма',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff5A6D96),
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
                    ? const Center(
                        child: Text(
                          'Склады не найдены',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff64748B),
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
                                  ? Colors.white
                                  : const Color(0xffF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xffE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xff1E2E52)
                                      .withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff42526E),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    storage.name,
                                    style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff42526E),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    storage.quantity,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff42526E),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    storage.sum,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff1E2E52),
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
