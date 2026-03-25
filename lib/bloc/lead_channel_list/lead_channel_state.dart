part of 'lead_channel_bloc.dart';

@immutable
sealed class GetAllLeadChannelState {}

final class GetAllLeadChannelInitial extends GetAllLeadChannelState {}

final class GetAllLeadChannelLoading extends GetAllLeadChannelState {}

final class GetAllLeadChannelError extends GetAllLeadChannelState {
  final String message;

  GetAllLeadChannelError({required this.message});
}

final class GetAllLeadChannelSuccess extends GetAllLeadChannelState {
  final List<LeadFilterChannelData> dataChannels;

  GetAllLeadChannelSuccess({required this.dataChannels});
}
