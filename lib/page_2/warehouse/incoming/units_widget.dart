import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/units_bloc/units_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/units_bloc/units_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/units_bloc/units_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/measure_unit_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UnitsWidget extends StatefulWidget {
  final String? selectedUnit;
  final ValueChanged<String?> onChanged;

  UnitsWidget({required this.selectedUnit, required this.onChanged});

  @override
  _UnitsWidgetState createState() => _UnitsWidgetState();
}

class _UnitsWidgetState extends State<UnitsWidget> {
  MeasureUnitModel? selectedUnitData;
  String? _autoSelectedUnitId;

  @override
  void initState() {
    super.initState();
    context.read<UnitsBloc>().add(FetchUnits());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocListener<UnitsBloc, UnitsState>(
      listener: (context, state) {
        if (state is UnitsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.surfacePrimary,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: colors.error,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<UnitsBloc, UnitsState>(
        builder: (context, state) {
          final isLoading = state is UnitsLoading;

          if (state is UnitsLoaded) {
            List<MeasureUnitModel> unitsList = state.unitsList;

            if (widget.selectedUnit != null && unitsList.isNotEmpty) {
              try {
                selectedUnitData = unitsList.firstWhere(
                  (unit) => unit.id.toString() == widget.selectedUnit,
                );
              } catch (e) {
                selectedUnitData = null;
              }
            }

            if (unitsList.length == 1 &&
                (widget.selectedUnit == null || selectedUnitData == null) &&
                _autoSelectedUnitId != unitsList.first.id.toString()) {
              final singleUnit = unitsList.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                widget.onChanged(singleUnit.id.toString());
                setState(() {
                  selectedUnitData = singleUnit;
                  _autoSelectedUnitId = singleUnit.id.toString();
                });
              });
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('unit'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                child: CustomDropdown<MeasureUnitModel>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: state is UnitsLoaded ? state.unitsList : [],
                  searchHintText:
                      AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: !isLoading,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: colors.fieldBg,
                    expandedFillColor: colors.surfacePrimary,
                    closedBorder: Border.all(
                      color: colors.borderSubtle,
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: colors.borderSubtle,
                      width: 1,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    if (isLoading) {
                      return Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.buttonPrimaryBg),
                          ),
                        ),
                      );
                    }
                    return Text(
                      selectedItem.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textPrimary,
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) {
                    if (isLoading) {
                      return Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.buttonPrimaryBg),
                          ),
                        ),
                      );
                    }
                    return Text(
                      AppLocalizations.of(context)!.translate('select_unit'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textPrimary,
                      ),
                    );
                  },
                  noResultFoundBuilder: (context, text) {
                    if (isLoading) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colors.buttonPrimaryBg),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          AppLocalizations.of(context)!.translate('no_results'),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                  excludeSelected: false,
                  initialItem: (state is UnitsLoaded &&
                          state.unitsList.contains(selectedUnitData))
                      ? selectedUnitData
                      : null,
                  validator: (value) {
                    if (value == null) {
                      return AppLocalizations.of(context)!
                          .translate('field_required_project');
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value != null) {
                      widget.onChanged(value.id.toString());
                      setState(() {
                        selectedUnitData = value;
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
    );
  }
}
