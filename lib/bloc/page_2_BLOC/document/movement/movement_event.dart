import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';

abstract class MovementEvent extends Equatable {
  const MovementEvent();

  @override
  List<Object> get props => [];
}

class FetchMovements extends MovementEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status;
  final String? search;

  const FetchMovements({
    this.forceRefresh = false,
    this.filters,
    this.status,
    this.search,
  });

  @override
  List<Object> get props => [forceRefresh, filters ?? {}, status ?? 0, search ?? ''];
}

class CreateMovementDocument extends MovementEvent {
  final String date;
  final int senderStorageId;
  final int recipientStorageId;
  final String comment;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final bool approve;

  const CreateMovementDocument({
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

class UpdateMovementDocument extends MovementEvent {
  final int documentId;
  final String date;
  final int senderStorageId;
  final int recipientStorageId;
  final String comment;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final bool approve;

  const UpdateMovementDocument({
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

class DeleteMovementDocument extends MovementEvent {
  final int documentId;
  final AppLocalizations localizations;
  final bool shouldReload;

  const DeleteMovementDocument(this.documentId, this.localizations, {this.shouldReload = true});

  @override
  List<Object> get props => [documentId, localizations, shouldReload];
}

class RestoreMovementDocument extends MovementEvent {
  final int documentId;
  final AppLocalizations localizations;

  const RestoreMovementDocument(this.documentId, this.localizations);

  @override
  List<Object> get props => [documentId, localizations];
}

// Mass Operations Events
class MassApproveMovementDocuments extends MovementEvent {
  @override
  List<Object> get props => [];
}

class MassDisapproveMovementDocuments extends MovementEvent {
  @override
  List<Object> get props => [];
}

class MassDeleteMovementDocuments extends MovementEvent {
  @override
  List<Object> get props => [];
}

class MassRestoreMovementDocuments extends MovementEvent {
  @override
  List<Object> get props => [];
}

// Selection Events
class SelectDocument extends MovementEvent {
  final IncomingDocument document;

  const SelectDocument(this.document);

  @override
  List<Object> get props => [document];
}

class UnselectAllDocuments extends MovementEvent {
  @override
  List<Object> get props => [];
}