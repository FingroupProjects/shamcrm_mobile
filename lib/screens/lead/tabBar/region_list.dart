import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/models/region_model.dart';
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
            if (state is GetAllRegionLoading) {
              // return Center(child: CircularProgressIndicator());
            }

            if (state is GetAllRegionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${state.message}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16, // Размер шрифта совпадает с CustomTextField
                      fontWeight: FontWeight.w500, // Жирность текста
                      color: Colors.white, // Цвет текста для читаемости
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        12), // Радиус, как у текстового поля
                  ),
                  backgroundColor:
                      Colors.red, // Цвет фона, как у текстового поля
                  elevation: 3,
                  padding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16), // Паддинг для комфортного восприятия
                      duration: Duration(seconds: 2),
                ),
              );
            }
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SizedBox(height: 8),
                  const Text(
                    'Регион',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xfff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(width: 1, color: Color(0xFFF4F7FD)),
                    ),
                    child: CustomDropdown<RegionData>.search(
                      closeDropDownOnClearFilterSearch: true,
                      items: regionsList,
                      searchHintText: 'Поиск',
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
                        return Text(item.name!);
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem.name ?? 'Выберите регион',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) =>
                          Text('Выберите регион',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              )),
                      excludeSelected: false,
                      initialItem: selectedRegionData,
                      validator: (value) {
                        if (value == null) {
                          return 'Поле обязательно для заполнения';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value != null) {
                          widget.onSelectRegion(value);
                          setState(() {
                            selectedRegionData = value;
                          });
                        }
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
