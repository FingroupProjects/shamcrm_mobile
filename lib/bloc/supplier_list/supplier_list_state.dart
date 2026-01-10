import 'package:crm_task_manager/models/supplier_list_model.dart';
import 'package:flutter/material.dart';

@immutable
sealed class GetAllSupplierState {}

final class GetAllSupplierInitial extends GetAllSupplierState {}

final class GetAllSupplierLoading extends GetAllSupplierState {}

final class GetAllSupplierError extends GetAllSupplierState {
  final String message;

  GetAllSupplierError({required this.message});
}

final class GetAllSupplierSuccess extends GetAllSupplierState {
  final SuppliersDataResponse dataSuppliers;

  GetAllSupplierSuccess({required this.dataSuppliers});
}