import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/page_2/widgets/product_network_image.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

class OrderGoodsScreen extends StatefulWidget {
  final List<Good> goods;
  final Order order;

  const OrderGoodsScreen({
    required this.order,
    Key? key,
    required this.goods,
  }) : super(key: key);

  @override
  _OrderGoodsState createState() => _OrderGoodsState();
}

class _OrderGoodsState extends State<OrderGoodsScreen> {
  @override
  Widget build(BuildContext context) {
    return _buildGoodsList(widget.goods);
  }

  Widget _buildGoodsList(List<Good> goods) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(AppLocalizations.of(context)!.translate('goods')),
        const SizedBox(height: 8),
        if (goods.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration(context),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.translate('empty'),
                    style:  TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 550,
            child: ListView.builder(
              primary: false,
              physics: const ClampingScrollPhysics(),
              itemCount: goods.length,
              itemBuilder: (context, index) {
                return _buildGoodsItem(goods[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGoodsItem(Good good) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () {
        _navigateToGoodsDetails(good);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: TaskCardStyles.taskCardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        good.goodName,
                        style: TaskCardStyles.titleStyle(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate('counts'),
                            style:  TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${good.quantity}',
                            style:  TextStyle(
                              fontSize: 18,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildImageWidget(good),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(Good good) {
    List<GoodFile> files = good.good.files;
    if (files.isEmpty && good.variantGood != null) {
      files = good.variantGood!.files;
    }

    return ProductNetworkImage(
      imageUrl: files.isNotEmpty ? files[0].path : null,
    );
  }

  // ИСПРАВЛЕННЫЙ МЕТОД - здесь была проблема!
  void _navigateToGoodsDetails(Good good) {
    final colors = context.appColors;
    int correctGoodId = good.getCorrectGoodId();
    debugPrint('Navigating to GoodsDetailsScreen with ID: $correctGoodId (goodId: ${good.goodId}, variantGood.id: ${good.variantGood?.id}, good.id: ${good.good.id})');

    if (correctGoodId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: Не удалось определить ID товара'),
          backgroundColor: colors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoodsDetailsScreen(
          id: correctGoodId,
          isFromOrder: true,
        ),
      ),
    );
  }

  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start, // Выравнивание заголовка слева
      children: [
        Text(
          title,
          style: TaskCardStyles.titleStyle(context).copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class DeleteGoodsDialog extends StatelessWidget {
  const DeleteGoodsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('delete_deal_dialog')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.translate('cancel')),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(AppLocalizations.of(context)!.translate('delete')),
        ),
      ],
    );
  }
}

class CategoryGoodsAddScreen extends StatelessWidget {
  const CategoryGoodsAddScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('addDeal')),
      ),
      body: Center(
        child: Text(AppLocalizations.of(context)!.translate('add_deal_screen')),
      ),
    );
  }
}