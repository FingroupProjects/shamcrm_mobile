import 'package:flutter/material.dart';

@immutable
abstract class DeliveryAddressEvent {}

class FetchDeliveryAddresses extends DeliveryAddressEvent {
  final int leadId;
  final int organizationId;

  FetchDeliveryAddresses({
    required this.leadId,
    required this.organizationId,
  });
}