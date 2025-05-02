import 'package:crm_task_manager/models/page_2/delivery_address_model.dart';
import 'package:flutter/material.dart';

@immutable
abstract class DeliveryAddressState {}

class DeliveryAddressInitial extends DeliveryAddressState {}

class DeliveryAddressLoading extends DeliveryAddressState {}

class DeliveryAddressLoaded extends DeliveryAddressState {
  final List<DeliveryAddress> addresses;

  DeliveryAddressLoaded(this.addresses);
}

class DeliveryAddressError extends DeliveryAddressState {
  final String message;

  DeliveryAddressError(this.message);
}