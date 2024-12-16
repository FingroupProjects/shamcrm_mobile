import 'package:equatable/equatable.dart';

abstract class CorporateProfileEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchCorporateProfile extends CorporateProfileEvent {
  final int chatId;

  FetchCorporateProfile(this.chatId);

  @override
  List<Object> get props => [chatId];
}
