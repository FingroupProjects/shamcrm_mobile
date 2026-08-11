import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:equatable/equatable.dart';

class IlliquidGoodsResponse extends Equatable {
  final IlliquidGoodsResult? result;
  final List<String>? errors;

  const IlliquidGoodsResponse({
    this.result,
    this.errors,
  });

  factory IlliquidGoodsResponse.fromJson(Map<String, dynamic> json) {
    return IlliquidGoodsResponse(
      result: SafeConverters.toMapOrNull(json['result']) != null
          ? IlliquidGoodsResult.fromJson(SafeConverters.toMap(json['result']))
          : null,
      errors: json['errors'] != null
          ? SafeConverters.toList(json['errors'])
              .map((e) => SafeConverters.toSafeString(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result?.toJson(),
      'errors': errors,
    };
  }

  @override
  List<Object?> get props => [result, errors];
}

class IlliquidGoodsResult extends Equatable {
  final num? liquidGoods;
  final num? liquidChange;
  final String? liquidChangeFormatted;

  const IlliquidGoodsResult({
    required this.liquidGoods,
    required this.liquidChange,
    required this.liquidChangeFormatted,
  });

  factory IlliquidGoodsResult.fromJson(Map<String, dynamic> json) {
    return IlliquidGoodsResult(
      liquidGoods: SafeConverters.toNumOrNull(json['liquidGoods']),
      liquidChange: SafeConverters.toNumOrNull(json['liquidChange']),
      liquidChangeFormatted: SafeConverters.toStringOrNull(json['liquidChangeFormatted']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'liquidGoods': liquidGoods,
      'liquidChange': liquidChange,
      'liquidChangeFormatted': liquidChangeFormatted,
    };
  }

  @override
  List<Object?> get props => [
        liquidGoods,
        liquidChange,
        liquidChangeFormatted,
      ];
}
