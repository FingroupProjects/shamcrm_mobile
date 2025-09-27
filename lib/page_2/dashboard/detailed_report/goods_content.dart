import 'package:flutter/material.dart';

import '../../../models/page_2/dashboard/dashboard_goods_report.dart';
import 'cards/goods_card.dart';

class GoodsContent extends StatefulWidget {
  const GoodsContent({super.key});

  @override
  State<GoodsContent> createState() => _GoodsContentState();
}

class _GoodsContentState extends State<GoodsContent> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(
            5,
            (index) => Container(
                margin: EdgeInsets.only(bottom: 16),
                child: GoodsCard(
                    goods: DashboardGoods(
                        id: 1,
                        article: 'article',
                        name: 'name',
                        category: 'category',
                        quantity: '1',
                        daysWithoutMovement: '1',
                        sum: '1'),
                    onClick: (e) {},
                    onLongPress: (e) {},
                    isSelectionMode: false,
                    isSelected: false)),
          )
        ],
      ),
    );
  }
}
