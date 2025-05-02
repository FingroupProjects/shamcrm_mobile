class DeliveryAddress {
  final int id;
  final String address;

  DeliveryAddress({
    required this.id,
    required this.address,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    print('DeliveryAddress: Parsing JSON: $json');
    return DeliveryAddress(
      id: json['id'] as int,
      address: json['address'] as String? ?? 'No address provided',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
    };
  }
}

class DeliveryAddressResponse {
  final List<DeliveryAddress> result;

  DeliveryAddressResponse({required this.result});

  factory DeliveryAddressResponse.fromJson(Map<String, dynamic> json) {
    print('DeliveryAddressResponse: Parsing JSON: $json');
    final result = (json['result'] as List<dynamic>? ?? [])
        .map((item) => DeliveryAddress.fromJson(item as Map<String, dynamic>))
        .toList();
    print('DeliveryAddressResponse: Parsed ${result.length} addresses');
    return DeliveryAddressResponse(result: result);
  }
}