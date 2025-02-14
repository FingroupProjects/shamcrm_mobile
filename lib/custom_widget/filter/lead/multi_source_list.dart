import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/source_list/source_bloc.dart';
import 'package:crm_task_manager/models/source_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SourcesMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedSources;
  final Function(List<SourceData>) onSelectSources;

  SourcesMultiSelectWidget({
    super.key,
    required this.selectedSources,
    required this.onSelectSources,
  });

  @override
  State<SourcesMultiSelectWidget> createState() => _SourcesMultiSelectWidgetState();
}

class _SourcesMultiSelectWidgetState extends State<SourcesMultiSelectWidget> {
  List<SourceData> sourcesList = [];
  List<SourceData> selectedSourcesData = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<GetAllSourceBloc, GetAllSourceState>(
          builder: (context, state) {
            if (state is GetAllSourceError) {
              return Text(state.message);
            }
            if (state is GetAllSourceSuccess) {
              sourcesList = state.dataSource ?? [];
              if (widget.selectedSources != null && sourcesList.isNotEmpty) {
                selectedSourcesData = sourcesList
                    .where((source) => widget.selectedSources!.contains(source.id.toString()))
                    .toList();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('source'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xfff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    child: CustomDropdown<SourceData>.multiSelectSearch(
                      items: sourcesList,
                      initialItems: selectedSourcesData,
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
                        int selecteRegionsCount = selectedSourcesData.length;

                        return Text(
                          selecteRegionsCount == 0
                              ? AppLocalizations.of(context)!
                                  .translate('select_source')
                              : '${AppLocalizations.of(context)!.translate('select_source')} $selecteRegionsCount',
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
                              .translate('select_source'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          )),
                      onListChanged: (values) {
                        widget.onSelectSources(values);
                        setState(() {
                          selectedSourcesData = values;
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
