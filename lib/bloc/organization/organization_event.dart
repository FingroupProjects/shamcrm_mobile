import 'package:equatable/equatable.dart';

abstract class OrganizationEvent extends Equatable {
  const OrganizationEvent();

  @override
  List<Object> get props => [];
}

class FetchOrganizations extends OrganizationEvent {}
