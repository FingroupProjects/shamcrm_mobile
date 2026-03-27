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
    required this.onSelectSources,
    this.selectedSources,
  });

  @override
  State<SourcesMultiSelectWidget> createState() => _SourcesMultiSelectWidgetState();
}

class _SourcesMultiSelectWidgetState extends State<SourcesMultiSelectWidget> {
  List<SourceData> sourcesList = [];
  List<SourceData> selectedSourcesData = [];
  bool allSelected = false; // Добавлено: Флаг для "Выделить всех"

  final TextStyle sourceTextStyle = const TextStyle( // Добавлено: Унифицированный стиль текста
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    context.read<GetAllSourceBloc>().add(GetAllSourceEv()); // Добавлено: Инициализация загрузки источников
  }

  // Добавлено: Функция для выделения/снятия выделения всех источников
  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      if (allSelected) {
        selectedSourcesData = List.from(sourcesList); // Выбираем все
      } else {
        selectedSourcesData = []; // Снимаем выделение
      }
      widget.onSelectSources(selectedSourcesData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<SourceData>>( // Изменено: Обёрнуто в FormField для валидации
      validator: (value) {
        if (selectedSourcesData.isEmpty) {
          return AppLocalizations.of(context)!.translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<SourceData>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('source'),
              style: sourceTextStyle.copyWith( // Изменено: Используем sourceTextStyle с меньшим весом
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8), // Изменено: Увеличен отступ до 8 для соответствия AuthorMultiSelectWidget
            Container(
              decoration: BoxDecoration( // Добавлено: Стилизация бордера с учетом ошибок
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? Colors.red : const Color(0xFFE5E7EB),
                ),
              ),
              child: BlocBuilder<GetAllSourceBloc, GetAllSourceState>(
                builder: (context, state) {
                  if (state is GetAllSourceSuccess) {
                    sourcesList = state.dataSource ?? [];
                    if (widget.selectedSources != null && sourcesList.isNotEmpty) {
                      selectedSourcesData = sourcesList
                          .where((source) => widget.selectedSources!
                              .contains(source.id.toString()))
                          .toList();
                      allSelected = selectedSourcesData.length == sourcesList.length; // Добавлено: Обновление allSelected
                    }
                  }

                  return CustomDropdown<SourceData>.multiSelectSearch(
                    items: sourcesList,
                    initialItems: selectedSourcesData,
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
                      if (sourcesList.indexOf(item) == 0) {
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
                                        style: sourceTextStyle,
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
                      String selectedSourcesNames = selectedSourcesData.isEmpty
                          ? AppLocalizations.of(context)!.translate('select_source')
                          : selectedSourcesData.map((e) => e.name).join(', ');
                      return Text(
                        selectedSourcesNames,
                        style: sourceTextStyle, // Изменено: Используем sourceTextStyle, показываем имена источников
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_source'),
                      style: sourceTextStyle.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    onListChanged: (values) {
                      widget.onSelectSources(values);
                      setState(() {
                        selectedSourcesData = values;
                        allSelected = values.length == sourcesList.length; // Добавлено: Обновление allSelected
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
  Widget _buildListItem(SourceData item, bool isSelected, Function() onItemSelect) {
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
                item.name,
                style: sourceTextStyle,
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