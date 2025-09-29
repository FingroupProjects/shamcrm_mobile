import 'package:flutter/material.dart';

enum ErrorDialogEnum {
  goodsIncomingDelete,
  goodsIncomingUnapprove,
  goodsIncomingApprove,
  goodsIncomingRestore,
  nothing;
}

void showSimpleErrorDialog(BuildContext context, String title, String errorMessage, {ErrorDialogEnum errorDialogEnum = ErrorDialogEnum.nothing}) {
  showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return ErrorDialog(title: title, errorMessage: errorMessage, errorDialogEnum: errorDialogEnum);
      });
}

class ErrorDialog extends StatelessWidget {
  final String title;
  final String errorMessage;
  final ErrorDialogEnum errorDialogEnum;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.errorMessage,
    this.errorDialogEnum = ErrorDialogEnum.nothing
  });

  // Простой и эффективный метод для красивого отображения ошибки
  Widget _buildFormattedError(String message) {

    if (errorDialogEnum == ErrorDialogEnum.goodsIncomingDelete) {
      return _buildGoodsIncomingDeleteError(message);
    }
    if (errorDialogEnum == ErrorDialogEnum.goodsIncomingUnapprove) {
      debugPrint("[ERROR] ErrorDialog.Unapprove: $message");
      return _buildGoodsIncomingUnapproveError(message);
    }

    // Проверяем, есть ли в сообщении информация о товарах
    if (message.contains('товар') || message.contains('Товар')) {
      return _buildInventoryError(message);
    }

    // Для обычных ошибок просто красиво форматируем текст
    return _buildSimpleError(message);
  }

  Widget _buildInventoryError(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок ошибки
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xffFFF5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xffFECDD3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Color(0xffDC2626),
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Недостаточно товара на складе',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xffDC2626),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Парсим информацию о товаре
        ...(_parseInventoryDetails(message)),
      ],
    );
  }

  Widget _buildGoodsIncomingDeleteError(String message) {
    // Парсим название товара и отрицательный остаток
    RegExp deletionRegex = RegExp(r"товара '([^']+)' станет отрицательным: (-?\d+)");
    Match? match = deletionRegex.firstMatch(message);

    String productName = match?.group(1) ?? 'Неизвестный товар';
    String negativeAmount = match?.group(2) ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок ошибки
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xffFFF5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xffFECDD3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Невозможно удалить документ',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xffDC2626),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Информация о товаре
        Container(
          width: double.infinity,
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
                      color: Color(0xffDC2626),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xffDC2626).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Color(0xffDC2626),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        productName,
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

              // Предупреждение об отрицательном остатке
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'После удаления документа остаток станет:',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff64748B),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xffFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xffFECDD3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            negativeAmount,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xffDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoodsIncomingUnapproveError(String message) {
    // Парсим название товара и отрицательный остаток
    RegExp unapproveRegex = RegExp(r"товара '([^']+)' станет отрицательным: (-?\d+)");
    Match? match = unapproveRegex.firstMatch(message);

    String productName = match?.group(1) ?? 'Неизвестный товар';
    String negativeAmount = match?.group(2) ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок ошибки
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xffFFF5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xffFECDD3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Нельзя отменить проведение',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xffDC2626),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Информация о товаре
        Container(
          width: double.infinity,
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
                      color: Color(0xffDC2626),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xffDC2626).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Color(0xffDC2626),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        productName,
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

              // Предупреждение об отрицательном остатке
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'После отмены проведения остаток станет:',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff64748B),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xffFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xffFECDD3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            negativeAmount,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xffDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _parseInventoryDetails(String message) {
    List<Widget> widgets = [];

    // Парсим все товары с помощью регулярного выражения
    RegExp productRegex = RegExp(r'- Товар ([^:]+): требуется (\d+), доступно (\d+)');
    Iterable<Match> matches = productRegex.allMatches(message);

    if (matches.isEmpty) return widgets;

    // Добавляем заголовок с общим количеством товаров
    widgets.add(
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Color(0xffF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(0xffCBD5E1),
            width: 1,
          ),
        ),
        child: Text(
          'Найдено ${matches.length} товаров с недостаточными остатками',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xff475569),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    // Добавляем каждый товар
    for (int index = 0; index < matches.length; index++) {
      Match match = matches.elementAt(index);
      String productName = match.group(1)?.trim() ?? '';
      String required = match.group(2) ?? '0';
      String available = match.group(3) ?? '0';

      // Контейнер для товара
      widgets.add(
        Container(
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
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xff1E2E52).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        productName,
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

              // Количества
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Требуется
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xffFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xffFECDD3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Требуется:',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff991B1B),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatNumber(required),
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xffDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 12),

                    // Доступно
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
                              'Доступно:',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff0369A1),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatNumber(available),
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
        ),
      );
    }

    return widgets;
  }

  Widget _buildSimpleError(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xffFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xffFECDD3),
          width: 1,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 16,
          color: Color(0xff1F2937),
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatNumber(String number) {
    if (number.length > 6) {
      // Для очень больших чисел показываем в более читаемом формате
      try {
        double num = double.parse(number);
        if (num >= 1000000000) {
          return '${(num / 1000000000).toStringAsFixed(1)}B';
        } else if (num >= 1000000) {
          return '${(num / 1000000).toStringAsFixed(1)}M';
        } else if (num >= 1000) {
          return '${(num / 1000).toStringAsFixed(1)}K';
        }
      } catch (e) {
        // Если не удается распарсить, показываем как есть
      }
    }
    return number;
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
                  colors: [Color(0xff1E2E52), Color(0xff2C3E68)],
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
                      Icons.error_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: _buildFormattedError(errorMessage),
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
                    backgroundColor: Color(0xff1E2E52),
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