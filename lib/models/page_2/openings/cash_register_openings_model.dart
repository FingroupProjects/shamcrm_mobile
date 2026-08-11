import 'package:crm_task_manager/utils/safe_converters.dart';

class CashRegisterOpeningsResponse {
  final List<CashRegisterOpening>? result;
  final dynamic errors;

  CashRegisterOpeningsResponse({
    this.result,
    this.errors,
  });

  factory CashRegisterOpeningsResponse.fromJson(Map<String, dynamic> json) {
    // ignore: avoid_print
    if (true) { // Временно всегда логируем для отладки
      print('🟢 CashRegisterOpeningsResponse.fromJson - входной JSON keys: ${json.keys.toList()}');
    }
    
    if (json["result"] != null) {
      final resultData = json["result"];
      // ignore: avoid_print
      print('🟢 CashRegisterOpeningsResponse.fromJson - resultData type: ${resultData.runtimeType}');
      
      if (resultData is Map<String, dynamic> && resultData["data"] != null) {
        // Формат: {"result": {"data": [...], "pagination": {...}}}
        // ignore: avoid_print
        print('🟢 CashRegisterOpeningsResponse.fromJson - формат: result.data');
        final rawList = SafeConverters.toList(resultData["data"]);
        if (rawList == null) {
          // ignore: avoid_print
          print('🟡 CashRegisterOpeningsResponse.fromJson - rawList is null');
          return CashRegisterOpeningsResponse(result: [], errors: json["errors"]);
        }
        // ignore: avoid_print
        print('🟢 CashRegisterOpeningsResponse.fromJson - rawList length: ${rawList.length}');
        
        final mappedList = <CashRegisterOpening>[];
        for (var i = 0; i < rawList.length; i++) {
          try {
            final item = rawList[i];
            if (item is! Map<String, dynamic>) {
              // ignore: avoid_print
              print('🟡 CashRegisterOpeningsResponse.fromJson - item $i is not Map, type: ${item.runtimeType}');
              continue;
            }
            // ignore: avoid_print
            print('🟢 CashRegisterOpeningsResponse.fromJson - парсинг item $i, keys: ${item.keys.toList()}');
            mappedList.add(CashRegisterOpening.fromJson(item));
            // ignore: avoid_print
            print('🟢 CashRegisterOpeningsResponse.fromJson - item $i успешно распарсен');
          } catch (e, st) {
            // ignore: avoid_print
            print('🔴 CashRegisterOpeningsResponse.fromJson - ОШИБКА при парсинге item $i: $e');
            // ignore: avoid_print
            print('🔴 CashRegisterOpeningsResponse.fromJson - STACK: $st');
            rethrow; // Пробрасываем ошибку дальше для диагностики
          }
        }
        // ignore: avoid_print
        print('🟢 CashRegisterOpeningsResponse.fromJson - успешно распарсено ${mappedList.length} элементов');
        return CashRegisterOpeningsResponse(result: mappedList, errors: json["errors"]);
      } else if (resultData is List) {
        // Формат: {"result": [...]}
        // ignore: avoid_print
        print('🟢 CashRegisterOpeningsResponse.fromJson - формат: result как List');
        final mappedList = <CashRegisterOpening>[];
        for (var i = 0; i < resultData.length; i++) {
          try {
            final item = resultData[i];
            if (item is! Map<String, dynamic>) {
              // ignore: avoid_print
              print('🟡 CashRegisterOpeningsResponse.fromJson - item $i is not Map');
              continue;
            }
            mappedList.add(CashRegisterOpening.fromJson(item));
          } catch (e, st) {
            // ignore: avoid_print
            print('🔴 CashRegisterOpeningsResponse.fromJson - ОШИБКА при парсинге item $i: $e');
            rethrow;
          }
        }
        return CashRegisterOpeningsResponse(result: mappedList, errors: json["errors"]);
      } else {
        // ignore: avoid_print
        print('🟡 CashRegisterOpeningsResponse.fromJson - resultData не Map и не List, type: ${resultData.runtimeType}');
      }
    } else {
      // ignore: avoid_print
      print('🟡 CashRegisterOpeningsResponse.fromJson - json["result"] is null');
    }
    // ignore: avoid_print
    print('🟡 CashRegisterOpeningsResponse.fromJson - возвращаем пустой результат');
    return CashRegisterOpeningsResponse(result: [], errors: json["errors"]);
  }

  Map<String, dynamic> toJson() => {
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toJson())),
        "errors": errors,
      };
}

class CashRegisterOpening {
  final int? id;
  final int? cashRegisterId;
  final String? sum;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? cashId;
  final CashRegister? cashRegister;

  CashRegisterOpening({
    this.id,
    this.cashRegisterId,
    this.sum,
    this.createdAt,
    this.updatedAt,
    this.cashId,
    this.cashRegister,
  });

  factory CashRegisterOpening.fromJson(Map<String, dynamic> json) {
    // ignore: avoid_print
    print('🔵 CashRegisterOpening.fromJson - входные keys: ${json.keys.toList()}');
    
    // Формат 1: {"cash_register_id", "sum", "cash_register": {...}}
    final hasCashRegister = json["cash_register"] != null;
    if (hasCashRegister) {
      // ignore: avoid_print
      print('🔵 CashRegisterOpening.fromJson - используем формат 1 (с cash_register)');
      try {
        final opening = CashRegisterOpening(
          id: SafeConverters.toIntOrNull(json["id"]),
          cashRegisterId: SafeConverters.toIntOrNull(json["cash_register_id"]),
          sum: SafeConverters.toStringOrNull(json["sum"]),
          createdAt: SafeConverters.toDateTimeOrNull(json["created_at"]),
          updatedAt: SafeConverters.toDateTimeOrNull(json["updated_at"]),
          cashId: SafeConverters.toIntOrNull(json["cash_id"]),
          cashRegister: CashRegister.fromJson(
              SafeConverters.toMap(json["cash_register"])),
        );
        // ignore: avoid_print
        print('🔵 CashRegisterOpening.fromJson - формат 1 успешно распарсен');
        return opening;
      } catch (e, st) {
        // ignore: avoid_print
        print('🔴 CashRegisterOpening.fromJson - ОШИБКА в формате 1: $e');
        // ignore: avoid_print
        print('🔴 CashRegisterOpening.fromJson - STACK: $st');
        rethrow;
      }
    }
    // Формат 2: API возвращает {"id", "name", "users", "created_at", "updated_at"} — касса как элемент списка
    // ignore: avoid_print
    print('🔵 CashRegisterOpening.fromJson - используем формат 2 (прямой объект кассы)');
    try {
      final id = SafeConverters.toIntOrNull(json["id"]);
      // ignore: avoid_print
      print('🔵 CashRegisterOpening.fromJson - parsed id: $id');
      
      final cashReg = CashRegister.fromJson(json);
      // ignore: avoid_print
      print('🔵 CashRegisterOpening.fromJson - CashRegister распарсен, name: ${cashReg.name}');
      
      final opening = CashRegisterOpening(
        id: id,
        cashRegisterId: id,
        sum: SafeConverters.toStringOrNull(json["sum"]),
        createdAt: SafeConverters.toDateTimeOrNull(json["created_at"]),
        updatedAt: SafeConverters.toDateTimeOrNull(json["updated_at"]),
        cashId: id,
        cashRegister: cashReg,
      );
      // ignore: avoid_print
      print('🔵 CashRegisterOpening.fromJson - формат 2 успешно распарсен');
      return opening;
    } catch (e, st) {
      // ignore: avoid_print
      print('🔴 CashRegisterOpening.fromJson - ОШИБКА в формате 2: $e');
      // ignore: avoid_print
      print('🔴 CashRegisterOpening.fromJson - STACK: $st');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "cash_register_id": cashRegisterId,
        "sum": sum,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "cash_id": cashId,
        "cash_register": cashRegister?.toJson(),
      };
}

class CashRegister {
  final int? id;
  final String? name;
  final int? organizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  /// Список пользователей кассы (опционально, API может возвращать)
  final List<dynamic>? users;

  CashRegister({
    this.id,
    this.name,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
    this.users,
  });

  factory CashRegister.fromJson(Map<String, dynamic> json) {
    try {
      // ignore: avoid_print
      print('🟣 CashRegister.fromJson - входные keys: ${json.keys.toList()}');
      final cashReg = CashRegister(
        id: SafeConverters.toIntOrNull(json["id"]),
        name: SafeConverters.toStringOrNull(json["name"]),
        organizationId: SafeConverters.toIntOrNull(json["organization_id"]),
        createdAt: SafeConverters.toDateTimeOrNull(json["created_at"]),
        updatedAt: SafeConverters.toDateTimeOrNull(json["updated_at"]),
        users: SafeConverters.toList(json["users"]).isEmpty
            ? null
            : SafeConverters.toList(json["users"]),
      );
      // ignore: avoid_print
      print('🟣 CashRegister.fromJson - успешно распарсен, id: ${cashReg.id}, name: ${cashReg.name}');
      return cashReg;
    } catch (e, st) {
      // ignore: avoid_print
      print('🔴 CashRegister.fromJson - ОШИБКА: $e');
      // ignore: avoid_print
      print('🔴 CashRegister.fromJson - STACK: $st');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "organization_id": organizationId,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
