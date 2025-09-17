// movement_event.dart
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:equatable/equatable.dart';

abstract class MovementEvent extends Equatable {
  const MovementEvent();

  @override
  List<Object> get props => [];
}

class FetchMovements extends MovementEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status;

  const FetchMovements({
    this.forceRefresh = false,
    this.filters,
    this.status,
  });

  @override
  List<Object> get props => [forceRefresh, filters ?? {}, status ?? 0];
}

class CreateMovementDocument extends MovementEvent {
  final String date;
  final int senderStorageId;
  final int recipientStorageId;
  final String comment;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;

  const CreateMovementDocument({
    required this.date,
    required this.senderStorageId,
    required this.recipientStorageId,
    required this.comment,
    required this.documentGoods,
    required this.organizationId,
  });

  @override
  List<Object> get props => [
    date,
    senderStorageId,
    recipientStorageId,
    comment,
    documentGoods,
    organizationId,
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

  const UpdateMovementDocument({
    required this.documentId,
    required this.date,
    required this.senderStorageId,
    required this.recipientStorageId,
    required this.comment,
    required this.documentGoods,
    required this.organizationId,
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
  ];
}

class DeleteMovementDocument extends MovementEvent {
  final int documentId;
  final AppLocalizations localizations;

  const DeleteMovementDocument(this.documentId, this.localizations);

  @override
  List<Object> get props => [documentId, localizations];
}

class RestoreMovementDocument extends MovementEvent {
  final int documentId;
  final AppLocalizations localizations;

  const RestoreMovementDocument(this.documentId, this.localizations);

  @override
  List<Object> get props => [documentId, localizations];
}
