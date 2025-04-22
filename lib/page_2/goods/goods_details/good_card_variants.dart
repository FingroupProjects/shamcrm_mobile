import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class GoodsCardView extends StatelessWidget {
  final List<Goods> goodsList;

  const GoodsCardView({required this.goodsList, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        itemCount: goodsList.length,
        itemBuilder: (context, index) {
          final goods = goodsList[index];
          return _buildGoodsCard(context, goods);
        },
      ),
    );
  }

  Widget _buildGoodsCard(BuildContext context, Goods goods) {
    // Получаем цену из первого активного варианта
    double price = 0;
    if (goods.variants != null && goods.variants!.isNotEmpty) {
      final activeVariant = goods.variants!.firstWhere(
        (variant) => variant.isActive == true,
        orElse: () => goods.variants!.first,
      );
      price = activeVariant.variantPrice?.price ?? 0.0;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GoodsDetailsScreen(id: goods.id),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение товара
              _buildGoodsImage(goods),
              const SizedBox(width: 12),
              // Информация о товаре
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goods.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Категория
                    Text(
                      goods.category.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Рейтинг (заглушка)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '4.5', // Заглушка, можно заменить на реальный рейтинг
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Цена и кнопка "Купить"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$price ₽',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Действие для кнопки "Купить"
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1E2E52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          child: const Text(
                            'Купить',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoodsImage(Goods goods) {
    const String baseUrl = 'https://shamcrm.com/storage/';
    String imageUrl = '';

    if (goods.files.isNotEmpty) {
      imageUrl = '$baseUrl/${goods.files.first.path}';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 80,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey),
      ),
    );
  }
}