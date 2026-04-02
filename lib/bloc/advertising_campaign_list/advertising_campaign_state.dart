part of 'advertising_campaign_bloc.dart';

@immutable
sealed class GetAllAdvertisingCampaignState {}

final class GetAllAdvertisingCampaignInitial
    extends GetAllAdvertisingCampaignState {}

final class GetAllAdvertisingCampaignLoading
    extends GetAllAdvertisingCampaignState {}

final class GetAllAdvertisingCampaignError
    extends GetAllAdvertisingCampaignState {
  final String message;

  GetAllAdvertisingCampaignError({required this.message});
}

final class GetAllAdvertisingCampaignSuccess
    extends GetAllAdvertisingCampaignState {
  final List<AdvertisingCampaignData> dataCampaigns;

  GetAllAdvertisingCampaignSuccess({required this.dataCampaigns});
}
