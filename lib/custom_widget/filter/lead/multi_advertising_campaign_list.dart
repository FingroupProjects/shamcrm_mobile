import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/advertising_campaign_list/advertising_campaign_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
    final campaignTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    final hintStyle = campaignTextStyle.copyWith(
      fontSize: 14,
      color: context.appColors.textSecondary,
    );
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
                color: context.appColors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError
                      ? context.appColors.error
                      : context.appColors.borderSubtle,
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
                      closedFillColor: context.appColors.fieldBg,
                      expandedFillColor: context.appColors.surfacePrimary,
                      closedBorder: Border.all(color: Colors.transparent),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: context.appColors.borderSubtle,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                      hintStyle: hintStyle,
                      headerStyle: campaignTextStyle,
                      listItemStyle: campaignTextStyle,
                      listItemDecoration: ListItemDecoration(
                        selectedColor: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.14),
                        highlightColor: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.08),
                        splashColor: Colors.transparent,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: context.appColors.fieldBg,
                        textStyle: campaignTextStyle.copyWith(fontSize: 14),
                        hintStyle: hintStyle,
                        prefixIcon: Icon(
                          Icons.search,
                          color: context.appColors.textSecondary,
                        ),
                        suffixIcon: (onClear) => IconButton(
                          onPressed: onClear,
                          icon: Icon(
                            Icons.close_rounded,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.appColors.borderSubtle,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.appColors.buttonPrimaryBg,
                          ),
                        ),
                      ),
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
                                          color: context.appColors.textPrimary,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        color: allSelected
                                            ? context.appColors.buttonPrimaryBg
                                            : Colors.transparent,
                                      ),
                                      child: allSelected
                                          ? Icon(
                                              Icons.check,
                                              color:
                                                  context.appColors.textInverse,
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
                            Divider(
                              height: 20,
                              color: context.appColors.borderSubtle,
                            ),
                            _buildListItem(item, isSelected, onItemSelect),
                          ],
                        );
                      }

                      return _buildListItem(item, isSelected, onItemSelect);
                    },
                    headerListBuilder: (context, hint, enabled) {
                      final selectedCampaignNames = selectedCampaignsData
                              .isEmpty
                          ? AppLocalizations.of(context)!
                              .translate('select_advertising_campaign')
                          : selectedCampaignsData.map((e) => e.name).join(', ');
                      return Text(
                        selectedCampaignNames,
                        style: campaignTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!
                          .translate('select_advertising_campaign'),
                      style: hintStyle,
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
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.error,
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
    final campaignTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
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
                  color: context.appColors.textPrimary,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected
                    ? context.appColors.buttonPrimaryBg
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: context.appColors.textInverse,
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
