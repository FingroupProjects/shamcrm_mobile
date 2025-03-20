import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/page_2/goods/goods_add_screen.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class Goods {
  final int id;
  final String goodsName;
  final String goodsDescription;
  final double goodsPrice;
  final discountGoodsPrice;
  final stockQuantity;
  final List<String> imagePaths;

  Goods({
    required this.id,
    required this.goodsName,
    required this.goodsDescription,
    required this.goodsPrice,
    required this.discountGoodsPrice,
    required this.stockQuantity,
    required this.imagePaths,
  });
}
class CategoryGoodsScreen extends StatefulWidget {
  final categoryName;

  const CategoryGoodsScreen({Key? key, required this.categoryName }) : super(key: key);

  @override
  _CategoryGoodsState createState() => _CategoryGoodsState();
}

class _CategoryGoodsState extends State<CategoryGoodsScreen> {
final List<Goods> testGoods = [
  Goods(
    id: 1,
    goodsName: 'Смартфон Galaxy S22',
    goodsDescription: 'Флагманский смартфон с мощным процессором, AMOLED-экраном 6.5" и камерой 108 МП.',
    goodsPrice: 899.99,
    discountGoodsPrice: 799,
    stockQuantity: 350,
    imagePaths: ['assets/images/goods_photo2.jpg', 'assets/images/goods_photo1.jpg'],
  ),
  Goods(
    id: 2,
    goodsName: 'Ноутбук UltraBook X1',
    goodsDescription: 'Легкий и мощный ноутбук с процессором i7, 16 ГБ ОЗУ и SSD 512 ГБ. Отличный выбор для работы и развлечений.',
    goodsPrice: 1200.00,
    discountGoodsPrice: 1099,
    stockQuantity: 150,
    imagePaths: ['assets/images/goods_photo.jpg', 'assets/images/goods_photo1.jpg'],
  ),
  Goods(
    id: 3,
    goodsName: 'Игровая консоль NextGen X',
    goodsDescription: 'Новая консоль с поддержкой 4K-гейминга, мощной графикой и библиотекой эксклюзивных игр.',
    goodsPrice: 499.99,
    discountGoodsPrice: 459,
    stockQuantity: 500,
    imagePaths: ['assets/images/goods_photo2.jpg', 'assets/images/goods_photo.jpg'],
  ),
  Goods(
    id: 4,
    goodsName: 'Умные часы FitPro 3',
    goodsDescription: 'Следите за своим здоровьем и активностью с FitPro 3! Мониторинг сна, шагомер, датчик ЧСС и водонепроницаемость.',
    goodsPrice: 199.99,
    discountGoodsPrice: 179,
    stockQuantity: 800,
    imagePaths: ['assets/images/goods_photo1.jpg', 'assets/images/goods_photo2.jpg'],
  ),
  Goods(
    id: 5,
    goodsName: 'Беспроводные наушники SoundBeat Pro',
    goodsDescription: 'Высокое качество звука, активное шумоподавление и до 30 часов работы на одном заряде.',
    goodsPrice: 249.99,
    discountGoodsPrice: 219,
    stockQuantity: 1000,
    imagePaths: ['assets/images/goods_photo.jpg', 'assets/images/goods_photo2.jpg'],
  ),
  Goods(
    id: 6,
    goodsName: 'Электросамокат SpeedRide X',
    goodsDescription: 'Складной электросамокат с запасом хода до 40 км, максимальной скоростью 25 км/ч и мощным аккумулятором.',
    goodsPrice: 650.00,
    discountGoodsPrice: 599,
    stockQuantity: 200,
    imagePaths: ['assets/images/goods_photo2.jpg', 'assets/images/goods_photo.jpg'],
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
        _buildTitleRow(AppLocalizations.of(context)!.translate('goods')),
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
            height: MediaQuery.of(context).size.height * 0.65,
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
                            text: AppLocalizations.of(context)!.translate('counts'),
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
                            text: AppLocalizations.of(context)!.translate('price'),
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
              Container(
                width: 100,
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: goods.imagePaths.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          goods.imagePaths[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
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
        imagePaths: goods.imagePaths,
        selectedCategory: widget.categoryName, 
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
               MaterialPageRoute(builder: (context) => GoodsAddScreen()),
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
      title: Text(AppLocalizations.of(context)!.translate('delete_category')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.translate('cancel')),
        ),
        TextButton(
          onPressed: () {
            // Логика удаления
            Navigator.pop(context);
          },
          child: Text(AppLocalizations.of(context)!.translate('delete')),
        ),
      ],
    );
  }
}
