import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegionsMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedRegions;
  final Function(List<RegionData>) onSelectRegions;

  RegionsMultiSelectWidget({
    super.key,
    required this.selectedRegions,
    required this.onSelectRegions,
  });

  @override
  State<RegionsMultiSelectWidget> createState() => _RegionsMultiSelectWidgetState();
}

class _RegionsMultiSelectWidgetState extends State<RegionsMultiSelectWidget> {
  List<RegionData> regionsList = [];
  List<RegionData> selectedRegionsData = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllRegionBloc, GetAllRegionState>(
          builder: (context, state) {
            if (state is GetAllRegionLoading) {
              // return Center(child: CircularProgressIndicator());
            }
            if (state is GetAllRegionError) {
              return Text(state.message);
            }
            if (state is GetAllRegionSuccess) {
              regionsList = state.dataRegion.result ?? [];
              if (widget.selectedRegions != null && regionsList.isNotEmpty) {
                selectedRegionsData = regionsList
                    .where((region) =>widget.selectedRegions!.contains(region.id.toString())).toList();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('region'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xfff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    child: CustomDropdown<RegionData>.multiSelectSearch(
                      items: regionsList,
                      initialItems: selectedRegionsData,
                      searchHintText:
                          AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: Color(0xffF4F7FD),
                        expandedFillColor: Colors.white,
                        closedBorder: Border.all(
                          color: Color(0xffF4F7FD),
                          width: 1,
                        ),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(
                          color: Color(0xffF4F7FD),
                          width: 1,
                        ),
                        expandedBorderRadius: BorderRadius.circular(12),
                      ),
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        return ListTile(
                          minTileHeight: 1,
                          minVerticalPadding: 2,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Padding(
                            padding: EdgeInsets.zero,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Color(0xff1E2E52), width: 1),
                                    color: isSelected
                                        ? Color(0xff1E2E52)
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Icon(Icons.check,
                                          color: Colors.white, size: 16)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Text(item.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xff1E2E52),
                                    )),
                              ],
                            ),
                          ),
                          onTap: () {
                            onItemSelect();
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                      headerListBuilder: (context, hint, enabled) {
                        int selecteRegionsCount = selectedRegionsData.length;

                        return Text(
                          selecteRegionsCount == 0
                              ? AppLocalizations.of(context)!
                                  .translate('select_region')
                              : '${AppLocalizations.of(context)!.translate('select_region')} $selecteRegionsCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                          AppLocalizations.of(context)!
                              .translate('select_region'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          )),
                      onListChanged: (values) {
                        widget.onSelectRegions(values);
                        setState(() {
                          selectedRegionsData = values;
                        });
                      },
                    ),
                  ),
                ],
              );
            }
            return SizedBox();
          },
        ),
      ],
    );
  }
}
