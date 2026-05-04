import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';

abstract class ManufactureEvent extends Equatable {
  const ManufactureEvent();

  @override
  List<Object> get props => [];
}

class FetchManufactures extends ManufactureEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status;
  final String? search;

  const FetchManufactures({
    this.forceRefresh = false,
    this.filters,
    this.status,
    this.search,
  });

  @override
  List<Object> get props =>
      [forceRefresh, filters ?? {}, status ?? 0, search ?? ''];
}

class CreateManufactureDocument extends ManufactureEvent {
  final String date;
  final int senderStorageId;
  final int recipientStorageId;
  final String comment;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final bool approve;

  const CreateManufactureDocument({
    required this.date,
    required this.senderStorageId,
    required this.recipientStorageId,
    required this.comment,
    required this.documentGoods,
    required this.organizationId,
    this.approve = false,
  });

  @override
  List<Object> get props => [
        date,
        senderStorageId,
        recipientStorageId,
        comment,
        documentGoods,
        organizationId,
        approve,
      ];
}

class UpdateManufactureDocument extends ManufactureEvent {
  final int documentId;
  final String date;
  final int senderStorageId;
  final int recipientStorageId;
  final String comment;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final bool approve;

  const UpdateManufactureDocument({
    required this.documentId,
    required this.date,
    required this.senderStorageId,
    required this.recipientStorageId,
    required this.comment,
    required this.documentGoods,
    required this.organizationId,
    this.approve = false,
  });

  @override
  List<Object> get props => [
        documentId,
        date,
        senderStorageId,
        recipientStorageId,
        comment,
        documentGoods,
        organizationId,
        approve,
      ];
}

class DeleteManufactureDocument extends ManufactureEvent {
  final int documentId;
  final AppLocalizations localizations;
  final bool shouldReload;

  const DeleteManufactureDocument(this.documentId, this.localizations,
      {this.shouldReload = true});

  @override
  List<Object> get props => [documentId, localizations, shouldReload];
}

class RestoreManufactureDocument extends ManufactureEvent {
  final int documentId;
  final AppLocalizations localizations;

  const RestoreManufactureDocument(this.documentId, this.localizations);

  @override
  List<Object> get props => [documentId, localizations];
}

// Mass Operations Events
class MassApproveManufactureDocuments extends ManufactureEvent {
  @override
  List<Object> get props => [];
}

class MassDisapproveManufactureDocuments extends ManufactureEvent {
  @override
  List<Object> get props => [];
}

class MassDeleteManufactureDocuments extends ManufactureEvent {
  @override
  List<Object> get props => [];
}

class MassRestoreManufactureDocuments extends ManufactureEvent {
  @override
  List<Object> get props => [];
}

// Selection Events
class SelectDocument extends ManufactureEvent {
  final IncomingDocument document;

  const SelectDocument(this.document);

  @override
  List<Object> get props => [document];
}

class UnselectAllDocuments extends ManufactureEvent {
  @override
  List<Object> get props => [];
}
