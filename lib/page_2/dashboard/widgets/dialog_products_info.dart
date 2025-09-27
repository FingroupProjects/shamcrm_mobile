import 'package:flutter/material.dart';
import 'dart:convert';

import '../../../models/page_2/dashboard/dashboard_goods_report.dart';

void showSimpleInfoDialog(BuildContext context, List<DashboardGoods> items) {
  showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return InfoDialog(items: items);
      });
}

class InfoDialog extends StatelessWidget {
  final List<DashboardGoods> items;

  const InfoDialog({super.key, required this.items});

  Widget _buildProductsInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок информации
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xffEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xffBFDBFE),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.inventory_outlined,
                color: Color(0xff1D4ED8),
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Неликвидные товары',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1D4ED8),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Отображаем список товаров
        ...items.map((item) => _buildProductCard(item)).toList(),
      ],
    );
  }

  Widget _buildProductCard(DashboardGoods item) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xffE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xff1E2E52).withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок товара
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xffF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                left: BorderSide(
                  width: 4,
                  color: Color(0xff1D4ED8),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xff1D4ED8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.id}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1D4ED8),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${item.article} ${item.name}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Детали: первая строка (категория и дни)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // Категория
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xffF0F9FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xffBAE6FD),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Категория:',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff0369A1),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.category,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // Дней без движения
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xffF0F9FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xffBAE6FD),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Дней без движения:',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff0369A1),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.daysWithoutMovement,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Детали: вторая строка (количество и сумма)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Количество
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xffF0F9FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xffBAE6FD),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Количество:',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff0369A1),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.quantity,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // Сумма
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xffF0F9FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xffBAE6FD),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Сумма:',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff0369A1),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.sum,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 420,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0xff1E2E52).withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff1D4ED8), Color(0xff3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: _buildProductsInfo(),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff1D4ED8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Понятно',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}