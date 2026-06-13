import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegionRadioGroupWidget extends StatefulWidget {
  final String? selectedRegion;
  final Function(RegionData) onSelectRegion;

  const RegionRadioGroupWidget({
    super.key,
    required this.onSelectRegion,
    this.selectedRegion,
  });

  @override
  State<RegionRadioGroupWidget> createState() => _RegionRadioGroupWidgetState();
}

class _RegionRadioGroupWidgetState extends State<RegionRadioGroupWidget> {
  final ApiService _apiService = ApiService();
  List<RegionData> regionsList = [];
  RegionData? selectedRegionData;

  @override
  void initState() {
    super.initState();
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());
  }

  Future<List<RegionData>> _searchRegions(String query) async {
    final response = await _apiService.getAllRegion(search: query);
    return response.result ?? <RegionData>[];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fieldFill = colors.fieldBg;
    final primaryText = context.adaptiveForegroundOn(fieldFill);
    final hintTextColor = context.adaptiveHintOn(fieldFill, lightAlpha: 0.62);
    final fieldBorder = context.adaptiveBorderOn(fieldFill);
    final dropdownFill = colors.surfacePrimary;
    final dropdownSelected = colors.surfaceElevated;
    final dropdownIcon = primaryText.withValues(alpha: 0.92);

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
                        color: context.appColors.textInverse,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: context.appColors.error,
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
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  child: CustomDropdown<RegionData>.searchRequest(
                    futureRequest: _searchRegions,
                    futureRequestDelay: const Duration(milliseconds: 350),
                    closeDropDownOnClearFilterSearch: true,
                    items: regionsList,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    enabled: true, // Всегда enabled
                    decoration: CustomDropdownDecoration(
                      closedFillColor: fieldFill,
                      expandedFillColor: dropdownFill,
                      closedBorder: Border.all(
                        color: fieldBorder,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: fieldBorder,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                      closedSuffixIcon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: dropdownIcon),
                      expandedSuffixIcon: Icon(Icons.keyboard_arrow_up_rounded,
                          color: dropdownIcon),
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: hintTextColor,
                      ),
                      headerStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: primaryText,
                      ),
                      listItemStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: primaryText,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: fieldFill,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: hintTextColor,
                        ),
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: primaryText,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: hintTextColor,
                        ),
                        suffixIcon: (onClear) => IconButton(
                          onPressed: onClear,
                          icon: Icon(Icons.close_rounded, color: hintTextColor),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: fieldBorder, width: 1.2),
                        ),
                      ),
                      listItemDecoration: ListItemDecoration(
                        selectedColor: dropdownSelected,
                        highlightColor:
                            dropdownSelected.withValues(alpha: 0.72),
                        splashColor:
                            context.appColors.overlay.withValues(alpha: 0),
                      ),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      return Text(
                        item.name,
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                              AppLocalizations.of(context)!
                                  .translate('select_region'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: hintTextColor,
                              ),
                            ),
                          ],
                        );
                      }
                      return Text(
                        selectedItem.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: primaryText,
                        ),
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_region'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: hintTextColor,
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
