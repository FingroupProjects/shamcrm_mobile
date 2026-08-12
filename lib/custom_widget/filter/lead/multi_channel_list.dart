import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead_channel_list/lead_channel_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/lead/lead_filter_channel_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChannelsMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedChannels;
  final Function(List<LeadFilterChannelData>) onSelectChannels;

  const ChannelsMultiSelectWidget({
    super.key,
    required this.onSelectChannels,
    this.selectedChannels,
  });

  @override
  State<ChannelsMultiSelectWidget> createState() =>
      _ChannelsMultiSelectWidgetState();
}

class _ChannelsMultiSelectWidgetState extends State<ChannelsMultiSelectWidget> {
  List<LeadFilterChannelData> channelsList = [];
  List<LeadFilterChannelData> selectedChannelsData = [];
  bool allSelected = false;

  @override
  void initState() {
    super.initState();
    context.read<GetAllLeadChannelBloc>().add(GetAllLeadChannelEv());
  }

  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      selectedChannelsData = allSelected ? List.from(channelsList) : [];
      widget.onSelectChannels(selectedChannelsData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final channelTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    final hintStyle = channelTextStyle.copyWith(
      fontSize: 14,
      color: context.appColors.textSecondary,
    );
    return FormField<List<LeadFilterChannelData>>(
      validator: (value) {
        if (selectedChannelsData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<LeadFilterChannelData>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('channels'),
              style: channelTextStyle.copyWith(
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
              child: BlocBuilder<GetAllLeadChannelBloc, GetAllLeadChannelState>(
                builder: (context, state) {
                  if (state is GetAllLeadChannelSuccess) {
                    channelsList = state.dataChannels
                        .where((channel) => channel.id > 0)
                        .toList();
                    if (widget.selectedChannels != null &&
                        channelsList.isNotEmpty) {
                      selectedChannelsData = channelsList
                          .where((channel) => widget.selectedChannels!
                              .contains(channel.id.toString()))
                          .toList();
                      allSelected =
                          selectedChannelsData.length == channelsList.length;
                    }
                  }

                  return CustomDropdown<
                      LeadFilterChannelData>.multiSelectSearch(
                    items: channelsList,
                    initialItems: selectedChannelsData,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: context.appColors.fieldBg,
                      expandedFillColor: context.appColors.surfacePrimary,
                      closedBorder: Border.all(color: Colors.transparent),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder:
                          Border.all(color: context.appColors.borderSubtle),
                      expandedBorderRadius: BorderRadius.circular(12),
                      hintStyle: hintStyle,
                      headerStyle: channelTextStyle,
                      listItemStyle: channelTextStyle,
                      listItemDecoration: ListItemDecoration(
                        selectedColor: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.14),
                        highlightColor: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.08),
                        splashColor: Colors.transparent,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: context.appColors.fieldBg,
                        textStyle: channelTextStyle.copyWith(fontSize: 14),
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
                      if (channelsList.indexOf(item) == 0) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: GestureDetector(
                                onTap: _toggleSelectAll,
                                child: Row(
                                  children: [
                                    _buildCheckbox(allSelected),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('select_all'),
                                        style: channelTextStyle,
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
                      final selectedNames = selectedChannelsData.isEmpty
                          ? AppLocalizations.of(context)!
                              .translate('select_channels')
                          : selectedChannelsData
                              .map((e) => e.displayName)
                              .join(', ');
                      return Text(
                        selectedNames,
                        style: channelTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!
                          .translate('select_channels'),
                      style: hintStyle,
                    ),
                    onListChanged: (values) {
                      widget.onSelectChannels(values);
                      setState(() {
                        selectedChannelsData = values;
                        allSelected = values.length == channelsList.length;
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

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(color: context.appColors.textPrimary, width: 1),
        borderRadius: BorderRadius.circular(4),
        color:
            isSelected ? context.appColors.buttonPrimaryBg : Colors.transparent,
      ),
      child: isSelected
          ? Icon(
              Icons.check,
              color: context.appColors.textInverse,
              size: 14,
            )
          : null,
    );
  }

  Widget _buildListItem(
    LeadFilterChannelData item,
    bool isSelected,
    Function() onItemSelect,
  ) {
    final channelTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
          children: [
            _buildCheckbox(isSelected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.displayName,
                style: channelTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
