import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/lead/lead_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadStatusEditpWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(LeadStatus) onSelectStatus;
  final String? salesFunnelId; // Новый параметр

  LeadStatusEditpWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
    this.salesFunnelId,
  }) : super(key: key);

  @override
  State<LeadStatusEditpWidget> createState() => _LeadStatusEditpWidgetState();
}

class _LeadStatusEditpWidgetState extends State<LeadStatusEditpWidget> {
  List<LeadStatus> statusList = [];
  LeadStatus? selectedStatusData;

  final TextStyle statusTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    // Добавляем загрузку статусов, если они еще не загружены
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = context.read<LeadBloc>().state;
      if (currentState is! LeadLoaded || currentState.leadStatuses.isEmpty) {
        context.read<LeadBloc>().add(FetchLeadStatuses());
      } else {
        // Если данные уже есть, сразу инициализируем
        _initializeFromState(currentState);
      }
    });
  }

  void _initializeFromState(LeadLoaded state) {
    setState(() {
      statusList = state.leadStatuses;
      if (widget.selectedStatus != null && statusList.isNotEmpty) {
        try {
          selectedStatusData = statusList.firstWhere(
            (status) => status.id.toString() == widget.selectedStatus,
          );
        } catch (e) {
          selectedStatusData = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fieldFill = colors.fieldBg;
    final primaryText = context.adaptiveForegroundOn(fieldFill);
    final hintTextColor = context.adaptiveHintOn(fieldFill, lightAlpha: 0.62);
    final fieldBorder = context.adaptiveBorderOn(fieldFill);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocListener<LeadBloc, LeadState>(
          listener: (context, state) {
            if (state is LeadError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.translate(state.message),
                    style: statusTextStyle.copyWith(color: Colors.white),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.red,
                  elevation: 3,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state is LeadLoaded) {
              setState(() {
                statusList = state.leadStatuses;
                // Сбрасываем текущий статус, если он не входит в новый список
                if (widget.selectedStatus != null && statusList.isNotEmpty) {
                  try {
                    selectedStatusData = statusList.firstWhere(
                      (status) => status.id.toString() == widget.selectedStatus,
                    );
                  } catch (e) {
                    selectedStatusData =
                        null; // Сбрасываем, если статус не найден
                  }
                }
              });
            }
          },
          child: BlocBuilder<LeadBloc, LeadState>(
            builder: (context, state) {
              // Убираем отображение загрузки - всегда показываем поле
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('lead_status'),
                    style: statusTextStyle.copyWith(
                      fontWeight: FontWeight.w400,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: fieldFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomDropdown<LeadStatus>.search(
                      closeDropDownOnClearFilterSearch: true,
                      items: statusList, // Используем локальный список
                      searchHintText:
                          AppLocalizations.of(context)!.translate('search'),
                      overlayHeight: 400,
                      enabled: true, // Всегда включено
                      decoration: CustomDropdownDecoration(
                        closedFillColor: fieldFill,
                        expandedFillColor: colors.surfacePrimary,
                        closedBorder: Border.all(
                          color: fieldBorder,
                          width: 1,
                        ),
                        closedBorderRadius: BorderRadius.circular(12),
                        expandedBorder: Border.all(
                          color: fieldBorder,
                          width: 1,
                        ),
                        expandedBorderRadius: BorderRadius.circular(12),
                        closedSuffixIcon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: primaryText.withValues(alpha: 0.92),
                        ),
                        expandedSuffixIcon: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: primaryText.withValues(alpha: 0.92),
                        ),
                        hintStyle: statusTextStyle.copyWith(
                          fontSize: 14,
                          color: hintTextColor,
                        ),
                        headerStyle: statusTextStyle.copyWith(
                          color: primaryText,
                        ),
                        listItemStyle: statusTextStyle.copyWith(
                          color: primaryText,
                        ),
                        searchFieldDecoration: SearchFieldDecoration(
                          fillColor: fieldFill,
                          hintStyle: statusTextStyle.copyWith(
                            fontSize: 14,
                            color: hintTextColor,
                          ),
                          textStyle: statusTextStyle.copyWith(
                            fontSize: 14,
                            color: primaryText,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: hintTextColor,
                          ),
                          suffixIcon: (onClear) => IconButton(
                            onPressed: onClear,
                            icon: Icon(
                              Icons.close_rounded,
                              color: hintTextColor,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: fieldBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: fieldBorder,
                              width: 1.2,
                            ),
                          ),
                        ),
                        listItemDecoration: ListItemDecoration(
                          selectedColor: colors.surfaceElevated,
                          highlightColor:
                              colors.surfaceElevated.withValues(alpha: 0.72),
                          splashColor:
                              colors.overlay.withValues(alpha: 0),
                        ),
                      ),
                      listItemBuilder:
                          (context, item, isSelected, onItemSelect) {
                        return Text(
                          item.title,
                          style: statusTextStyle.copyWith(
                            color: primaryText,
                          ),
                        );
                      },
                      headerBuilder: (context, selectedItem, enabled) {
                        return Text(
                          selectedItem?.title ??
                              AppLocalizations.of(context)!
                                  .translate('select_status'),
                          style: statusTextStyle.copyWith(
                            color: primaryText,
                          ),
                        );
                      },
                      hintBuilder: (context, hint, enabled) => Text(
                        AppLocalizations.of(context)!
                            .translate('select_status'),
                        style: statusTextStyle.copyWith(
                          fontSize: 14,
                          color: hintTextColor,
                        ),
                      ),
                      excludeSelected: false,
                      initialItem: statusList.contains(selectedStatusData)
                          ? selectedStatusData
                          : null,
                      onChanged: (value) {
                        if (value != null) {
                          widget.onSelectStatus(value);
                          setState(() {
                            selectedStatusData = value;
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
        ),
      ],
    );
  }
}
