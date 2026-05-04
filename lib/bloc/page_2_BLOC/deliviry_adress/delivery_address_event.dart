import 'package:flutter/material.dart';

@immutable
abstract class DeliveryAddressEvent {}

class FetchDeliveryAddresses extends DeliveryAddressEvent {
  final int? leadId;
  final int? dealId;

  FetchDeliveryAddresses({
    this.leadId,
    this.dealId,
  });
}
