import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:equatable/equatable.dart';

abstract class SupplierReturnEvent extends Equatable {
  const SupplierReturnEvent();

  @override
  List<Object> get props => [];
}

class FetchSupplierReturn extends SupplierReturnEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status;

  const FetchSupplierReturn({
    this.forceRefresh = false,
    this.filters,
    this.status,
  });

  @override
  List<Object> get props => [forceRefresh, filters ?? {}, status ?? 0];
}

class CreateSupplierReturn extends SupplierReturnEvent {
  final String date;
  final int storageId;
  final String comment;
  final int counterpartyId;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final int salesFunnelId;
  final bool approve;
  final double? exchangeRate;

  CreateSupplierReturn({
    required this.date,
    required this.storageId,
    required this.comment,
    required this.counterpartyId,
    required this.documentGoods,
    required this.organizationId,
    required this.salesFunnelId,
    this.approve = false,
    this.exchangeRate,
  });

  @override
  List<Object> get props => [
        date,
        storageId,
        comment,
        counterpartyId,
        documentGoods,
        organizationId,
        salesFunnelId,
        approve,
        exchangeRate ?? -1,
      ];
}

class UpdateSupplierReturn extends SupplierReturnEvent {
  final int documentId;
  final String date;
  final int storageId;
  final String comment;
  final int counterpartyId;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final int salesFunnelId;
  final double? exchangeRate;

  const UpdateSupplierReturn({
    required this.documentId,
    required this.date,
    required this.storageId,
    required this.comment,
    required this.counterpartyId,
    required this.documentGoods,
    required this.organizationId,
    required this.salesFunnelId,
    this.exchangeRate,
  });

  @override
  List<Object> get props => [
        documentId,
        date,
        storageId,
        comment,
        counterpartyId,
        documentGoods,
        organizationId,
        salesFunnelId,
        exchangeRate ?? -1,
      ];
}

class DeleteSupplierReturn extends SupplierReturnEvent {
  final int documentId;
  final bool shouldReload;

  const DeleteSupplierReturn(this.documentId, {this.shouldReload = true});

  @override
  List<Object> get props => [documentId, shouldReload];
}

class RestoreSupplierReturn extends SupplierReturnEvent {
  final int documentId;
  final AppLocalizations localizations;

  const RestoreSupplierReturn(this.documentId, this.localizations);

  @override
  List<Object> get props => [documentId, localizations];
}

// Массовые операции
class MassApproveSupplierReturnDocuments extends SupplierReturnEvent {
  @override
  List<Object> get props => [];
}

class MassDisapproveSupplierReturnDocuments extends SupplierReturnEvent {
  @override
  List<Object> get props => [];
}

class MassDeleteSupplierReturnDocuments extends SupplierReturnEvent {
  @override
  List<Object> get props => [];
}

class MassRestoreSupplierReturnDocuments extends SupplierReturnEvent {
  @override
  List<Object> get props => [];
}

// Выбор документов
class SelectSupplierReturnDocument extends SupplierReturnEvent {
  final IncomingDocument document;

  const SelectSupplierReturnDocument(this.document);

  @override
  List<Object> get props => [document];
}

class UnselectAllSupplierReturnDocuments extends SupplierReturnEvent {
  @override
  List<Object> get props => [];
}
