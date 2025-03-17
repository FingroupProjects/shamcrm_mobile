import 'package:flutter/material.dart';

class ProductSelectionSheet extends StatefulWidget {
  @override
  _ProductSelectionSheetState createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<ProductSelectionSheet> {
  // Пример списка товаров
  final List<Map<String, dynamic>> _products = [
    {
      'id': '8742220',
      'name': 'Соус Pesto con Basilico e Ru...',
      'imageUrl': 'assets/images/pesto.png',
      'price': 54.080,
      'isSelected': false,
      'quantity': 1, // Добавляем количество для каждого товара
    },
    {
      'id': '4312322',
      'name': 'Нутовая мука цельнозерно...',
      'imageUrl': 'assets/images/nut_flour.png',
      'price': 34.500,
      'isSelected': false,
      'quantity': 1,
    },
    {
      'id': '3422560',
      'name': 'Ржаная цельнозерновая му...',
      'imageUrl': 'assets/images/rye_flour.png',
      'price': 45.200,
      'isSelected': false,
      'quantity': 1,
    },
    {
      'id': '9992235',
      'name': 'Варенье из сосновых шише...',
      'imageUrl': 'assets/images/jam.png',
      'price': 67.890,
      'isSelected': false,
      'quantity': 1,
    },
    {
      'id': '9992235',
      'name': 'Вода минеральная "Нагер"...',
      'imageUrl': 'assets/images/water.png',
      'price': 23.450,
      'isSelected': false,
      'quantity': 1,
    },
    {
      'id': '9992235',
      'name': 'Холодный чай Ti Чёрный со...',
      'imageUrl': 'assets/images/tea.png',
      'price': 35.600,
      'isSelected': false,
      'quantity': 1,
    },
    {
      'id': '9992235',
      'name': 'Холодный чай Arizona Зеле...',
      'imageUrl': 'assets/images/arizona_tea.png',
      'price': 39.800,
      'isSelected': false,
      'quantity': 1,
    },
    {
      'id': '9992235',
      'name': 'Растительный напиток Вито...',
      'imageUrl': 'assets/images/drink.png',
      'price': 28.900,
      'isSelected': false,
      'quantity': 1,
    },
  ];

  List<Map<String, dynamic>> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedFilter = 'Новый';
  int _selectedStatusId = 1;

  final List<Map<String, dynamic>> _statuses = [
    {'id': 1, 'title': 'Новый'},
    {'id': 2, 'title': 'Ожидает оплаты'},
    {'id': 3, 'title': 'Оплачен'},
    {'id': 4, 'title': 'В обработке'},
    {'id': 5, 'title': 'Отправлен'},
    {'id': 6, 'title': 'Завершен'},
    {'id': 7, 'title': 'Отменен'},
  ];

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(_products);
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = List.from(_products);
      } else {
        _filteredProducts = _products
            .where((product) =>
                product['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filteredProducts = List.from(_products);
      if (_searchQuery.isNotEmpty) {
        _filteredProducts = _filteredProducts
            .where((product) => product['name']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
      }
    });
  }

  // Функция для добавления выбранных товаров
  void _addSelectedProducts() {
    final selectedProducts = _products
        .where((product) => product['isSelected'] == true)
        .map((product) => {
              'id': product['id'],
              'name': product['name'],
              'imageUrl': product['imageUrl'],
              'price': product['price'],
              'quantity': product['quantity'],
            })
        .toList();

    if (selectedProducts.isNotEmpty) {
      Navigator.pop(context, selectedProducts);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Выберите хотя бы один товар',
            style: TextStyle(fontFamily: 'Gilroy', color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Заголовок и кнопка закрытия
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Добавление товара',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Color(0xff1E2E52), size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Поле поиска
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Поиск по названию, артикулу, штри...',
                hintStyle: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: Color(0xff99A4BA),
                ),
                prefixIcon: Icon(Icons.search, color: Color(0xff99A4BA)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xffE0E7FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xff4759FF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xffE0E7FF)),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          // Статусы вместо фильтров
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((status) {
                  return Row(
                    children: [
                      _buildFilterChip(status['title']),
                      SizedBox(width: 8),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 12),
          // Список товаров
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        product['isSelected'] = !product['isSelected'];
                        if (!product['isSelected']) {
                          product['quantity'] = 1; // Сбрасываем количество
                        }
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Color(0xffF4F7FD),
                            ),
                            child: Image.asset(
                              'assets/images/goods_photo.jpg',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff1E2E52),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  product['id'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff99A4BA),
                                  ),
                                ),
                                if (product['isSelected']) ...[
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Количество',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Gilroy',
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xff99A4BA),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.remove, size: 20),
                                            color: Color(0xff1E2E52),
                                            onPressed: () {
                                              if (product['quantity'] > 1) {
                                                setState(() {
                                                  product['quantity']--;
                                                });
                                              }
                                            },
                                          ),
                                          Text(
                                            '${product['quantity']}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'Gilroy',
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xff1E2E52),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.add, size: 20),
                                            color: Color(0xff1E2E52),
                                            onPressed: () {
                                              setState(() {
                                                product['quantity']++;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: product['isSelected']
                                    ? Color(0xff4CAF50)
                                    : Color(0xff99A4BA),
                                width: 2,
                              ),
                            ),
                            child: product['isSelected']
                                ? Icon(
                                    Icons.check,
                                    color: Color(0xff4CAF50),
                                    size: 16,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Кнопка "Добавить"
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton(
              onPressed: _addSelectedProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff4759FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Center(
                child: Text(
                  'Добавить',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _applyFilter(label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xff4759FF) : Color(0xffF4F7FD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Color(0xff1E2E52),
          ),
        ),
      ),
    );
  }
}