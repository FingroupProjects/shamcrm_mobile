import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesFunnelMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedFunnels;
  final Function(List<SalesFunnel>) onSelectFunnels;

  const SalesFunnelMultiSelectWidget({
    super.key,
    required this.onSelectFunnels,
    this.selectedFunnels,
  });

  @override
  State<SalesFunnelMultiSelectWidget> createState() =>
      _SalesFunnelMultiSelectWidgetState();
}

class _SalesFunnelMultiSelectWidgetState
    extends State<SalesFunnelMultiSelectWidget> {
  List<SalesFunnel> funnelsList = [];
  List<SalesFunnel> selectedFunnelsData = [];
  bool allSelected = false;

  @override
  void initState() {
    super.initState();
    context.read<SalesFunnelBloc>().add(FetchSalesFunnels());
  }

  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      if (allSelected) {
        selectedFunnelsData = List.from(funnelsList);
      } else {
        selectedFunnelsData = [];
      }
      widget.onSelectFunnels(selectedFunnelsData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final funnelTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    final hintStyle = funnelTextStyle.copyWith(
      fontSize: 14,
      color: context.appColors.textSecondary,
    );
    final borderColor = context.appColors.borderSubtle;

    return FormField<List<SalesFunnel>>(
      validator: (value) {
        if (selectedFunnelsData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<SalesFunnel>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('sales_funnel'),
              style: funnelTextStyle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.appColors.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError
                      ? context.appColors.error
                      : context.appColors.borderSubtle,
                ),
              ),
              child: BlocBuilder<SalesFunnelBloc, SalesFunnelState>(
                builder: (context, state) {
                  if (state is SalesFunnelLoaded) {
                    funnelsList = state.funnels;
                    if (widget.selectedFunnels != null &&
                        funnelsList.isNotEmpty) {
                      selectedFunnelsData = funnelsList
                          .where((funnel) => widget.selectedFunnels!
                              .contains(funnel.id.toString()))
                          .toList();
                      allSelected =
                          selectedFunnelsData.length == funnelsList.length;
                    }
                  }

                  return CustomDropdown<SalesFunnel>.multiSelectSearch(
                    items: funnelsList,
                    initialItems: selectedFunnelsData,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      closedFillColor: context.appColors.fieldBg,
                      expandedFillColor: context.appColors.surfacePrimary,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: context.appColors.borderSubtle,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                      hintStyle: hintStyle,
                      headerStyle: funnelTextStyle,
                      listItemStyle: funnelTextStyle,
                      listItemDecoration: ListItemDecoration(
                        selectedColor: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.14),
                        highlightColor: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.08),
                        splashColor: Colors.transparent,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: context.appColors.backgroundPrimary,
                        textStyle: funnelTextStyle,
                        hintStyle: hintStyle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.appColors.buttonPrimaryBg,
                          ),
                        ),
                      ),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      if (funnelsList.indexOf(item) == 0) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: GestureDetector(
                                onTap: _toggleSelectAll,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: context.appColors.textPrimary,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        color: allSelected
                                            ? context.appColors.buttonPrimaryBg
                                            : Colors.transparent,
                                      ),
                                      child: allSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('select_all'),
                                        style: funnelTextStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              height: 20,
                              color: context.appColors.borderSubtle,
                            ),
                            _buildListItem(item, isSelected, onItemSelect),
                          ],
                        );
                      }
                      return _buildListItem(item, isSelected, onItemSelect);
                    },
                    headerListBuilder: (context, hint, enabled) {
                      final selectedNames = selectedFunnelsData.isEmpty
                          ? AppLocalizations.of(context)!
                              .translate('select_sales_funnel')
                          : selectedFunnelsData.map((e) => e.name).join(', ');
                      return Text(
                        selectedNames,
                        style: funnelTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!
                          .translate('select_sales_funnel'),
                      style: hintStyle,
                    ),
                    onListChanged: (values) {
                      widget.onSelectFunnels(values);
                      setState(() {
                        selectedFunnelsData = values;
                        allSelected = values.length == funnelsList.length;
                      });
                      field.didChange(values);
                    },
                  );
                },
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  field.errorText!,
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildListItem(
    SalesFunnel item,
    bool isSelected,
    Function() onItemSelect,
  ) {
    final funnelTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.appColors.textPrimary,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected
                    ? context.appColors.buttonPrimaryBg
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: funnelTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
