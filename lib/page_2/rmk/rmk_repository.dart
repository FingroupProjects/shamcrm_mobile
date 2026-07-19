import 'dart:async';
import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
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

  static const int _syncPageSize = 15;
  static const String _syncModule = 'rmk';
  static const String _goodsFullSyncScope = 'goods_full_sync';
  static const String _syncCompleteVersion = 'complete_v1';
  Future<void>? _syncChain;

  Stream<List<RmkGood>> watchGoods({
    String query = '',
    Set<int>? categoryIds,
  }) {
    final normalizedQuery = _normalize(query);
    final statement = _db.select(_db.rmkGoods)
      ..where((tbl) => tbl.isDeleted.equals(false));

    if (normalizedQuery.isNotEmpty) {
      statement.where(
        (tbl) => tbl.normalizedName.like('%$normalizedQuery%'),
      );
    }

    if (categoryIds != null && categoryIds.isNotEmpty) {
      statement.where((tbl) => tbl.categoryId.isIn(categoryIds.toList()));
    }

    statement.orderBy([
      (tbl) => OrderingTerm.desc(tbl.serverCreatedAt),
      (tbl) => OrderingTerm.asc(tbl.id),
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
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.updatedAt)]);
    return statement.watch();
  }

  Future<RmkCartItem?> getCartItem(int goodId) {
    return (_db.select(_db.rmkCartItems)
          ..where((tbl) => tbl.goodId.equals(goodId)))
        .getSingleOrNull();
  }

  Future<RmkGood?> getGoodById(int goodId) {
    return (_db.select(_db.rmkGoods)..where((tbl) => tbl.id.equals(goodId)))
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

    final existingItem = await getCartItem(good.id);
    await _db.into(_db.rmkCartItems).insertOnConflictUpdate(
          RmkCartItemsCompanion.insert(
            goodId: Value(good.id),
            name: good.name,
            quantity: Value(quantity),
            price: Value(price),
            customTotal: Value(customTotal),
            imageUrl: Value(good.imageUrl),
            // Preserve first-add order for the selected-items list.
            updatedAt: existingItem?.updatedAt ?? DateTime.now(),
          ),
        );
  }

  Future<void> removeCartItem(int goodId) {
    return (_db.delete(_db.rmkCartItems)
          ..where((tbl) => tbl.goodId.equals(goodId)))
        .go();
  }

  Future<void> clearCart() => _db.delete(_db.rmkCartItems).go();

  Future<RmkSaleSubmitResult> submitSale(
    List<RmkCartItem> items, {
    required int storageId,
    required String paymentMode,
    required String? paymentMethod,
    required double paidAmount,
    required double debtAmount,
    int? cashRegisterId,
    int? leadId,
    int? currencyId,
    double? exchangeRate,
  }) async {
    if (items.isEmpty) {
      return const RmkSaleSubmitResult(sentToServer: false, savedLocal: false);
    }

    final now = DateTime.now();
    final saleId = const Uuid().v4();
    final idempotencyKey = const Uuid().v4();
    final payload = await _buildSalePayload(
      createdAt: now,
      items: items,
      storageId: storageId,
      paymentMode: paymentMode,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      debtAmount: debtAmount,
      cashRegisterId: cashRegisterId,
      leadId: leadId,
      currencyId: currencyId,
      exchangeRate: exchangeRate,
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

    try {
      await _apiService.createRmkSale(payload: payload);
      await _markSaleSynced(saleId);
      await _deductSoldGoodsFromCache(items);
      await clearCart();
      unawaited(_refreshSoldGoodsFromServer(items, storageId: storageId));
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

  Future<void> createLocalSale(
    List<RmkCartItem> items, {
    required int storageId,
  }) async {
    final total = items.fold<double>(
      0,
      (sum, item) => sum + (item.customTotal ?? item.quantity * item.price),
    );
    await submitSale(
      items,
      storageId: storageId,
      paymentMode: 'payment',
      paymentMethod: 'cash',
      paidAmount: total,
      debtAmount: 0,
    );
  }

  Future<List<WareHouse>> getStorages() {
    return _apiService.getStorage();
  }

  Future<void> _deductSoldGoodsFromCache(List<RmkCartItem> items) async {
    if (items.isEmpty) return;

    final now = DateTime.now();
    await _db.transaction(() async {
      for (final item in items) {
        final good = await (_db.select(_db.rmkGoods)
              ..where((tbl) => tbl.id.equals(item.goodId)))
            .getSingleOrNull();
        if (good == null) continue;

        final newQuantity = (good.quantity - item.quantity)
            .clamp(0, double.infinity)
            .toDouble();
        await (_db.update(_db.rmkGoods)
              ..where((tbl) => tbl.id.equals(item.goodId)))
            .write(
          RmkGoodsCompanion(
            quantity: Value(newQuantity),
            payload:
                Value(_goodsPayloadWithQuantity(good.payload, newQuantity)),
            localUpdatedAt: Value(now),
          ),
        );
      }
    });
  }

  Future<void> _refreshSoldGoodsFromServer(
    List<RmkCartItem> items, {
    required int storageId,
  }) async {
    final ids = items.map((item) => item.goodId).toSet();
    for (final id in ids) {
      try {
        await refreshGoodForStorage(variantId: id, storageId: storageId);
      } catch (_) {
        // Local deduction is already applied; the next catalog sync will fix it.
      }
    }
  }

  Future<RmkGood?> refreshGoodForStorage({
    required int variantId,
    required int storageId,
  }) async {
    var page = 1;
    while (true) {
      final response = await _apiService.getVariants(
        page: page,
        perPage: _syncPageSize,
        filters: {'storage_id': storageId},
      );
      final variants = response.data;
      if (variants.isEmpty) return null;

      final variant =
          variants.where((item) => item.id == variantId).firstOrNull;
      if (variant != null) {
        await _saveGoods([variant], page: page);
        return (_db.select(_db.rmkGoods)
              ..where((tbl) => tbl.id.equals(variantId)))
            .getSingleOrNull();
      }

      if (page >= response.pagination.totalPages ||
          variants.length < _syncPageSize) {
        return null;
      }
      page += 1;
    }
  }

  Future<RmkGood?> findGoodByBarcode(
    String barcode, {
    required int storageId,
  }) async {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty) return null;

    final cachedGoods = await (_db.select(_db.rmkGoods)
          ..where((tbl) => tbl.isDeleted.equals(false)))
        .get();
    for (final good in cachedGoods) {
      try {
        final payload = jsonDecode(good.payload);
        if (payload is Map<String, dynamic> &&
            payload['barcode']?.toString() == normalizedBarcode) {
          return good;
        }
      } catch (_) {
        // Ignore malformed legacy payloads.
      }
    }

    final response = await _apiService.getVariants(
      page: 1,
      perPage: _syncPageSize,
      search: normalizedBarcode,
      filters: {'storage_id': storageId},
    );
    final variants = response.data;
    if (variants.isEmpty) return null;

    final exactMatch = variants
        .where((variant) => variant.barcode == normalizedBarcode)
        .firstOrNull;
    final match = exactMatch ?? variants.firstOrNull;

    if (match != null) {
      await _saveGoods([match], page: 1);
      return (_db.select(_db.rmkGoods)
            ..where((tbl) => tbl.id.equals(match.id)))
          .getSingleOrNull();
    }

    return null;
  }

  Future<bool> searchAndCacheGoods(String query, int storageId) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return false;

    try {
      final response = await _apiService.getVariants(
        page: 1,
        perPage: _syncPageSize,
        search: normalizedQuery,
        filters: {'storage_id': storageId},
      );
      final variants = response.data;
      if (variants.isNotEmpty) {
        await _saveGoods(variants, page: 1);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncInBackground({
    required int storageId,
    bool resetCatalogCache = false,
  }) {
    _syncChain = (_syncChain ?? Future<void>.value()).then(
      (_) => _executeSync(
        storageId: storageId,
        resetCatalogCache: resetCatalogCache,
      ),
    );
    return _syncChain!;
  }

  Future<void> _executeSync({
    required int storageId,
    bool resetCatalogCache = false,
  }) async {
    try {
      await _syncCategories(resetCache: resetCatalogCache);
      await _syncGoods(
        storageId: storageId,
        resetCache: resetCatalogCache,
      );
    } catch (error, stackTrace) {
      debugPrint('RMK sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _resetGoodsCache() async {
    await _db.delete(_db.rmkGoods).go();
    await (_db.delete(_db.syncStates)
          ..where((tbl) => tbl.module.equals(_syncModule)))
        .go();
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

  Future<Map<String, dynamic>> _buildSalePayload({
    required DateTime createdAt,
    required List<RmkCartItem> items,
    required int storageId,
    required String paymentMode,
    required String? paymentMethod,
    required double paidAmount,
    required double debtAmount,
    int? cashRegisterId,
    int? leadId,
    int? currencyId,
    double? exchangeRate,
  }) async {
    final saleItems = await Future.wait(items.map((item) async {
      final total = item.customTotal ?? item.quantity * item.price;
      return {
        'good_id': item.goodId,
        'quantity': _compactNumber(item.quantity),
        'price': item.price,
        'unit_id': await _requiredUnitIdForCartItem(item),
        'sum': total,
      };
    }));

    final organizationId = await _selectedInt(
      _apiService.getSelectedOrganization,
      fallback: 1,
    );
    final salesFunnelId = await _selectedInt(
      _apiService.getSelectedSalesFunnel,
      fallback: 1,
    );

    final payload = {
      'date': createdAt.toUtc().toIso8601String(),
      'storage_id': storageId,
      'comment': 'RMK',
      'counterparty_id': leadId ?? 0,
      'lead_id': leadId ?? 0,
      'document_goods': saleItems,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
      'payment_mode': paymentMode,
      'paid_amount': paidAmount,
      'debt_amount': debtAmount,
      'approve': true,
      if (cashRegisterId != null) 'cash_register_id': cashRegisterId,
      if (currencyId != null) 'currency_id': currencyId,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
    };
    if (paymentMethod != null) {
      payload['payment_type'] = paymentMethod;
    }
    return payload;
  }

  Future<int> _requiredUnitIdForCartItem(RmkCartItem item) async {
    final unitId = await _unitIdForGood(item.goodId);
    if (unitId != null && unitId > 0) return unitId;

    await _refreshGoodUnitInfo(item.goodId);
    final refreshedUnitId = await _unitIdForGood(item.goodId);
    if (refreshedUnitId != null && refreshedUnitId > 0) {
      return refreshedUnitId;
    }

    throw Exception('У товара "${item.name}" не найдена единица измерения');
  }

  Future<int> requiredUnitIdForCartItem(RmkCartItem item) {
    return _requiredUnitIdForCartItem(item);
  }

  Future<int?> _unitIdForGood(int goodId) async {
    final good = await (_db.select(_db.rmkGoods)
          ..where((tbl) => tbl.id.equals(goodId)))
        .getSingleOrNull();
    if (good == null) return null;

    try {
      final decoded = jsonDecode(good.payload);
      if (decoded is Map<String, dynamic>) {
        return _extractUnitId(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> _refreshGoodUnitInfo(int goodId) async {
    try {
      final goods = await _apiService.getGoodsById(goodId, isFromOrder: true);
      if (goods.isNotEmpty) {
        await _saveGoodsFromLookup(goods);
        return;
      }
    } catch (error) {
      debugPrint('RMK good unit refresh failed for $goodId: $error');
    }

    try {
      final variant = await _findVariantById(goodId);
      if (variant != null) {
        await _saveGoods([variant], page: 1);
      }
    } catch (error) {
      debugPrint('RMK variant fallback refresh failed for $goodId: $error');
    }
  }

  Future<Variant?> _findVariantById(int variantId) async {
    var page = 1;
    const maxPagesToCheck = 10;

    while (page <= maxPagesToCheck) {
      final response = await _apiService.getVariants(
        page: page,
        perPage: _syncPageSize,
      );
      final variants = response.data;
      if (variants.isEmpty) return null;

      final match = variants.where((item) => item.id == variantId).firstOrNull;
      if (match != null) {
        return match;
      }

      if (page >= response.pagination.totalPages ||
          variants.length < _syncPageSize) {
        return null;
      }

      page += 1;
    }

    return null;
  }

  static int? _extractUnitId(Map<String, dynamic> payload) {
    final directUnitId = _asInt(payload['unit_id']);
    if (directUnitId != null && directUnitId > 0) return directUnitId;

    final unit = payload['unit'];
    if (unit is Map<String, dynamic>) {
      final unitId = _asInt(unit['id']);
      if (unitId != null && unitId > 0) return unitId;
    }

    final units = payload['units'];
    if (units is List) {
      final baseUnit = units.whereType<Map>().where((unit) {
        return unit['is_base'] == true || unit['is_base'] == 1;
      }).firstOrNull;
      final baseUnitId = _asInt(baseUnit?['id']);
      if (baseUnitId != null && baseUnitId > 0) return baseUnitId;

      final firstUnit = units.whereType<Map>().firstOrNull;
      final firstUnitId = _asInt(firstUnit?['id']);
      if (firstUnitId != null && firstUnitId > 0) return firstUnitId;
    }

    final measurements = payload['measurements'];
    if (measurements is List) {
      final firstMeasurement = measurements.whereType<Map>().firstOrNull;
      final measurementUnitId = _asInt(firstMeasurement?['unit_id']);
      if (measurementUnitId != null && measurementUnitId > 0) {
        return measurementUnitId;
      }
    }

    return null;
  }

  static String unitLabelForGood(RmkGood good) {
    return unitLabelFromPayload(good.payload);
  }

  static String unitLabelFromPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return _defaultUnitLabel;

      final cached = decoded['unit_label']?.toString().trim();
      if (cached != null && cached.isNotEmpty) return cached;

      return _extractUnitLabel(decoded) ?? _defaultUnitLabel;
    } catch (_) {
      return _defaultUnitLabel;
    }
  }

  static const String _defaultUnitLabel = 'шт';

  static String? _extractUnitLabel(Map<String, dynamic> payload) {
    final unitId = _asInt(payload['unit_id']);

    final units = payload['units'];
    if (unitId != null && units is List) {
      for (final item in units.whereType<Map<String, dynamic>>()) {
        if (_asInt(item['id']) == unitId) {
          final label = _unitNameFromMap(item);
          if (label != null) return label;
        }
      }
    }

    final unit = payload['unit'];
    if (unit is Map<String, dynamic>) {
      if (unitId == null || _asInt(unit['id']) == unitId) {
        final label = _unitNameFromMap(unit);
        if (label != null) return label;
      }
    }

    final measurements = payload['measurements'];
    if (unitId != null && measurements is List) {
      for (final measurement
          in measurements.whereType<Map<String, dynamic>>()) {
        if (_asInt(measurement['unit_id']) == unitId) {
          final measurementUnit = measurement['unit'];
          if (measurementUnit is Map<String, dynamic>) {
            final label = _unitNameFromMap(measurementUnit);
            if (label != null) return label;
          }
        }
      }
    }

    if (units is List) {
      final baseUnit = units.whereType<Map<String, dynamic>>().where((item) {
        return item['is_base'] == true || item['is_base'] == 1;
      }).firstOrNull;
      final baseLabel = baseUnit != null ? _unitNameFromMap(baseUnit) : null;
      if (baseLabel != null) return baseLabel;

      final firstUnit = units.whereType<Map<String, dynamic>>().firstOrNull;
      if (firstUnit != null) return _unitNameFromMap(firstUnit);
    }

    return null;
  }

  static String? _unitNameFromMap(Map<String, dynamic> unit) {
    final shortName = unit['short_name']?.toString().trim();
    if (shortName != null && shortName.isNotEmpty) return shortName;

    final name = unit['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    return null;
  }

  String? _resolveUnitLabel(Variant variant) {
    final good = variant.good;
    if (good == null) return null;
    return _resolveUnitLabelForGood(good);
  }

  String? _resolveUnitLabelForGood(Goods good) {
    final unitId = _resolveGoodUnitId(good);

    if (unitId != null && good.units != null) {
      for (final unit in good.units!) {
        if (unit.id == unitId) {
          return _unitDisplayName(unit.shortName, unit.name);
        }
      }
    }

    if (good.unit != null && (unitId == null || good.unit!.id == unitId)) {
      return _unitDisplayName(good.unit!.shortName, good.unit!.name);
    }

    if (unitId != null && good.measurements != null) {
      for (final measurement in good.measurements!) {
        if (measurement.unitId == unitId && measurement.unit != null) {
          return _unitDisplayName(
            measurement.unit!.shortName,
            measurement.unit!.name,
          );
        }
      }
    }

    final baseUnit =
        good.units?.where((unit) => unit.isBase == true).firstOrNull;
    if (baseUnit != null) {
      return _unitDisplayName(baseUnit.shortName, baseUnit.name);
    }

    final firstUnit = good.units?.firstOrNull;
    if (firstUnit != null) {
      return _unitDisplayName(firstUnit.shortName, firstUnit.name);
    }

    return null;
  }

  static String? _unitDisplayName(String? shortName, String? name) {
    final short = shortName?.trim();
    if (short != null && short.isNotEmpty) return short;

    final fullName = name?.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;

    return null;
  }

  Future<int> _selectedInt(
    Future<String?> Function() loader, {
    required int fallback,
  }) async {
    final value = await loader();
    return int.tryParse(value ?? '') ?? fallback;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static num _compactNumber(double value) {
    if (value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    return value;
  }

  Future<void> _syncCategories({bool resetCache = false}) async {
    final categories = await _apiService.getCategory();
    final now = DateTime.now();

    Future<void> writeCategories() {
      return _db.batch((batch) {
        for (final category in categories) {
          _writeCategory(batch, category, null, 0, now);
        }
      });
    }

    if (resetCache) {
      await _db.transaction(() async {
        await _db.delete(_db.rmkCategories).go();
        await writeCategories();
      });
      return;
    }

    await writeCategories();
  }

  Future<void> _syncGoods({
    required int storageId,
    bool resetCache = false,
  }) async {
    var page = 1;
    const maxPagesPerSync = 300;
    final shouldLoadAllPages = resetCache ||
        !await _isGoodsFullSyncComplete() ||
        await _hasCachedGoodsWithoutUnitInfo();
    var reachedLastPage = false;

    while (true) {
      final response = await _apiService.getVariants(
        page: page,
        perPage: _syncPageSize,
        filters: {'storage_id': storageId},
      );
      final variants = response.data;
      if (variants.isEmpty) break;

      final hasNewGoods = await _hasNewGoods(variants);
      await _saveGoods(
        variants,
        page: page,
        resetCacheBeforeSave: resetCache && page == 1,
      );

      if (page >= response.pagination.totalPages ||
          variants.length < _syncPageSize) {
        reachedLastPage = true;
        break;
      }
      if (!shouldLoadAllPages && !hasNewGoods) break;
      page += 1;
      if (page > maxPagesPerSync) {
        break;
      }
    }

    if (shouldLoadAllPages && reachedLastPage) {
      await _markGoodsFullSyncComplete();
    }
  }

  Future<void> _writeGoodsBatch(
    List<Variant> variants, {
    required int page,
  }) {
    final now = DateTime.now();
    return _db.batch((batch) {
      for (var index = 0; index < variants.length; index++) {
        final variant = variants[index];
        final good = variant.good;
        final category = good?.category;
        final categoryId = category?.id ?? 0;
        final categoryName = category?.name;
        final sortIndex = ((page - 1) * _syncPageSize) + index;
        final sortDate =
            DateTime(2100).subtract(Duration(milliseconds: sortIndex));
        batch.insert(
          _db.rmkGoods,
          RmkGoodsCompanion.insert(
            id: Value(variant.id),
            name: variant.fullName ?? good?.name ?? '',
            normalizedName: _normalize(
              '${variant.fullName ?? good?.name ?? ''} ${good?.article ?? ''} ${variant.barcode ?? ''}',
            ),
            categoryId: Value(categoryId == 0 ? null : categoryId),
            categoryName: Value(categoryName),
            price: Value(variant.price ?? 0),
            quantity: Value(variant.remainder ?? 0),
            imageUrl: Value(good?.mainImageUrl),
            payload: _goodsPayload(variant),
            serverCreatedAt: Value(sortDate),
            serverUpdatedAt: Value(null),
            localUpdatedAt: now,
            isDeleted: const Value(false),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _saveGoods(
    List<Variant> variants, {
    required int page,
    bool resetCacheBeforeSave = false,
  }) async {
    if (resetCacheBeforeSave) {
      await _db.transaction(() async {
        await _resetGoodsCache();
        await _writeGoodsBatch(variants, page: page);
      });
      return;
    }

    await _writeGoodsBatch(variants, page: page);
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

  Future<bool> _hasCachedGoodsWithoutUnitInfo() async {
    final cachedGoods = await _db.select(_db.rmkGoods).get();
    return cachedGoods.any((good) {
      final payload = good.payload;
      return !payload.contains('"unit_id"') ||
          !payload.contains('"unit_label"');
    });
  }

  Future<bool> _isGoodsFullSyncComplete() async {
    final state = await (_db.select(_db.syncStates)
          ..where((tbl) =>
              tbl.module.equals(_syncModule) &
              tbl.scope.equals(_goodsFullSyncScope)))
        .getSingleOrNull();
    return state?.entityVersion == _syncCompleteVersion;
  }

  Future<void> _markGoodsFullSyncComplete() async {
    final now = DateTime.now();
    await _db.into(_db.syncStates).insertOnConflictUpdate(
          SyncStatesCompanion.insert(
            module: _syncModule,
            scope: _goodsFullSyncScope,
            entityVersion: const Value(_syncCompleteVersion),
            lastSyncedAt: Value(now),
            updatedAt: now,
          ),
        );
  }

  Future<bool> _hasNewGoods(List<Variant> variants) async {
    if (variants.isEmpty) return false;

    final ids = variants.map((variant) => variant.id).toList(growable: false);
    final cachedGoods = await (_db.select(_db.rmkGoods)
          ..where((tbl) => tbl.id.isIn(ids)))
        .get();
    final cachedIds = cachedGoods.map((good) => good.id).toSet();

    return ids.any((id) => !cachedIds.contains(id));
  }

  Future<void> _saveGoodsFromLookup(List<Goods> goods) async {
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
            price: Value(_extractGoodPrice(good)),
            quantity: Value((good.quantity ?? 0).toDouble()),
            imageUrl: Value(good.mainImageUrl),
            payload: _goodsLookupPayload(good),
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

  double _extractGoodPrice(Goods good) {
    if (good.discountedPrice != null) return good.discountedPrice!;
    if (good.discountPrice != null) return good.discountPrice!;
    if (good.price != null) return double.tryParse(good.price!) ?? 0;
    return 0;
  }

  String _goodsPayload(Variant variant) {
    final good = variant.good;
    return jsonEncode({
      'id': variant.id,
      'variant_id': variant.id,
      'good_id': variant.goodId,
      'barcode': variant.barcode,
      'name': variant.fullName ?? good?.name,
      'article': good?.article,
      'category_id': good?.category.id,
      'category_name': good?.category.name,
      'quantity': variant.remainder,
      'remainder': variant.remainder,
      'price': variant.price,
      'unit_id': _resolveUnitId(variant),
      'unit_label': _resolveUnitLabel(variant),
      'unit': good?.unit?.toJson(),
      'units': good?.units?.map((unit) => unit.toJson()).toList(),
      'measurements': good?.measurements
          ?.map((measurement) => {
                'id': measurement.id,
                'good_id': measurement.goodId,
                'unit_id': measurement.unitId,
                'amount': measurement.amount,
                'unit': measurement.unit?.toJson(),
              })
          .toList(),
      'image_url': good?.mainImageUrl,
    });
  }

  String _goodsPayloadWithQuantity(String payload, double quantity) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        decoded['quantity'] = quantity;
        decoded['remainder'] = quantity;
        return jsonEncode(decoded);
      }
    } catch (_) {
      // Keep the original payload if legacy cached data is malformed.
    }
    return payload;
  }

  String _goodsLookupPayload(Goods good) {
    return jsonEncode({
      'id': good.id,
      'name': good.name,
      'article': good.article,
      'category_id': good.category.id,
      'category_name': good.category.name,
      'quantity': good.quantity,
      'price': good.price,
      'unit_id': _resolveGoodUnitId(good),
      'unit_label': _resolveUnitLabelForGood(good),
      'unit': good.unit?.toJson(),
      'units': good.units?.map((unit) => unit.toJson()).toList(),
      'measurements': good.measurements
          ?.map((measurement) => {
                'id': measurement.id,
                'good_id': measurement.goodId,
                'unit_id': measurement.unitId,
                'amount': measurement.amount,
                'unit': measurement.unit?.toJson(),
              })
          .toList(),
      'image_url': good.mainImageUrl,
    });
  }

  int? _resolveUnitId(Variant variant) {
    final good = variant.good;
    if (good == null) return null;
    return _resolveGoodUnitId(good);
  }

  int? _resolveGoodUnitId(Goods good) {
    if (good.unitId != null && good.unitId! > 0) return good.unitId;
    if (good.unit?.id != null && good.unit!.id! > 0) return good.unit!.id;

    final baseUnit =
        good.units?.where((unit) => unit.isBase == true).firstOrNull;
    if (baseUnit?.id != null && baseUnit!.id! > 0) return baseUnit.id;

    final firstUnit = good.units?.firstOrNull;
    if (firstUnit?.id != null && firstUnit!.id! > 0) return firstUnit.id;

    final firstMeasurement = good.measurements?.firstOrNull;
    if (firstMeasurement != null && firstMeasurement.unitId > 0) {
      return firstMeasurement.unitId;
    }

    return null;
  }

  static String _normalize(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static Set<int> categoryIdsIncludingDescendants(
    int categoryId,
    List<RmkCategory> categories,
  ) {
    final ids = <int>{categoryId};

    void collectChildren(int parentId) {
      for (final category in categories) {
        if (category.parentId == parentId) {
          ids.add(category.id);
          collectChildren(category.id);
        }
      }
    }

    collectChildren(categoryId);
    return ids;
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
