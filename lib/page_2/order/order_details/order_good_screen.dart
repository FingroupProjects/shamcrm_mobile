import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/page_2/goods/goods_add_screen.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/goods_details_by_order_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/goods_selection_sheet.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart'; // Импортируем модель Order

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
  String? baseUrl; // Переменная для базового URL
  final ApiService _apiService = ApiService(); // Экземпляр ApiService
  @override
  void initState() {
    _initializeBaseUrl(); // Инициализируем базовый URL
    super.initState();
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final enteredDomainMap = await _apiService.getEnteredDomain();
      String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
      String? enteredDomain = enteredDomainMap['enteredDomain'];

      setState(() {
        baseUrl = 'https://$enteredDomain-back.$enteredMainDomain/storage';
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage/'; // Резервный URL
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildGoodsList(widget.goods);
  }

  Widget _buildGoodsList(List<Good> goods) {
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

  Widget _buildGoodsItem(Good good) {
    return GestureDetector(
      onTap: () {
        _navigateToGoodsDetails(good);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: TaskCardStyles.taskCardDecoration,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        good.good.name,
                        style: TaskCardStyles.titleStyle,
                        overflow: TextOverflow.ellipsis,
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
                              text: '${good.quantity}',
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
                  child: good.good.files.isNotEmpty && baseUrl != null
                      ? Image.network(
                          '$baseUrl/${good.good.files[0].path}', // Динамический URL
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(); // Заглушка при ошибке
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildPlaceholderImage(); // Заглушка при загрузке
                          },
                        )
                      : _buildPlaceholderImage(), // Заглушка, если нет файлов или baseUrl
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Добавим метод для заглушки изображения
  Widget _buildPlaceholderImage() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey, size: 40),
      ),
    );
  }

  void _navigateToGoodsDetails(Good good) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoodsDetailsByOrderScreen(
          id: good.good.id, // Используем ID из GoodItem
          goodsName: good.good.name, // Используем имя из GoodItem
          goodsDescription:
              good.good.description, // Используем описание из GoodItem
          discountGoodsPrice: 0,
          stockQuantity: good.quantity,
          imagePaths: ['assets/images/goods_photo.jpg'],
          selectedCategory: '',
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
            showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) =>
                    ProductSelectionSheet(order: widget.order));
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
            Navigator.pop(context);
          },
          child: Text('Удалить'),
        ),
      ],
    );
  }
}

class CategoryGoodsAddScreen extends StatelessWidget {
  const CategoryGoodsAddScreen({
    Key? key,
  }) : super(key: key);

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
