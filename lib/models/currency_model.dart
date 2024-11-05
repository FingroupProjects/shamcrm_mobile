class Currency {
  final int id;
  final String name;
  final int digital_code;
  final String symbol_code;



  Currency({
    required this.id,
    required this.name,
    required this.digital_code,
    required this.symbol_code,

  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'],
      name: json['name'],
      digital_code: json['digital_code'],
      symbol_code: json['symbol_code'],
    );
  }
}
