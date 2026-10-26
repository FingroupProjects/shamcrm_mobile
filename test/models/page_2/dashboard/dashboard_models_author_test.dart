import 'package:crm_task_manager/models/page_2/dashboard/cash_balance_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/creditors_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/dashboard_goods_report.dart';
import 'package:crm_task_manager/models/page_2/dashboard/debtors_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/expense_structure_content.dart';
import 'package:crm_task_manager/models/page_2/dashboard/goods_expiration_report.dart';
import 'package:crm_task_manager/models/page_2/dashboard/net_profit_content_model.dart' as np;
import 'package:crm_task_manager/models/page_2/dashboard/order_quantity_content.dart';
import 'package:crm_task_manager/models/page_2/dashboard/profitability_content_model.dart' as pr;
import 'package:crm_task_manager/models/page_2/dashboard/salary_report_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/sales_model.dart' as sd;
import 'package:crm_task_manager/models/page_2/dashboard/top_selling_card_model.dart';
import 'package:crm_task_manager/models/page_2/good_variants_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reports author parsing', () {
    test('DashboardGoods parses author as string and map', () {
      final item1 = DashboardGoods.fromJson({
        'id': 1,
        'name': 'Item',
        'category': 'Cat',
        'total_quantity': '10',
        'price': '100',
        'total_sum': '1000',
        'storages': [],
        'author': 'Иван Иванов',
      });
      expect(item1.author, 'Иван Иванов');

      final item2 = DashboardGoods.fromJson({
        'id': 2,
        'name': 'Item 2',
        'category': 'Cat',
        'total_quantity': '10',
        'price': '100',
        'total_sum': '1000',
        'storages': [],
        'author': {'name': 'Петр Петров'},
      });
      expect(item2.author, 'Петр Петров');
    });

    test('GoodVariantItem parses author', () {
      final item = GoodVariantItem.fromJson({
        'id': 1,
        'full_name': 'Variant A',
        'author': 'Сергей',
      });
      expect(item.author, 'Сергей');
    });

    test('CashRegisters parses author', () {
      final reg = CashRegisters.fromJson({
        'id': 1,
        'name': 'Касса 1',
        'balance': 5000,
        'author_name': 'Кассир Анна',
      });
      expect(reg.author, 'Кассир Анна');
    });

    test('Creditor and Debtor parse author', () {
      final creditor = Creditor.fromJson({
        'id': 1,
        'name': 'Поставщик',
        'debt_amount': 2500,
        'author': {'full_name': 'Менеджер Олег'},
      });
      expect(creditor.author, 'Менеджер Олег');

      final debtor = Debtor.fromJson({
        'id': 2,
        'name': 'Клиент',
        'debt_amount': 1500,
        'user': {'name': 'Менеджер Мария'},
      });
      expect(debtor.author, 'Менеджер Мария');
    });

    test('TopSellingCardModel parses author', () {
      final top = TopSellingCardModel.fromJson({
        'id': 1,
        'name': 'Футболка',
        'category': 'Одежда',
        'total_quantity': 50,
        'total_amount': '5000',
        'avg_price': '100',
        'author': 'Алиса',
      });
      expect(top.author, 'Алиса');
    });

    test('Sales dynamics, net profit, profitability parse author', () {
      final sdMonth = sd.MonthData.fromJson({
        'month': 1,
        'month_name': 'Январь',
        'sales_count': 10,
        'total_quantity': 20,
        'total_amount': '15000',
        'author': 'Аналитик',
      });
      expect(sdMonth.author, 'Аналитик');

      final npMonth = np.MonthData.fromJson({
        'month': 2,
        'month_name': 'Февраль',
        'net_profit': '35000',
        'author': 'Бухгалтер',
      });
      expect(npMonth.author, 'Бухгалтер');

      final prMonth = pr.MonthData.fromJson({
        'month': 3,
        'month_name': 'Март',
        'profitability_percentage': 25.5,
        'author': 'Директор',
      });
      expect(prMonth.author, 'Директор');
    });

    test('ExpenseItem, SalaryEmployeeReport, OrderQuantity, Expiration parse author', () {
      final expense = ExpenseItem.fromJson({
        'article_name': 'Аренда',
        'article_type': 'Постоянные',
        'sum': 50000,
        'formatted_sum': '50 000',
        'percentage': 20,
        'author': 'Офис-менеджер',
      });
      expect(expense.author, 'Офис-менеджер');

      final salary = SalaryEmployeeReport.fromJson({
        'employee_id': 1,
        'employee_name': 'Дмитрий',
        'months': [],
        'author': 'HR',
      });
      expect(salary.author, 'HR');

      final order = ChartDataContent.fromJson({
        'id': 1,
        'name': 'В обработке',
        'amount': 15,
        'author': 'Оператор',
      });
      expect(order.author, 'Оператор');

      final expiration = GoodsExpirationItem.fromJson({
        'id': 1,
        'name': 'Молоко',
        'category': 'Продукты',
        'storage': 'Склад 1',
        'expiration_date': '2026-12-01',
        'days_left': 10,
        'quantity': 5,
        'unit': 'шт',
        'author': 'Кладовщик',
      });
      expect(expiration.author, 'Кладовщик');
    });
  });
}

