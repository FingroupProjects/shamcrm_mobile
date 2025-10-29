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
      result: json['result'] != null
          ? IlliquidGoodsResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      errors: json['errors'] as List<String>?,
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
  final int? nonLiquidGoods;
  final int? liquidGoods;
  final int? nonLiquidChange;
  final int? liquidChange;
  final String? nonLiquidChangeFormatted;
  final String? liquidChangeFormatted;

  const IlliquidGoodsResult({
    required this.nonLiquidGoods,
    required this.liquidGoods,
    required this.nonLiquidChange,
    required this.liquidChange,
    required this.nonLiquidChangeFormatted,
    required this.liquidChangeFormatted,
  });

  factory IlliquidGoodsResult.fromJson(Map<String, dynamic> json) {
    return IlliquidGoodsResult(
      nonLiquidGoods: json['nonLiquidGoods'] as int?,
      liquidGoods: json['liquidGoods'] as int?,
      nonLiquidChange: json['nonLiquidChange'] as int?,
      liquidChange: json['liquidChange'] as int?,
      nonLiquidChangeFormatted: json['nonLiquidChangeFormatted'] as String?,
      liquidChangeFormatted: json['liquidChangeFormatted'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nonLiquidGoods': nonLiquidGoods,
      'liquidGoods': liquidGoods,
      'nonLiquidChange': nonLiquidChange,
      'liquidChange': liquidChange,
      'nonLiquidChangeFormatted': nonLiquidChangeFormatted,
      'liquidChangeFormatted': liquidChangeFormatted,
    };
  }

  @override
  List<Object?> get props => [
        nonLiquidGoods,
        liquidGoods,
        nonLiquidChange,
        liquidChange,
        nonLiquidChangeFormatted,
        liquidChangeFormatted,
      ];
}