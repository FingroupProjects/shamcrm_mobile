import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegionRadioGroupWidget extends StatefulWidget {
  final String? selectedRegion;
  final Function(RegionData) onSelectRegion;

  RegionRadioGroupWidget(
      {super.key, required this.onSelectRegion, this.selectedRegion});

  @override
  State<RegionRadioGroupWidget> createState() => _RegionRadioGroupWidgetState();
}

class _RegionRadioGroupWidgetState extends State<RegionRadioGroupWidget> {
  List<RegionData> regionsList = [];
  RegionData? selectedRegionData;

  @override
  void initState() {
    super.initState();
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllRegionBloc, GetAllRegionState>(
          builder: (context, state) {
            // Обработка ошибок
            if (state is GetAllRegionError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.translate(state.message),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 3),
                  ),
                );
              });
            }

            // Обновление данных при успешной загрузке
            if (state is GetAllRegionSuccess) {
              regionsList = state.dataRegion.result ?? [];
              if (widget.selectedRegion != null && regionsList.isNotEmpty) {
                try {
                  selectedRegionData = regionsList.firstWhere(
                    (region) => region.id.toString() == widget.selectedRegion,
                  );
                } catch (e) {
                  selectedRegionData = null;
                }
              }
            }

            // Всегда отображаем поле
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
                  child: CustomDropdown<RegionData>.search(
                    closeDropDownOnClearFilterSearch: true,
                    items: regionsList,
                    searchHintText: AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    enabled: true, // Всегда enabled
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
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      return Text(
                        item.name!,
                        style: TextStyle(
                          color: Color(0xff1E2E52),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                        ),
                      );
                    },
                    headerBuilder: (context, selectedItem, enabled) {
                      if (state is GetAllRegionLoading) {
                        return Row(
                          children: [
                            // SizedBox(
                            //   width: 16,
                            //   height: 16,
                            //   child: CircularProgressIndicator(
                            //     strokeWidth: 2,
                            //     valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                            //   ),
                            // ),
                            SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.translate('select_region'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              ),
                            ),
                          ],
                        );
                      }
                      return Text(
                        selectedItem.name ?? AppLocalizations.of(context)!.translate('select_region'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_region'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    excludeSelected: false,
                    initialItem: selectedRegionData,
                    // validator: (value) {
                    //   if (value == null) {
                    //     return AppLocalizations.of(context)!.translate('field_required_project');
                    //   }
                    //   return null;
                    // },
                    onChanged: (value) {
                      if (value != null) {
                        widget.onSelectRegion(value);
                        setState(() {
                          selectedRegionData = value;
                        });
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}