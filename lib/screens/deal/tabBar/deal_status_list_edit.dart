import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DealStatusEditWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(DealStatus) onSelectStatus;
  final Function(List<int>)? onSelectMultipleStatuses;
  final List<DealStatusById>? dealStatuses;
  final bool hasError; // для показа красной рамки и текста при ошибке

  DealStatusEditWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
    this.onSelectMultipleStatuses,
    this.dealStatuses,
    this.hasError = false,
  }) : super(key: key);

  @override
  State<DealStatusEditWidget> createState() => _DealStatusEditWidgetState();
}

class _DealStatusEditWidgetState extends State<DealStatusEditWidget> {
  List<DealStatus> statusList = [];
  DealStatus? selectedStatusData;
  List<DealStatus> selectedStatusesList = [];
  bool isMultiSelectEnabled = false;
  bool allSelected = false;
  bool isLoadingStatuses = false;

  Set<int> _lastInitializedIds = {};

  @override
  void initState() {
    super.initState();
    _loadMultiSelectSetting();
  }

  @override
  void didUpdateWidget(DealStatusEditWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldIds = oldWidget.dealStatuses?.map((s) => s.id).toSet() ?? {};
    final newIds = widget.dealStatuses?.map((s) => s.id).toSet() ?? {};

    if (!oldIds.containsAll(newIds) || !newIds.containsAll(oldIds)) {
      //print('🔄 DealStatusEditWidget: dealStatuses изменились, переинициализация');
      _lastInitializedIds.clear();
      if (statusList.isNotEmpty) {
        _initializeSelectedStatuses();
      }
    }
  }

  Future<void> _loadMultiSelectSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('change_deal_to_multiple_statuses') ?? false;

    //print('DealStatusEditWidget: change_deal_to_multiple_statuses = $value');
    //print('DealStatusEditWidget: Режим = ${value ? "МУЛЬТИВЫБОР" : "ОДИНОЧНЫЙ"}');

    if (mounted) {
      setState(() {
        isMultiSelectEnabled = value;
      });
      // ✅ НОВОЕ: Загружаем статусы с правильным эндпоинтом
      await _loadDealStatuses();
    }
  }

  // ✅ НОВОЕ: Метод для загрузки статусов напрямую из API
  Future<void> _loadDealStatuses() async {
    if (isLoadingStatuses) return;

    setState(() {
      isLoadingStatuses = true;
    });

    try {
      //print('📡 Загрузка статусов: includeAll = $isMultiSelectEnabled');

      // ✅ Получаем salesFunnelId из DealBloc
      final dealBloc = context.read<DealBloc>();
      final salesFunnelId = dealBloc.currentSalesFunnelId;

      // Используем правильный эндпоинт в зависимости от настройки
      final statuses = await ApiService().getDealStatuses(
        includeAll: isMultiSelectEnabled,
        salesFunnelId: salesFunnelId,
      );

      //print('✅ Загружено ${statuses.length} статусов');

      if (mounted) {
        setState(() {
          statusList = statuses;
          isLoadingStatuses = false;
        });

        // После загрузки инициализируем выбранные статусы
        _initializeSelectedStatuses();
      }
    } catch (e) {
      //print('❌ Ошибка загрузки статусов: $e');
      if (mounted) {
        setState(() {
          isLoadingStatuses = false;
        });

        // Показываем ошибку пользователю
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка загрузки статусов',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: context.appColors.textInverse,
              ),
            ),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

  void _initializeSelectedStatuses() {
    if (statusList.isEmpty) {
      //print('❌ DealStatusEditWidget: statusList пустой, инициализация невозможна');
      return;
    }

    //print('🔍 DealStatusEditWidget: Начало инициализации');
    //print('   - widget.selectedStatus = ${widget.selectedStatus}');
    //print('   - widget.dealStatuses = ${widget.dealStatuses?.map((s) => s.id).toList()}');
    //print('   - statusList IDs = ${statusList.map((s) => s.id).toList()}');

    List<int> targetIds = [];

    // ✅ ПРИОРИТЕТ 1: Используем dealStatuses (массив от бэкенда)
    if (widget.dealStatuses != null && widget.dealStatuses!.isNotEmpty) {
      //print('✅ Используем dealStatuses от бэкенда');
      targetIds = isMultiSelectEnabled
          ? widget.dealStatuses!.map((s) => s.id).toList()
          : [widget.dealStatuses!.first.id];
    }
    // ✅ ПРИОРИТЕТ 2: Парсим selectedStatus (строка с ID через запятую)
    else if (widget.selectedStatus != null &&
        widget.selectedStatus!.isNotEmpty) {
      //print('✅ Используем selectedStatus');
      targetIds = widget.selectedStatus!
          .split(',')
          .map((id) => int.tryParse(id.trim()))
          .where((id) => id != null)
          .cast<int>()
          .toList();
    }
    // ✅ ПРИОРИТЕТ 3: Если только один статус в списке, выбираем его
    else if (statusList.length == 1) {
      //print('✅ Автовыбор единственного статуса');
      targetIds = [statusList[0].id];
    }

    // ✅ ПРОВЕРКА: Нужна ли повторная инициализация?
    final targetIdsSet = targetIds.toSet();
    if (_lastInitializedIds.containsAll(targetIdsSet) &&
        targetIdsSet.containsAll(_lastInitializedIds)) {
      //print('⭐️ Инициализация уже выполнена для этих ID, пропускаем');
      return;
    }

    if (targetIds.isNotEmpty) {
      final newSelectedList =
          statusList.where((status) => targetIds.contains(status.id)).toList();

      if (newSelectedList.isNotEmpty) {
        setState(() {
          selectedStatusesList = newSelectedList;
          selectedStatusData = newSelectedList.first;
          allSelected = newSelectedList.length == statusList.length;
          _lastInitializedIds = targetIds.toSet();
        });

        //print('✅ Инициализировано ${selectedStatusesList.length} статус(ов)');
        //print('✅ Выбранные ID: ${selectedStatusesList.map((s) => s.id).toList()}');

        // ✅ ВАЖНО: Уведомляем родителя о выборе
        widget.onSelectStatus(newSelectedList.first);
        if (widget.onSelectMultipleStatuses != null) {
          widget.onSelectMultipleStatuses!(
            isMultiSelectEnabled ? targetIds : [newSelectedList.first.id],
          );
        }
      } else {
        //print('❌ Не найдены статусы с ID: $targetIds');
        //print('   Доступные ID: ${statusList.map((s) => s.id).toList()}');
      }
    } else {
      //print('⚠️ targetIds пустой, выбор не установлен');
    }
  }

  void _toggleSelectAll() {
    setState(() {
      allSelected = !allSelected;
      if (allSelected) {
        selectedStatusesList = List.from(statusList);
      } else {
        selectedStatusesList = [];
      }

      if (selectedStatusesList.isNotEmpty) {
        widget.onSelectStatus(selectedStatusesList.first);
        if (widget.onSelectMultipleStatuses != null) {
          widget.onSelectMultipleStatuses!(
              selectedStatusesList.map((s) => s.id).toList());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showError = widget.hasError;
    final Color borderColor =
        showError ? context.appColors.error : context.appColors.borderSubtle;
    final statusTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: context.appColors.textPrimary,
    );
    final dropdownItemTextStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: context.appColors.textPrimary,
    );
    final searchFieldDecoration = SearchFieldDecoration(
      fillColor: context.appColors.fieldBg,
      hintStyle: context.appTextStyles.bodyMd.copyWith(
        fontWeight: FontWeight.w500,
        color: context.appColors.fieldHint,
      ),
      textStyle: context.appTextStyles.bodyMd.copyWith(
        fontWeight: FontWeight.w500,
        color: context.appColors.textPrimary,
      ),
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
        borderSide: BorderSide(
          color: context.appColors.fieldBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: context.appColors.buttonPrimaryBg,
          width: 1.2,
        ),
      ),
    );
    final listItemDecoration = ListItemDecoration(
      splashColor: Colors.transparent,
      highlightColor: context.appColors.surfaceElevated,
      selectedColor: context.appColors.surfaceElevated,
      selectedIconColor: context.appColors.buttonPrimaryFg,
      selectedIconBorder: BorderSide(
        color: context.appColors.buttonPrimaryBg,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('deal_statuses'),
          style: statusTextStyle,
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: context.appColors.fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: borderColor,
            ),
          ),
          child: isMultiSelectEnabled
              ? _buildMultiSelectDropdown(
                  dropdownItemTextStyle,
                  searchFieldDecoration,
                  listItemDecoration,
                )
              : _buildSingleSelectDropdown(
                  dropdownItemTextStyle,
                  searchFieldDecoration,
                  listItemDecoration,
                ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              AppLocalizations.of(context)!.translate('field_required'),
              style: TextStyle(
                color: context.appColors.error,
                fontSize: 12,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleSelectDropdown(
    TextStyle dropdownItemTextStyle,
    SearchFieldDecoration searchFieldDecoration,
    ListItemDecoration listItemDecoration,
  ) {
    return CustomDropdown<DealStatus>.search(
      closeDropDownOnClearFilterSearch: true,
      items: statusList,
      searchHintText: AppLocalizations.of(context)!.translate('search'),
      overlayHeight: 400,
      enabled: !isLoadingStatuses,
      decoration: CustomDropdownDecoration(
        closedFillColor: context.appColors.fieldBg,
        expandedFillColor: context.appColors.surfacePrimary,
        closedBorder: Border.all(
          color: widget.hasError
              ? context.appColors.error
              : Colors.transparent,
          width: 1,
        ),
        closedBorderRadius: BorderRadius.circular(12),
        expandedBorder: Border.all(
          color: widget.hasError
              ? context.appColors.error
              : context.appColors.borderSubtle,
          width: 1,
        ),
        expandedBorderRadius: BorderRadius.circular(12),
        hintStyle: dropdownItemTextStyle.copyWith(
          color: context.appColors.fieldHint,
        ),
        headerStyle: dropdownItemTextStyle,
        listItemStyle: dropdownItemTextStyle,
        searchFieldDecoration: searchFieldDecoration,
        listItemDecoration: listItemDecoration,
      ),
      listItemBuilder: (context, item, isSelected, onItemSelect) {
        return Text(
          item.title,
          style: dropdownItemTextStyle,
        );
      },
      headerBuilder: (context, selectedItem, enabled) {
        if (isLoadingStatuses) {
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    context.appColors.buttonPrimaryBg),
              ),
            ),
          );
        }
        return Text(
          selectedItem.title,
          style: dropdownItemTextStyle,
        );
      },
      hintBuilder: (context, hint, enabled) {
        if (isLoadingStatuses) {
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    context.appColors.buttonPrimaryBg),
              ),
            ),
          );
        }
        return Text(
          AppLocalizations.of(context)!.translate('select_status'),
          style: dropdownItemTextStyle.copyWith(
            color: context.appColors.fieldHint,
          ),
        );
      },
      noResultFoundBuilder: (context, text) {
        if (isLoadingStatuses) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    context.appColors.buttonPrimaryBg),
              ),
            ),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              AppLocalizations.of(context)!.translate('no_results'),
              style: dropdownItemTextStyle.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
      },
      excludeSelected: false,
      initialItem: selectedStatusData,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            selectedStatusData = value;
            selectedStatusesList = [value];
          });
          widget.onSelectStatus(value);
          if (widget.onSelectMultipleStatuses != null) {
            widget.onSelectMultipleStatuses!([value.id]);
          }
          FocusScope.of(context).unfocus();
        }
      },
    );
  }

  Widget _buildMultiSelectDropdown(
    TextStyle dropdownItemTextStyle,
    SearchFieldDecoration searchFieldDecoration,
    ListItemDecoration listItemDecoration,
  ) {
    //print('📋 Рендер мультивыбора');
    //print('   - statusList: ${statusList.length} элементов');
    //print('   - selectedStatusesList: ${selectedStatusesList.length} элементов');

    //print('   - selectedStatusesList IDs: ${selectedStatusesList.map((s) => s.id).toList()}');

    return CustomDropdown<DealStatus>.multiSelectSearch(
      items: statusList,
      initialItems: selectedStatusesList,
      searchHintText: AppLocalizations.of(context)!.translate('search'),
      overlayHeight: 400,
      enabled: !isLoadingStatuses,
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
        hintStyle: dropdownItemTextStyle.copyWith(
          color: context.appColors.fieldHint,
        ),
        headerStyle: dropdownItemTextStyle,
        listItemStyle: dropdownItemTextStyle,
        searchFieldDecoration: searchFieldDecoration,
        listItemDecoration: listItemDecoration,
      ),
      listItemBuilder: (context, item, isSelected, onItemSelect) {
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
                            color: context.appColors.textPrimary,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: allSelected
                              ? context.appColors.buttonPrimaryBg
                              : Colors.transparent,
                        ),
                        child: allSelected
                            ? Icon(
                                Icons.check,
                                color: context.appColors.textInverse,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.translate('select_all'),
                          style: dropdownItemTextStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 20, color: context.appColors.borderSubtle),
              _buildListItem(
                item,
                isSelected,
                onItemSelect,
                dropdownItemTextStyle,
              ),
            ],
          );
        }
        return _buildListItem(
          item,
          isSelected,
          onItemSelect,
          dropdownItemTextStyle,
        );
      },
      headerListBuilder: (context, selectedItems, enabled) {
        if (isLoadingStatuses) {
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    context.appColors.buttonPrimaryBg),
              ),
            ),
          );
        }
        if (selectedItems.isEmpty) {
          return Text(
            AppLocalizations.of(context)!.translate('select_status'),
            style: dropdownItemTextStyle,
          );
        }

        String statusNames = selectedItems.map((e) => e.title).join(', ');

        return Text(
          statusNames,
          style: dropdownItemTextStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
      hintBuilder: (context, hint, enabled) {
        if (isLoadingStatuses) {
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    context.appColors.buttonPrimaryBg),
              ),
            ),
          );
        }
        return Text(
          AppLocalizations.of(context)!.translate('select_status'),
          style: dropdownItemTextStyle.copyWith(
            color: context.appColors.fieldHint,
          ),
        );
      },
      noResultFoundBuilder: (context, text) {
        if (isLoadingStatuses) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    context.appColors.buttonPrimaryBg),
              ),
            ),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              AppLocalizations.of(context)!.translate('no_results'),
              style: dropdownItemTextStyle.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
      },
      onListChanged: (value) {
        //print('✏️ Выбрано статусов: ${value.length}');

        //print('✏️ onListChanged вызван: ${value.length} статусов');

        // ✅ КРИТИЧНО: Проверяем, действительно ли изменились данные
        final newIds = value.map((s) => s.id).toSet();
        final currentIds = selectedStatusesList.map((s) => s.id).toSet();

        // Если списки идентичны, игнорируем
        if (newIds.length == currentIds.length &&
            newIds.containsAll(currentIds)) {
          //print('⏭️ Список не изменился, пропускаем обновление');
          return;
        }

        //print('✅ Список изменился, обновляем');

        setState(() {
          selectedStatusesList = value;
          allSelected = value.length == statusList.length;
          if (value.isNotEmpty) {
            selectedStatusData = value.first;
          }
        });

        if (value.isNotEmpty) {
          widget.onSelectStatus(value.first);
          if (widget.onSelectMultipleStatuses != null) {
            final selectedIds = value.map((s) => s.id).toList();
            widget.onSelectMultipleStatuses!(selectedIds);
          }
        }
      },
    );
  }

  Widget _buildListItem(
      DealStatus item,
      bool isSelected,
      Function() onItemSelect,
      TextStyle dropdownItemTextStyle) {
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
                color:
                    isSelected ? context.appColors.buttonPrimaryBg : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: context.appColors.textInverse,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: dropdownItemTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
