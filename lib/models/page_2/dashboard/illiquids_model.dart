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
      liquidGoods: json['liquidGoods'] as num?,
      liquidChange: json['liquidChange'] as num?,
      liquidChangeFormatted: json['liquidChangeFormatted'] as String?,
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