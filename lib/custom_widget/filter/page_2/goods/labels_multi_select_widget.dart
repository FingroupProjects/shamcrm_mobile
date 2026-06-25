import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/label_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LabelsMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedLabels;
  final Function(List<String>) onSelectLabels;

  const LabelsMultiSelectWidget({
    super.key,
    required this.selectedLabels,
    required this.onSelectLabels,
  });

  @override
  State<LabelsMultiSelectWidget> createState() => _LabelsMultiSelectWidgetState();
}

class _LabelsMultiSelectWidgetState extends State<LabelsMultiSelectWidget> {
  List<Label> labelsList = [];
  List<Label> selectedLabelsData = [];

  @override
  void initState() {
    super.initState();
    context.read<LabelBloc>().add(FetchLabels());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocListener<LabelBloc, LabelState>(
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
              if (state is LabelLoading) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('labels'),
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

              if (state is LabelLoaded) {
                labelsList = state.labels;
                if (widget.selectedLabels != null && labelsList.isNotEmpty) {
                  selectedLabelsData = labelsList
                      .where((label) => widget.selectedLabels!.contains(label.id.toString()))
                      .toList();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('labels'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CustomDropdown<Label>.multiSelectSearch(
                      items: labelsList,
                      initialItems: selectedLabelsData,
                      searchHintText: AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: colors.backgroundSecondary,
                        expandedFillColor: colors.surfaceElevated,
                        closedBorder: Border.all(color: colors.borderSubtle, width: 1),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(color: colors.borderSubtle, width: 1),
                        expandedBorderRadius: BorderRadius.circular(12),
                        listItemDecoration: ListItemDecoration(
                          selectedColor: colors.buttonPrimaryBg.withValues(alpha: 0.15),
                        ),
                      ),
                      listItemBuilder: (context, item, isSelected, onItemSelect) {
                        return ListTile(
                          minTileHeight: 1,
                          minVerticalPadding: 2,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          dense: true,
                          title: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  border: Border.all(color: colors.borderPrimary, width: 1),
                                  color: isSelected ? colors.buttonPrimaryBg : Colors.transparent,
                                ),
                                child: isSelected
                                    ? Icon(Icons.check, color: colors.textInverse, size: 16)
                                    : null,
                              ),
                              const SizedBox(width: 10),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gilroy',
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            onItemSelect();
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                      headerListBuilder: (context, selectedItems, enabled) {
                        final selectedLabelsCount = selectedItems.length;
                        return Text(
                          selectedLabelsCount == 0
                              ? AppLocalizations.of(context)!.translate('select_labels')
                              : '${AppLocalizations.of(context)!.translate('selected_labels')} ($selectedLabelsCount)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: colors.textPrimary,
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        selectedLabelsData.isEmpty
                            ? AppLocalizations.of(context)!.translate('select_labels')
                            : '${AppLocalizations.of(context)!.translate('selected_labels')} (${selectedLabelsData.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: colors.textPrimary,
                        ),
                      ),
                      onListChanged: (values) {
                        final selectedIds = values.map((label) => label.id.toString()).toList();
                        widget.onSelectLabels(selectedIds);
                        setState(() {
                          selectedLabelsData = values;
                        });
                      },
                    ),
                  ],
                );
              }

              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}
