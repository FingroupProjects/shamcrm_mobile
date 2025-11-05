import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/label/label_state.dart';
import 'package:crm_task_manager/models/page_2/label_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LabelsMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedLabels; // Оставляем как List<String> для label_id
  final Function(List<String>) onSelectLabels; // Изменяем на List<String>

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
    //print('LabelsMultiSelectWidget: Инициализация, загрузка меток');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocListener<LabelBloc, LabelState>(
          listener: (context, state) {
            if (state is LabelError) {
              //print('LabelsMultiSelectWidget: Ошибка загрузки меток: ${state.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.translate(state.message),
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.red,
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
                //print('LabelsMultiSelectWidget: Загрузка меток');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('labels'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52))),
                  ],
                );
              }

              if (state is LabelLoaded) {
                labelsList = state.labels;
                if (widget.selectedLabels != null && labelsList.isNotEmpty) {
                  selectedLabelsData = labelsList
                      .where((label) => widget.selectedLabels!.contains(label.id.toString()))
                      .toList();
                  //print('LabelsMultiSelectWidget: Начальные метки: ${selectedLabelsData.map((e) => e.name).toList()}');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('labels'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(height: 4),
                    CustomDropdown<Label>.multiSelectSearch(
                      items: labelsList,
                      initialItems: selectedLabelsData,
                      searchHintText: AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      decoration: CustomDropdownDecoration(
                        closedFillColor: Color(0xffF4F7FD),
                        expandedFillColor: Colors.white,
                        closedBorder: Border.all(color: Color(0xffF4F7FD), width: 1),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(color: Color(0xffF4F7FD), width: 1),
                        expandedBorderRadius: BorderRadius.circular(12),
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
                                  border: Border.all(color: const Color(0xff1E2E52), width: 1),
                                  color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff1E2E52),
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
      ? AppLocalizations.of(context)!.translate('select_labels') // "Выберите метки"
      : '${AppLocalizations.of(context)!.translate('selected_labels')} ($selectedLabelsCount)', // "Выбраны метки (2)"
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  ),
);

                      },
                     hintBuilder: (context, hint, enabled) => Text(
  selectedLabelsData.isEmpty
      ? AppLocalizations.of(context)!.translate('select_labels')
      : '${AppLocalizations.of(context)!.translate('selected_labels')} (${selectedLabelsData.length})',
  style: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  ),
),

                      onListChanged: (values) {
                        // Передаём список label_id как строки
                        final selectedIds = values.map((label) => label.id.toString()).toList();
                        widget.onSelectLabels(selectedIds);
                        setState(() {
                          selectedLabelsData = values;
                        });
                        //print('LabelsMultiSelectWidget: Выбраны метки (label_id): $selectedIds');
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