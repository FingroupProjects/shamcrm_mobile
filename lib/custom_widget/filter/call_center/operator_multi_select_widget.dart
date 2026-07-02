import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
  late final OperatorBloc _operatorBloc;
  List<Operator> operatorsList = [];
  List<Operator> selectedOperatorsData = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _operatorBloc = OperatorBloc(ApiService())..add(FetchOperators());
  }

  @override
  void dispose() {
    _operatorBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _operatorBloc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('operator'),
            style: context.appTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
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
                    closedFillColor: context.appColors.fieldBg,
                    expandedFillColor: context.appColors.surfacePrimary,
                    closedBorder: Border.all(
                      color: context.appColors.fieldBorder,
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: context.appColors.fieldBorder,
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
                      tileColor: Colors.transparent,
                      selectedTileColor: Colors.transparent,
                      selected: isSelected,
                      title: Padding(
                        padding: EdgeInsets.zero,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                border: Border.all(color: context.appColors.buttonPrimaryBg, width: 1),
                                color: isSelected ? context.appColors.buttonPrimaryBg : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Icon(Icons.check, color: context.appColors.buttonPrimaryFg, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              item.fullName,
                              style: context.appTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w500,
                                color: context.appColors.textPrimary,
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
                      style: context.appTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_operator'),
                    style: context.appTextStyles.bodySm.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textSecondary,
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
                          style: context.appTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w500,
                            color: context.appColors.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<OperatorBloc>().add(FetchOperators());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.appColors.buttonPrimaryBg,
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
