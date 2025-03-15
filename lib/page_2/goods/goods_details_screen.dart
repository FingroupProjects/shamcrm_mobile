import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class GoodsDetailsScreen extends StatefulWidget {
  final int id;
  final String goodsName;
  final String goodsDescription;
  final double goodsPrice;
  final double discountGoodsPrice;
  final double stockQuantity;
  final String imagePath;
  String? selectedCategory;
  bool isActive = false;

  GoodsDetailsScreen({
    required this.id,
    required this.goodsName,
    required this.goodsDescription,
    required this.goodsPrice,
    required this.discountGoodsPrice,
    required this.stockQuantity,
    required this.imagePath,
    this.selectedCategory,
    this.isActive = false,
  });

  @override
  _GoodsDetailsScreenState createState() => _GoodsDetailsScreenState();
}

class _GoodsDetailsScreenState extends State<GoodsDetailsScreen> {
  List<Map<String, String>> details = [];


  @override
  void initState() {
    super.initState();
    _updateDetails();
  }

  void _updateDetails() {
    details = [
      {'label': 'Название:', 'value': widget.goodsName},
      {'label': 'Описание:', 'value': widget.goodsDescription},
      {'label': 'Цена:', 'value': widget.goodsPrice.toString()},
      {'label': 'Скидка:', 'value': widget.discountGoodsPrice.toString()},
      {'label': 'Количество:', 'value': widget.stockQuantity.toString()},
      {'label': 'Категория:', 'value': widget.selectedCategory.toString()},
      {'label': 'Статус:', 'value': widget.isActive ? 'Активно' : 'Неактивно'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(
          context,
          AppLocalizations.of(context)!.translate('Просмотр товара'),
        ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            children: [
              _buildDetailsList(),
            ],
          ),
        ));
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Transform.translate(
          offset: const Offset(0, -2),
          child: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () async {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              icon: Image.asset(
                'assets/icons/edit.png',
                width: 24,
                height: 24,
              ),
              onPressed: () async {
                // CategoryEditBottomSheet.show(
                //   context,
                //   initialName: widget.categoryName,
                //   initialDescription: widget.categoryDescription,
                // );
              },
            ),
            IconButton(
              padding: EdgeInsets.only(right: 8),
              constraints: BoxConstraints(),
              icon: Image.asset(
                'assets/icons/delete.png',
                width: 24,
                height: 24,
              ),
              onPressed: () {
                // showDialog(
                //   context: context,
                //   builder: (context) => DeleteCategoryDialog(),
                // );           
              },
            ),
          ],
        ),
      ],
    );
  }

Widget _buildDetailsList() {
  return ListView(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    children: [
      // Отображение изображения товара
      Container(
        margin: const EdgeInsets.only(bottom: 16), // Отступ снизу
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), // Закругление углов
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // Закругление углов
          child: Image.asset(
            widget.imagePath, // Путь к изображению
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      ),
      // Остальные детали
      ...details.map((detail) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildDetailItem(
            detail['label']!,
            detail['value']!,
          ),
        );
      }).toList(),
    ],
  );
}

  Widget _buildDetailItem(String label, String value) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            SizedBox(width: 8),
            Expanded(
              child: _buildValue(value, label),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xfff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value, String label) {
    if (value.isEmpty) return Container();

    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xFF1E2E52),
      ),
      overflow: TextOverflow.visible,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
