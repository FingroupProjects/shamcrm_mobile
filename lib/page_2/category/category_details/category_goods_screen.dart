import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/page_2/goods/goods_add_screen.dart';
import 'package:crm_task_manager/page_2/goods/goods_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class Goods {
  final int id;
  final String goodsName;
  final String goodsDescription;
  final double goodsPrice;
  final double discountGoodsPrice;
  final double stockQuantity;
  final String imagePath;

  Goods({
    required this.id,
    required this.goodsName,
    required this.goodsDescription,
    required this.goodsPrice,
    required this.discountGoodsPrice,
    required this.stockQuantity,
    required this.imagePath,
  });
}
class CategoryGoodsScreen extends StatefulWidget {

  const CategoryGoodsScreen({Key? key, }) : super(key: key);

  @override
  _CategoryGoodsState createState() => _CategoryGoodsState();
}

class _CategoryGoodsState extends State<CategoryGoodsScreen> {
final List<Goods> testGoods = [
  Goods(
    id: 1,
    goodsName: 'Товар 1',
    goodsDescription: '🌟 Забудьте о компромиссах! Смартфон Nova X создан для тех, кто хочет максимум возможностей. Сверхчеткий экран, профессиональная камера и батарея, которая не подведёт. Воплотите мечты в реальность',
    goodsPrice: 50,
    discountGoodsPrice: 10,
    stockQuantity: 500,
    imagePath: 'assets/images/goods_photo.jpg', 
  ),
  Goods(
    id: 2,
    goodsName: 'Товар 2',
    goodsDescription: 'Тест описание тест тест тест  ',
    goodsPrice: 23,
    discountGoodsPrice: 0,
    stockQuantity: 1000,
    imagePath: 'assets/images/goods_photo.jpg', 
  ),
  Goods(
    id: 3,
    goodsName: 'Товар 3',
    goodsDescription: 'Тест описание тест тест тест тест тест тест тест тест тест тест тест тест тест тест тест тест тест тест тест',
    goodsPrice: 125.3,
    discountGoodsPrice: 30,
    stockQuantity: 712,
    imagePath: 'assets/images/goods_photo.jpg', 
  ),
  Goods(
    id: 4,
    goodsName: 'Товар 4',
    goodsDescription: 'Тест описание тест тест тест  ',
    goodsPrice: 23,
    discountGoodsPrice: 0,
    stockQuantity: 1000,
    imagePath: 'assets/images/goods_photo.jpg', 
  ),
  Goods(
    id: 5,
    goodsName: 'Товар 5',
    goodsDescription: 'Тест описание тест тест тест тест тест тест тест тест тест тест тест тест тест тест тест тест тест тест тест',
    goodsPrice: 125.3,
    discountGoodsPrice: 30,
    stockQuantity: 712,
    imagePath: 'assets/images/goods_photo.jpg', 
  ),
];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildGoodsList(testGoods);
  }

  Widget _buildGoodsList(List<Goods> goods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(AppLocalizations.of(context)!.translate('Товары')),
        SizedBox(height: 8),
        if (goods.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.translate('empty'),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 550,
            child: ListView.builder(
              itemCount: goods.length,
              itemBuilder: (context, index) {
                return _buildGoodsItem(goods[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGoodsItem(Goods goods) {
    return GestureDetector(
  onTap: () {
    _navigateToGoodsDetails(goods);
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
                    goods.goodsName,
                    style: TaskCardStyles.titleStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      text: goods.goodsDescription,
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
                            text: 'Количество: ',
                            style: TaskCardStyles.priorityStyle.copyWith(
                              color: Color(0xff1E2E52),
                            ),
                          ),
                          TextSpan(
                            text: '${goods.stockQuantity % 1 == 0 ? goods.stockQuantity.toInt() : goods.stockQuantity}',
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
                            text: 'Цена: ',
                            style: TaskCardStyles.priorityStyle.copyWith(
                              color: Color(0xff1E2E52),
                            ),
                          ),
                          TextSpan(
                            text: '${goods.goodsPrice % 1 == 0 ? goods.goodsPrice.toInt() : goods.goodsPrice}',
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
                child: Image.asset(
                  goods.imagePath, 
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    ),
  ),
);
}

void _navigateToGoodsDetails(Goods goods) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GoodsDetailsScreen(
        id: goods.id,
        goodsName: goods.goodsName,
        goodsDescription: goods.goodsDescription,
        goodsPrice: goods.goodsPrice,
        discountGoodsPrice: goods.discountGoodsPrice,
        stockQuantity: goods.stockQuantity,
        imagePath: goods.imagePath,
        selectedCategory: goods.id.toString(), 
        isActive: true, 
      ),
    ),
  );
}

  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TaskCardStyles.titleStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
           onPressed: () {
             Navigator.push(
               context,
               MaterialPageRoute(builder: (context) => ProductAddScreen()),
             );
           },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: Color(0xff1E2E52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.translate('add'),
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class DeleteGoodsDialog extends StatelessWidget {
  const DeleteGoodsDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Удалить сделку?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            // Логика удаления
            Navigator.pop(context);
          },
          child: Text('Удалить'),
        ),
      ],
    );
  }
}

// Заглушка для экрана добавления сделки
class CategoryGoodsAddScreen extends StatelessWidget {

  const CategoryGoodsAddScreen({Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить сделку'),
      ),
      body: Center(
        child: Text('Экран добавления сделки'),
      ),
    );
  }
}