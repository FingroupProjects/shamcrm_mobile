import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_state.dart';
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
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<LabelBloc, LabelState>(
        builder: (context, state) {
          // Обновляем данные при успешной загрузке
          if (state is LabelLoaded) {
            List<Label> labelsList = state.labels;

            if (widget.selectedLabel != null && labelsList.isNotEmpty) {
              try {
                selectedLabelData = labelsList.firstWhere(
                  (label) => label.id.toString() == widget.selectedLabel,
                );
              } catch (e) {
                selectedLabelData = null;
              }
            }
          }

          // Всегда отображаем поле
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('label'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                child: CustomDropdown<Label>.search(
                  closeDropDownOnClearFilterSearch: true,
                  items: state is LabelLoaded ? state.labels : [],
                  searchHintText: AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  enabled: true,
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
                        SizedBox(width: 8),
                        Text(
                          item.name,
                          style: TextStyle(
                            color: Color(0xff1E2E52),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ],
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    if (state is LabelLoading) {
                      return Text(
                        AppLocalizations.of(context)!.translate('select_label'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      );
                    }
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
                        SizedBox(width: 8),
                        Text(
                          selectedItem?.name ??
                              AppLocalizations.of(context)!.translate('select_label'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
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
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  excludeSelected: false,
                  initialItem: (state is LabelLoaded && state.labels.contains(selectedLabelData))
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