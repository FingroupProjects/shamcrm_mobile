import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/call_bloc/operator_bloc/operator_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/operator_bloc/operator_event.dart';
import 'package:crm_task_manager/bloc/call_bloc/operator_bloc/operator_state.dart';
import 'package:crm_task_manager/models/page_2/operator_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class OperatorMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedOperators;
  final Function(List<Operator>) onSelectOperators;

  const OperatorMultiSelectWidget({
    super.key,
    required this.selectedOperators,
    required this.onSelectOperators,
  });

  @override
  State<OperatorMultiSelectWidget> createState() => _OperatorMultiSelectWidgetState();
}

class _OperatorMultiSelectWidgetState extends State<OperatorMultiSelectWidget> {
  List<Operator> operatorsList = [];
  List<Operator> selectedOperatorsData = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    context.read<OperatorBloc>().add(FetchOperators());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OperatorBloc(ApiService()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('operator'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          const SizedBox(height: 4),
          BlocListener<OperatorBloc, OperatorState>(
            listener: (context, state) {
              if (state is OperatorLoaded) {
                setState(() {
                  operatorsList = state.operators;
                  errorMessage = null;
                  if (widget.selectedOperators != null && operatorsList.isNotEmpty) {
                    selectedOperatorsData = operatorsList
                        .where((operator) => widget.selectedOperators!.contains(operator.id.toString()))
                        .toList();
                  }
                });
              } else if (state is OperatorError) {
                setState(() {
                  errorMessage = state.message;
                });
              }
            },
            child: Column(
              children: [
                CustomDropdown<Operator>.multiSelectSearch(
                  items: operatorsList,
                  initialItems: selectedOperatorsData,
                  searchHintText: AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 400,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: const Color(0xffF4F7FD),
                    expandedFillColor: Colors.white,
                    closedBorder: Border.all(
                      color: const Color(0xffF4F7FD),
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: const Color(0xffF4F7FD),
                      width: 1,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
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
                                border: Border.all(color: const Color(0xff1E2E52), width: 1),
                                color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              item.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              ),
                            ),
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
                    int selectedOperatorsCount = selectedOperatorsData.length;
                    return Text(
                      selectedOperatorsCount == 0
                          ? AppLocalizations.of(context)!.translate('select_operator')
                          : '${AppLocalizations.of(context)!.translate('select_operator')} $selectedOperatorsCount',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_operator'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  onListChanged: (values) {
                    widget.onSelectOperators(values);
                    setState(() {
                      selectedOperatorsData = values;
                    });
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<OperatorBloc>().add(FetchOperators());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Повторить',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}