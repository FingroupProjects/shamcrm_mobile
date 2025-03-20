import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GoodsCard extends StatefulWidget {
  final int goodsId;
  final String goodsName;
  final String goodsDescription;
  final String goodsCategory;
  final double goodsPrice;
  final int goodsDiscountPrice;
  final int goodsStockQuantity;
  final List<String> goodsImagePath;
  final bool goodsIsActive;


  GoodsCard({
    Key? key,
    required this.goodsId,
    required this.goodsName,
    required this.goodsDescription,
    required this.goodsCategory,
    required this.goodsPrice,
    required this.goodsDiscountPrice,
    required this.goodsStockQuantity,
    required this.goodsImagePath,
    required this.goodsIsActive,
  }) : super(key: key);

  @override
  _GoodsCardState createState() => _GoodsCardState();
}

class _GoodsCardState extends State<GoodsCard> {
  String formatDate(String dateString) {
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

void _navigateToGoodsDetails() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GoodsDetailsScreen(
        id: widget.goodsId,
        goodsName: widget.goodsName,
        goodsDescription: widget.goodsDescription,
        goodsPrice: widget.goodsPrice,
        discountGoodsPrice: widget.goodsDiscountPrice,
        stockQuantity: widget.goodsStockQuantity,
        imagePaths: widget.goodsImagePath,
        selectedCategory: widget.goodsCategory, 
        isActive: widget.goodsIsActive, 
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
  onTap: () {
    _navigateToGoodsDetails();
  },
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Container(
      decoration: TaskCardStyles.taskCardDecoration,
      child: Padding(
        padding: const EdgeInsets.only(left: 16,right: 16,top: 12,bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.goodsName,
                    style: TaskCardStyles.titleStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      text: widget.goodsDescription,
                      style: TaskCardStyles.priorityStyle.copyWith(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff1E2E52),
                      ),
                      children: const <TextSpan>[
                        TextSpan(
                          text: '\n\u200B', 
                          style: TaskCardStyles.priorityStyle,
                        ),
                      ],
                    ),
                  ),
                 SizedBox(height: 4),
                 RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: AppLocalizations.of(context)!.translate('category_card'), 
                            style: TaskCardStyles.priorityStyle.copyWith(
                            color: Color(0xff99A4BA),
                            ),
                          ),
                          TextSpan(
                            text: widget.goodsCategory,
                            style: TaskCardStyles.priorityStyle.copyWith(
                              color: Color(0xff1E2E52),
                              fontWeight: FontWeight.w600, 
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: AppLocalizations.of(context)!.translate('price'), 
                            style: TaskCardStyles.priorityStyle.copyWith(
                            color: Color(0xff99A4BA),
                            ),
                          ),
                          TextSpan(
                            text: '${widget.goodsPrice % 1 == 0 ? widget.goodsPrice.toInt() : widget.goodsPrice}',
                            style: TaskCardStyles.priorityStyle.copyWith(
                              color: Color(0xff1E2E52),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(width: 16), 
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 100,
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,   
                itemCount: widget.goodsImagePath.length,  
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),   
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        widget.goodsImagePath[index],   
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          )
          ],
        ),
      ),
    ),
  ),
);
  }
}

