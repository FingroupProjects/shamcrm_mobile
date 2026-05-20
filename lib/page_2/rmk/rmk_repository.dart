import 'dart:async';
import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class RmkRepository {
  RmkRepository({
    AppDatabase? database,
    ApiService? apiService,
  })  : _db = database ?? AppDatabase(),
        _apiService = apiService ?? ApiService();

  final AppDatabase _db;
  final ApiService _apiService;

  static const int _syncPageSize = 20;
  bool _isSyncing = false;

  Stream<List<RmkGood>> watchGoods({
    String query = '',
    int? categoryId,
  }) {
    final normalizedQuery = _normalize(query);
    final statement = _db.select(_db.rmkGoods)
      ..where((tbl) => tbl.isDeleted.equals(false));

    if (normalizedQuery.isNotEmpty) {
      statement.where(
        (tbl) => tbl.normalizedName.like('%$normalizedQuery%'),
      );
    }

    if (categoryId != null) {
      statement.where((tbl) => tbl.categoryId.equals(categoryId));
    }

    statement.orderBy([
      (tbl) => OrderingTerm.desc(tbl.serverCreatedAt),
      (tbl) => OrderingTerm.desc(tbl.id),
    ]);

    return statement.watch();
  }

  Stream<List<RmkCategory>> watchCategories() {
    final statement = _db.select(_db.rmkCategories)
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.level),
        (tbl) => OrderingTerm.asc(tbl.name),
      ]);
    return statement.watch();
  }

  Stream<List<RmkCartItem>> watchCart() {
    final statement = _db.select(_db.rmkCartItems)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]);
    return statement.watch();
  }

  Future<RmkCartItem?> getCartItem(int goodId) {
    return (_db.select(_db.rmkCartItems)
          ..where((tbl) => tbl.goodId.equals(goodId)))
        .getSingleOrNull();
  }

  Future<void> upsertCartItem({
    required RmkGood good,
    required double quantity,
    required double price,
    double? customTotal,
  }) async {
    if (quantity <= 0) {
      await removeCartItem(good.id);
      return;
    }

    await _db.into(_db.rmkCartItems).insertOnConflictUpdate(
          RmkCartItemsCompanion.insert(
            goodId: Value(good.id),
            name: good.name,
            quantity: Value(quantity),
            price: Value(price),
            customTotal: Value(customTotal),
            imageUrl: Value(good.imageUrl),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<void> removeCartItem(int goodId) {
    return (_db.delete(_db.rmkCartItems)
          ..where((tbl) => tbl.goodId.equals(goodId)))
        .go();
  }

  Future<void> clearCart() => _db.delete(_db.rmkCartItems).go();

  Future<RmkSaleSubmitResult> submitSale(List<RmkCartItem> items) async {
    if (items.isEmpty) {
      return const RmkSaleSubmitResult(sentToServer: false, savedLocal: false);
    }

    final now = DateTime.now();
    final saleId = const Uuid().v4();
    final idempotencyKey = const Uuid().v4();
    final payload = _buildSalePayload(
      saleId: saleId,
      idempotencyKey: idempotencyKey,
      createdAt: now,
      items: items,
    );

    await _db.into(_db.rmkOutboxSales).insert(
          RmkOutboxSalesCompanion.insert(
            id: saleId,
            payload: jsonEncode(payload),
            idempotencyKey: idempotencyKey,
            status: 'sending',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await clearCart();

    try {
      await _apiService.createRmkSale(payload: payload);
      await _markSaleSynced(saleId);
      return const RmkSaleSubmitResult(sentToServer: true, savedLocal: true);
    } catch (error) {
      await _markSalePending(saleId, error.toString());
      return RmkSaleSubmitResult(
        sentToServer: false,
        savedLocal: true,
        error: error.toString(),
      );
    }
  }

  Future<void> createLocalSale(List<RmkCartItem> items) async {
    await submitSale(items);
  }

  Future<void> syncInBackground() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await _flushPendingSales();
      await _syncCategories();
      await _syncGoods();
    } catch (error, stackTrace) {
      debugPrint('RMK sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _flushPendingSales() async {
    final sales = await (_db.select(_db.rmkOutboxSales)
          ..where((tbl) => tbl.status.equals('pending'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();

    for (final sale in sales) {
      try {
        await (_db.update(_db.rmkOutboxSales)
              ..where((tbl) => tbl.id.equals(sale.id)))
            .write(
          RmkOutboxSalesCompanion(
            status: const Value('sending'),
            attemptCount: Value(sale.attemptCount + 1),
            updatedAt: Value(DateTime.now()),
          ),
        );

        final decoded = jsonDecode(sale.payload);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid RMK sale payload');
        }
        await _apiService.createRmkSale(payload: decoded);
        await _markSaleSynced(sale.id);
      } catch (error) {
        await _markSalePending(sale.id, error.toString());
      }
    }
  }

  Future<void> _markSaleSynced(String saleId) {
    return (_db.update(_db.rmkOutboxSales)
          ..where((tbl) => tbl.id.equals(saleId)))
        .write(
      RmkOutboxSalesCompanion(
        status: const Value('synced'),
        lastError: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _markSalePending(String saleId, String error) {
    return (_db.update(_db.rmkOutboxSales)
          ..where((tbl) => tbl.id.equals(saleId)))
        .write(
      RmkOutboxSalesCompanion(
        status: const Value('pending'),
        lastError: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Map<String, dynamic> _buildSalePayload({
    required String saleId,
    required String idempotencyKey,
    required DateTime createdAt,
    required List<RmkCartItem> items,
  }) {
    final saleItems = items.map((item) {
      final total = item.customTotal ?? item.quantity * item.price;
      return {
        'good_id': item.goodId,
        'quantity': item.quantity,
        'price': item.price,
        'total': total,
      };
    }).toList();

    final total = items.fold<double>(
      0,
      (sum, item) => sum + (item.customTotal ?? item.quantity * item.price),
    );

    return {
      'local_id': saleId,
      'idempotency_key': idempotencyKey,
      'source': 'mobile_rmk',
      'sold_at': createdAt.toIso8601String(),
      'currency': 'TJS',
      'total': total,
      'approve': true,
      'items': saleItems,
    };
  }

  Future<void> _syncCategories() async {
    final categories = await _apiService.getCategory();
    final now = DateTime.now();

    await _db.batch((batch) {
      for (final category in categories) {
        _writeCategory(batch, category, null, 0, now);
      }
    });
  }

  void _writeCategory(
    Batch batch,
    CategoryData category,
    int? parentId,
    int level,
    DateTime now,
  ) {
    batch.insert(
      _db.rmkCategories,
      RmkCategoriesCompanion.insert(
        id: Value(category.id),
        parentId: Value(parentId),
        name: category.name,
        normalizedName: _normalize(category.name),
        level: Value(level),
        localUpdatedAt: now,
      ),
      mode: InsertMode.insertOrReplace,
    );

    for (final child in category.subcategories) {
      _writeSubCategory(batch, child, category.id, level + 1, now);
    }
  }

  void _writeSubCategory(
    Batch batch,
    SubCategoryResponse category,
    int? parentId,
    int level,
    DateTime now,
  ) {
    batch.insert(
      _db.rmkCategories,
      RmkCategoriesCompanion.insert(
        id: Value(category.id),
        parentId: Value(parentId),
        name: category.name,
        normalizedName: _normalize(category.name),
        level: Value(level),
        localUpdatedAt: now,
      ),
      mode: InsertMode.insertOrReplace,
    );

    for (final child in category.subcategories) {
      _writeSubCategory(batch, child, category.id, level + 1, now);
    }
  }

  Future<void> _syncGoods() async {
    var page = 1;
    const maxPagesPerSync = 300;

    while (true) {
      final goods = await _apiService.getGoods(
        page: page,
        perPage: _syncPageSize,
      );
      if (goods.isEmpty) break;

      await _saveGoods(goods);

      if (goods.length < _syncPageSize) break;
      page += 1;
      if (page > maxPagesPerSync) break;
    }
  }

  Future<void> _saveGoods(List<Goods> goods) async {
    final now = DateTime.now();
    await _db.batch((batch) {
      for (final good in goods) {
        batch.insert(
          _db.rmkGoods,
          RmkGoodsCompanion.insert(
            id: Value(good.id),
            name: good.name,
            normalizedName: _normalize('${good.name} ${good.article ?? ''}'),
            categoryId: Value(good.category.id == 0 ? null : good.category.id),
            categoryName: Value(good.category.name),
            price: Value(_extractPrice(good)),
            quantity: Value((good.quantity ?? 0).toDouble()),
            imageUrl: Value(good.mainImageUrl),
            payload: _goodsPayload(good),
            serverCreatedAt: Value(null),
            serverUpdatedAt: Value(null),
            localUpdatedAt: now,
            isDeleted: const Value(false),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  double _extractPrice(Goods good) {
    if (good.discountedPrice != null) return good.discountedPrice!;
    if (good.discountPrice != null) return good.discountPrice!;
    if (good.price != null) return double.tryParse(good.price!) ?? 0;
    return 0;
  }

  String _goodsPayload(Goods good) {
    return jsonEncode({
      'id': good.id,
      'name': good.name,
      'article': good.article,
      'category_id': good.category.id,
      'category_name': good.category.name,
      'quantity': good.quantity,
      'price': good.price,
      'image_url': good.mainImageUrl,
    });
  }

  static String _normalize(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class RmkSaleSubmitResult {
  const RmkSaleSubmitResult({
    required this.sentToServer,
    required this.savedLocal,
    this.error,
  });

  final bool sentToServer;
  final bool savedLocal;
  final String? error;
}
