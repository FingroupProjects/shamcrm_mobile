import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_bloc.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_event.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_state.dart';
import 'package:crm_task_manager/models/LeadStatusForFilter.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadStatusForFilterMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedLeadStatuses;
  final Function(List<LeadStatusForFilter>) onSelectStatuses;

  LeadStatusForFilterMultiSelectWidget({
    super.key,
    required this.onSelectStatuses,
    this.selectedLeadStatuses,
  });

  @override
  State<LeadStatusForFilterMultiSelectWidget> createState() => _LeadStatusForFilterMultiSelectWidgetState();
}

class _LeadStatusForFilterMultiSelectWidgetState extends State<LeadStatusForFilterMultiSelectWidget> {
  List<LeadStatusForFilter> statusList = [];
  List<LeadStatusForFilter> selectedStatusesData = [];
  bool allSelected = false; // Добавлено: Флаг для "Выделить всех"

  final TextStyle statusTextStyle = const TextStyle( // Добавлено: Унифицированный стиль текста
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    context.read<LeadStatusForFilterBloc>().add(FetchLeadStatusForFilter()); // Без изменений: Инициализация загрузки статусов
  }

  // Добавлено: Функция для выделения/снятия выделения всех статусов
  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      if (allSelected) {
        selectedStatusesData = List.from(statusList); // Выбираем все
      } else {
        selectedStatusesData = []; // Снимаем выделение
      }
      widget.onSelectStatuses(selectedStatusesData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<LeadStatusForFilter>>( // Изменено: Обёрнуто в FormField для валидации
      validator: (value) {
        if (selectedStatusesData.isEmpty) {
          return AppLocalizations.of(context)!.translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<LeadStatusForFilter>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('status'),
              style: statusTextStyle.copyWith( // Изменено: Используем statusTextStyle с меньшим весом
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8), // Изменено: Увеличен отступ до 8
            Container(
              decoration: BoxDecoration( // Добавлено: Стилизация бордера с учетом ошибок
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? Colors.red : const Color(0xFFE5E7EB),
                ),
              ),
              child: BlocBuilder<LeadStatusForFilterBloc, LeadStatusForFilterState>(
                builder: (context, state) {
                  if (state is LeadStatusForFilterLoaded) {
                    statusList = state.leadStatusForFilter;
                    if (widget.selectedLeadStatuses != null && statusList.isNotEmpty) {
                      selectedStatusesData = statusList
                          .where((status) => widget.selectedLeadStatuses!.contains(status.id.toString()))
                          .toList();
                      allSelected = selectedStatusesData.length == statusList.length; // Добавлено: Обновление allSelected
                    }
                  }

                  return CustomDropdown<LeadStatusForFilter>.multiSelectSearch(
                    items: statusList,
                    initialItems: selectedStatusesData,
                    searchHintText: AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration( // Изменено: Унифицированы стили декорации
                      closedFillColor: const Color(0xffF4F7FD),
                      expandedFillColor: Colors.white,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                    ),
                    listItemBuilder: (context, item, isSelected, onItemSelect) {
                      // Добавлено: Опция "Выделить всех" как первый элемент
                      if (statusList.indexOf(item) == 0) {
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
                                            color: const Color(0xff1E2E52),
                                            width: 1),
                                        borderRadius: BorderRadius.circular(4),
                                        color: allSelected
                                            ? const Color(0xff1E2E52)
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
                                        AppLocalizations.of(context)!.translate('select_all'),
                                        style: statusTextStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                                height: 20,
                                color: const Color(0xFFE5E7EB)), // Добавлено: Разделитель для "Выделить всех"
                            _buildListItem(item, isSelected, onItemSelect),
                          ],
                        );
                      }
                      return _buildListItem(item, isSelected, onItemSelect); // Изменено: Используем кастомный _buildListItem
                    },
                    headerListBuilder: (context, hint, enabled) {
                      String selectedStatusesNames = selectedStatusesData.isEmpty
                          ? AppLocalizations.of(context)!.translate('select_status')
                          : selectedStatusesData.map((e) => e.title).join(', ');
                      return Text(
                        selectedStatusesNames,
                        style: statusTextStyle, // Изменено: Используем statusTextStyle, показываем имена статусов
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_status'),
                      style: statusTextStyle.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    onListChanged: (values) {
                      widget.onSelectStatuses(values);
                      setState(() {
                        selectedStatusesData = values;
                        allSelected = values.length == statusList.length; // Добавлено: Обновление allSelected
                      });
                      field.didChange(values); // Добавлено: Обновление состояния FormField
                    },
                  );
                },
              ),
            ),
            if (field.hasError) // Добавлено: Отображение текста ошибки
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 0),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Добавлено: Кастомный построитель элементов списка для соответствия AuthorMultiSelectWidget
  Widget _buildListItem(LeadStatusForFilter item, bool isSelected, Function() onItemSelect) {
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
                  color: const Color(0xff1E2E52),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
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
                item.title,
                style: statusTextStyle,
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