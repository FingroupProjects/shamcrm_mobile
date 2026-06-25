import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/label_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LabelWidget extends StatefulWidget {
  final String? selectedLabel;
  final ValueChanged<String?> onChanged;

  LabelWidget({required this.selectedLabel, required this.onChanged});

  @override
  _LabelWidgetState createState() => _LabelWidgetState();
}

class _LabelWidgetState extends State<LabelWidget> {
  Label? selectedLabelData;

  @override
  void initState() {
    super.initState();
    context.read<LabelBloc>().add(FetchLabels());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocListener<LabelBloc, LabelState>(
      listener: (context, state) {
        if (state is LabelError) {
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
      child: BlocBuilder<LabelBloc, LabelState>(
        builder: (context, state) {
          List<Label> labelsList = state is LabelLoaded ? state.labels : [];

          if (state is LabelLoaded && widget.selectedLabel != null && labelsList.isNotEmpty) {
            try {
              selectedLabelData = labelsList.firstWhere(
                (label) => label.id.toString() == widget.selectedLabel,
              );
            } catch (e) {
              selectedLabelData = null;
            }
          }

          if (state is LabelLoading) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('label'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Center(child: CircularProgressIndicator(color: colors.buttonPrimaryBg)),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('label'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                child: CustomDropdown<Label>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: labelsList,
                  searchHintText: AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: true,
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
                    return Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Color(int.parse('0xff${item.color}')),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ],
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    return Row(
                      children: [
                        if (selectedItem != null)
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(int.parse('0xff${selectedItem.color}')),
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          selectedItem?.name ??
                              AppLocalizations.of(context)!.translate('select_label'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_label'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary,
                    ),
                  ),
                  excludeSelected: false,
                  initialItem: selectedLabelData != null && labelsList.contains(selectedLabelData)
                      ? selectedLabelData
                      : null,
                  onChanged: (value) {
                    if (value != null) {
                      widget.onChanged(value.id.toString());
                      setState(() {
                        selectedLabelData = value;
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
