import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/advertising_campaign_list/advertising_campaign_bloc.dart';
import 'package:crm_task_manager/models/advertising_campaign_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdvertisingCampaignMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedCampaigns;
  final Function(List<AdvertisingCampaignData>) onSelectCampaigns;

  const AdvertisingCampaignMultiSelectWidget({
    super.key,
    required this.onSelectCampaigns,
    this.selectedCampaigns,
  });

  @override
  State<AdvertisingCampaignMultiSelectWidget> createState() =>
      _AdvertisingCampaignMultiSelectWidgetState();
}

class _AdvertisingCampaignMultiSelectWidgetState
    extends State<AdvertisingCampaignMultiSelectWidget> {
  List<AdvertisingCampaignData> campaignsList = [];
  List<AdvertisingCampaignData> selectedCampaignsData = [];
  bool allSelected = false;

  final TextStyle campaignTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    context
        .read<GetAllAdvertisingCampaignBloc>()
        .add(GetAllAdvertisingCampaignEv());
  }

  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      selectedCampaignsData =
          allSelected ? List.from(campaignsList) : <AdvertisingCampaignData>[];
      widget.onSelectCampaigns(selectedCampaignsData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<AdvertisingCampaignData>>(
      validator: (value) {
        if (selectedCampaignsData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<AdvertisingCampaignData>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Рекламная кампания',
              style: campaignTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? Colors.red : const Color(0xFFE5E7EB),
                ),
              ),
              child: BlocBuilder<GetAllAdvertisingCampaignBloc,
                  GetAllAdvertisingCampaignState>(
                builder: (context, state) {
                  if (state is GetAllAdvertisingCampaignSuccess) {
                    campaignsList = state.dataCampaigns;
                    if (widget.selectedCampaigns != null &&
                        campaignsList.isNotEmpty) {
                      selectedCampaignsData = campaignsList
                          .where(
                            (campaign) => widget.selectedCampaigns!
                                .contains(campaign.id.toString()),
                          )
                          .toList();
                      allSelected =
                          selectedCampaignsData.length == campaignsList.length;
                    }
                  }

                  return CustomDropdown<
                      AdvertisingCampaignData>.multiSelectSearch(
                    items: campaignsList,
                    initialItems: selectedCampaignsData,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: const Color(0xffF4F7FD),
                      expandedFillColor: Colors.white,
                      closedBorder: Border.all(color: Colors.transparent),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      if (campaignsList.indexOf(item) == 0) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: GestureDetector(
                                onTap: _toggleSelectAll,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xff1E2E52),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        color: allSelected
                                            ? const Color(0xff1E2E52)
                                            : Colors.transparent,
                                      ),
                                      child: allSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('select_all'),
                                        style: campaignTextStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 20, color: Color(0xFFE5E7EB)),
                            _buildListItem(item, isSelected, onItemSelect),
                          ],
                        );
                      }

                      return _buildListItem(item, isSelected, onItemSelect);
                    },
                    headerListBuilder: (context, hint, enabled) {
                      final selectedCampaignNames = selectedCampaignsData
                              .isEmpty
                          ? 'Выберите рекламную кампанию'
                          : selectedCampaignsData.map((e) => e.name).join(', ');
                      return Text(
                        selectedCampaignNames,
                        style: campaignTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      'Выберите рекламную кампанию',
                      style: campaignTextStyle.copyWith(fontSize: 14),
                    ),
                    onListChanged: (values) {
                      widget.onSelectCampaigns(values);
                      setState(() {
                        selectedCampaignsData = values;
                        allSelected = values.length == campaignsList.length;
                      });
                      field.didChange(values);
                    },
                  );
                },
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildListItem(
    AdvertisingCampaignData item,
    bool isSelected,
    Function() onItemSelect,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xff1E2E52),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color:
                    isSelected ? const Color(0xff1E2E52) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: campaignTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
