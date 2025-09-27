import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:equatable/equatable.dart';

import '../../../../models/page_2/incoming_document_model.dart';

abstract class IncomingEvent extends Equatable {
  const IncomingEvent();

  @override
  List<Object> get props => [];
}

class FetchIncoming extends IncomingEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status;

  const FetchIncoming({
    this.forceRefresh = false,
    this.filters,
    this.status,
  });

  @override
  List<Object> get props => [forceRefresh, filters ?? {}, status ?? 0];
}

class CreateIncoming extends IncomingEvent {
  final String date;
  final int storageId;
  final String comment;
  final int counterpartyId;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final int salesFunnelId;
  final bool approve; // Новый параметр

  CreateIncoming({
    required this.date,
    required this.storageId,
    required this.comment,
    required this.counterpartyId,
    required this.documentGoods,
    required this.organizationId,
    required this.salesFunnelId,
    this.approve = false, // По умолчанию false
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
    approve, // Добавляем в props
  ];
}

class UpdateIncoming extends IncomingEvent {
  final int documentId;
  final String date;
  final int storageId;
  final String comment;
  final int counterpartyId;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final int salesFunnelId;

  const UpdateIncoming({
    required this.documentId,
    required this.date,
    required this.storageId,
    required this.comment,
    required this.counterpartyId,
    required this.documentGoods,
    required this.organizationId,
    required this.salesFunnelId,
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
      ];
}
class DeleteIncoming extends IncomingEvent {
  final int documentId;
  final AppLocalizations localizations;

  const DeleteIncoming(this.documentId, this.localizations);

  @override
  List<Object> get props => [documentId, localizations];
}

class RestoreIncoming extends IncomingEvent {
  final int documentId;
  final AppLocalizations localizations;

  const RestoreIncoming(this.documentId, this.localizations);

  @override
  List<Object> get props => [documentId, localizations];
}

class MassApproveIncomingDocuments extends IncomingEvent {

  @override
  List<Object> get props => [];
}

class MassDisapproveIncomingDocuments extends IncomingEvent {

  @override
  List<Object> get props => [];
}

class MassDeleteIncomingDocuments extends IncomingEvent {

  @override
  List<Object> get props => [];
}

class MassRestoreIncomingDocuments extends IncomingEvent {

  @override
  List<Object> get props => [];
}


class SelectDocument extends IncomingEvent {
  final IncomingDocument document;

  const SelectDocument(this.document);

  @override
  List<Object> get props => [document];
}

class UnselectAllDocuments extends IncomingEvent {
  @override
  List<Object> get props => [];
}