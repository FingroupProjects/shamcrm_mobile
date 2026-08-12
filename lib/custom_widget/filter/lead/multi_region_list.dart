import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/lead/region_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegionsMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedRegions;
  final Function(List<RegionData>) onSelectRegions;

  const RegionsMultiSelectWidget({
    super.key,
    required this.onSelectRegions,
    this.selectedRegions,
  });

  @override
  State<RegionsMultiSelectWidget> createState() =>
      _RegionsMultiSelectWidgetState();
}

class _RegionsMultiSelectWidgetState extends State<RegionsMultiSelectWidget> {
  List<RegionData> regionsList = [];
  List<RegionData> selectedRegionsData = [];
  bool allSelected = false; // Добавлено: Флаг для "Выделить всех"

  @override
  void initState() {
    super.initState();
    context
        .read<GetAllRegionBloc>()
        .add(GetAllRegionEv()); // Добавлено: Инициализация загрузки регионов
  }

  // Добавлено: Функция для выделения/снятия выделения всех регионов
  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      if (allSelected) {
        selectedRegionsData = List.from(regionsList); // Выбираем все
      } else {
        selectedRegionsData = []; // Снимаем выделение
      }
      widget.onSelectRegions(selectedRegionsData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final regionTextStyle = context.appTextStyles.bodyMd.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );
    final hintStyle = regionTextStyle.copyWith(
      color: context.appColors.textSecondary,
    );
    final surfaceColor =
        context.appColors.surfacePrimary.withValues(alpha: 0.78);
    final borderColor = context.appColors.borderSubtle.withValues(alpha: 0.36);
    final overlayColor = context.appColors.surfacePrimary;

    return FormField<List<RegionData>>(
      // Изменено: Обёрнуто в FormField для валидации
      validator: (value) {
        if (selectedRegionsData.isEmpty) {
          return AppLocalizations.of(context)!
              .translate('field_required_project');
        }
        return null;
      },
      builder: (FormFieldState<List<RegionData>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('region'),
              style: regionTextStyle.copyWith(
                // Изменено: Используем regionTextStyle с меньшим весом
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
            const SizedBox(
                height:
                    8), // Изменено: Увеличен отступ до 8 для соответствия AuthorMultiSelectWidget
            Container(
              decoration: BoxDecoration(
                // Добавлено: Стилизация бордера с учетом ошибок
                color: surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? Colors.red : borderColor,
                ),
              ),
              child: BlocBuilder<GetAllRegionBloc, GetAllRegionState>(
                builder: (context, state) {
                  if (state is GetAllRegionSuccess) {
                    regionsList = state.dataRegion.result ?? [];
                    if (widget.selectedRegions != null &&
                        regionsList.isNotEmpty) {
                      selectedRegionsData = regionsList
                          .where((region) => widget.selectedRegions!
                              .contains(region.id.toString()))
                          .toList();
                      allSelected = selectedRegionsData.length ==
                          regionsList
                              .length; // Добавлено: Обновление allSelected
                    }
                  }

                  return CustomDropdown<RegionData>.multiSelectSearch(
                    items: regionsList,
                    initialItems: selectedRegionsData,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: CustomDropdownDecoration(
                      // Изменено: Унифицированы стили декорации
                      closedFillColor: surfaceColor,
                      expandedFillColor: overlayColor,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(18),
                      expandedBorder: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(18),
                      hintStyle: hintStyle,
                      headerStyle: regionTextStyle,
                      listItemStyle: regionTextStyle,
                      listItemDecoration: ListItemDecoration(
                        selectedColor: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.14),
                        highlightColor: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.08),
                        splashColor: Colors.transparent,
                      ),
                      searchFieldDecoration: SearchFieldDecoration(
                        fillColor: context.appColors.fieldBg,
                        textStyle: regionTextStyle,
                        hintStyle: hintStyle,
                        prefixIcon: Icon(
                          Icons.search,
                          color: context.appColors.textSecondary,
                        ),
                        suffixIcon: (onClear) => IconButton(
                          onPressed: onClear,
                          icon: Icon(
                            Icons.close_rounded,
                            color: context.appColors.textSecondary,
                          ),
                        ),
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
                      // Добавлено: Опция "Выделить всех" как первый элемент
                      if (regionsList.indexOf(item) == 0) {
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
                                            color: context
                                                .appColors.buttonPrimaryBg,
                                            width: 1),
                                        borderRadius: BorderRadius.circular(4),
                                        color: allSelected
                                            ? context.appColors.buttonPrimaryBg
                                            : Colors.transparent,
                                      ),
                                      child: allSelected
                                          ? Icon(
                                              Icons.check,
                                              color: context
                                                  .appColors.buttonPrimaryFg,
                                              size: 14,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('select_all'),
                                        style: regionTextStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                                height: 20,
                                color:
                                    borderColor), // Добавлено: Разделитель для "Выделить всех"
                            _buildListItem(item, isSelected, onItemSelect),
                          ],
                        );
                      }
                      return _buildListItem(item, isSelected,
                          onItemSelect); // Изменено: Используем кастомный _buildListItem
                    },
                    headerListBuilder: (context, hint, enabled) {
                      String selectedRegionsNames = selectedRegionsData.isEmpty
                          ? AppLocalizations.of(context)!
                              .translate('select_region')
                          : selectedRegionsData.map((e) => e.name).join(', ');
                      return Text(
                        selectedRegionsNames,
                        style:
                            regionTextStyle, // Изменено: Используем regionTextStyle, показываем имена регионов
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    hintBuilder: (context, hint, enabled) => Text(
                      AppLocalizations.of(context)!.translate('select_region'),
                      style: hintStyle.copyWith(fontSize: 14),
                    ),
                    onListChanged: (values) {
                      widget.onSelectRegions(values);
                      setState(() {
                        selectedRegionsData = values;
                        allSelected = values.length ==
                            regionsList
                                .length; // Добавлено: Обновление allSelected
                      });
                      field.didChange(
                          values); // Добавлено: Обновление состояния FormField
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
  Widget _buildListItem(
      RegionData item, bool isSelected, Function() onItemSelect) {
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
                  color: context.appColors.buttonPrimaryBg,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected
                    ? context.appColors.buttonPrimaryBg
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: context.appColors.buttonPrimaryFg,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: context.appTextStyles.bodyMd.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
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
