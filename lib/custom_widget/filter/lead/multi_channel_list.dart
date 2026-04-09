import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead_channel_list/lead_channel_bloc.dart';
import 'package:crm_task_manager/models/lead_filter_channel_model.dart';
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

  final TextStyle channelTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

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
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? Colors.red : const Color(0xFFE5E7EB),
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
                      closedFillColor: const Color(0xffF4F7FD),
                      expandedFillColor: Colors.white,
                      closedBorder: Border.all(color: Colors.transparent),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder:
                          Border.all(color: const Color(0xFFE5E7EB)),
                      expandedBorderRadius: BorderRadius.circular(12),
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
                            const Divider(height: 20, color: Color(0xFFE5E7EB)),
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
                      style: channelTextStyle.copyWith(fontSize: 14),
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

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xff1E2E52), width: 1),
        borderRadius: BorderRadius.circular(4),
        color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }

  Widget _buildListItem(
    LeadFilterChannelData item,
    bool isSelected,
    Function() onItemSelect,
  ) {
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
