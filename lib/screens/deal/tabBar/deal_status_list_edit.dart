import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DealStatusEditWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(DealStatus) onSelectStatus;
  final Function(List<int>)? onSelectMultipleStatuses;
  final List<DealStatusById>? dealStatuses;

  DealStatusEditWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
    this.onSelectMultipleStatuses,
    this.dealStatuses,
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

  final TextStyle statusTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

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
      print('🔄 DealStatusEditWidget: dealStatuses изменились, переинициализация');
      _lastInitializedIds.clear();
      if (statusList.isNotEmpty) {
        _initializeSelectedStatuses();
      }
    }
  }

  Future<void> _loadMultiSelectSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('managing_deal_status_visibility') ?? false;

    print('DealStatusEditWidget: managing_deal_status_visibility = $value');
    print('DealStatusEditWidget: Режим = ${value ? "МУЛЬТИВЫБОР" : "ОДИНОЧНЫЙ"}');

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
      print('📡 Загрузка статусов: includeAll = $isMultiSelectEnabled');

      // Используем правильный эндпоинт в зависимости от настройки
      final statuses = await ApiService().getDealStatuses(
          includeAll: isMultiSelectEnabled
      );

      print('✅ Загружено ${statuses.length} статусов');

      if (mounted) {
        setState(() {
          statusList = statuses;
          isLoadingStatuses = false;
        });

        // После загрузки инициализируем выбранные статусы
        _initializeSelectedStatuses();
      }
    } catch (e) {
      print('❌ Ошибка загрузки статусов: $e');
      if (mounted) {
        setState(() {
          isLoadingStatuses = false;
        });

        // Показываем ошибку пользователю
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка загрузки статусов',
              style: statusTextStyle.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initializeSelectedStatuses() {
    if (statusList.isEmpty) {
      print('❌ DealStatusEditWidget: statusList пустой, инициализация невозможна');
      return;
    }

    print('🔍 DealStatusEditWidget: Начало инициализации');
    print('   - widget.selectedStatus = ${widget.selectedStatus}');
    print('   - widget.dealStatuses = ${widget.dealStatuses?.map((s) => s.id).toList()}');
    print('   - statusList IDs = ${statusList.map((s) => s.id).toList()}');

    List<int> targetIds = [];

    // ✅ ПРИОРИТЕТ 1: Используем dealStatuses (массив от бэкенда)
    if (widget.dealStatuses != null && widget.dealStatuses!.isNotEmpty) {
      print('✅ Используем dealStatuses от бэкенда');
      targetIds = widget.dealStatuses!.map((s) => s.id).toList();
    }
    // ✅ ПРИОРИТЕТ 2: Парсим selectedStatus (строка с ID через запятую)
    else if (widget.selectedStatus != null && widget.selectedStatus!.isNotEmpty) {
      print('✅ Используем selectedStatus');
      targetIds = widget.selectedStatus!
          .split(',')
          .map((id) => int.tryParse(id.trim()))
          .where((id) => id != null)
          .cast<int>()
          .toList();
    }
    // ✅ ПРИОРИТЕТ 3: Если только один статус в списке, выбираем его
    else if (statusList.length == 1) {
      print('✅ Автовыбор единственного статуса');
      targetIds = [statusList[0].id];
    }

    // ✅ ПРОВЕРКА: Нужна ли повторная инициализация?
    final targetIdsSet = targetIds.toSet();
    if (_lastInitializedIds.containsAll(targetIdsSet) &&
        targetIdsSet.containsAll(_lastInitializedIds)) {
      print('⭐️ Инициализация уже выполнена для этих ID, пропускаем');
      return;
    }

    if (targetIds.isNotEmpty) {
      final newSelectedList = statusList
          .where((status) => targetIds.contains(status.id))
          .toList();

      if (newSelectedList.isNotEmpty) {
        setState(() {
          selectedStatusesList = newSelectedList;
          selectedStatusData = newSelectedList.first;
          allSelected = newSelectedList.length == statusList.length;
          _lastInitializedIds = targetIds.toSet();
        });

        print('✅ Инициализировано ${selectedStatusesList.length} статус(ов)');
        print('✅ Выбранные ID: ${selectedStatusesList.map((s) => s.id).toList()}');

        // ✅ ВАЖНО: Уведомляем родителя о выборе
        widget.onSelectStatus(newSelectedList.first);
        if (widget.onSelectMultipleStatuses != null && isMultiSelectEnabled) {
          widget.onSelectMultipleStatuses!(targetIds);
        }
      } else {
        print('❌ Не найдены статусы с ID: $targetIds');
        print('   Доступные ID: ${statusList.map((s) => s.id).toList()}');
      }
    } else {
      print('⚠️ targetIds пустой, выбор не установлен');
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
              selectedStatusesList.map((s) => s.id).toList()
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ ИЗМЕНЕНО: Используем собственную загрузку вместо BlocBuilder
        if (isLoadingStatuses)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xff1E2E52),
            ),
          )
        else if (statusList.isEmpty)
          Center(
            child: Text(
              'Ошибка загрузки статусов',
              style: statusTextStyle.copyWith(color: Colors.red),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('deal_statuses'),
                style: statusTextStyle.copyWith(fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: 1,
                    color: const Color(0xFFF4F7FD),
                  ),
                ),
                child: isMultiSelectEnabled
                    ? _buildMultiSelectDropdown()
                    : _buildSingleSelectDropdown(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSingleSelectDropdown() {
    return CustomDropdown<DealStatus>.search(
      closeDropDownOnClearFilterSearch: true,
      items: statusList,
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
        return Text(
          item.title,
          style: statusTextStyle,
        );
      },
      headerBuilder: (context, selectedItem, enabled) {
        return Text(
          selectedItem?.title ??
              AppLocalizations.of(context)!.translate('select_status'),

          style: statusTextStyle,
        );
      },
      hintBuilder: (context, hint, enabled) => Text(
        AppLocalizations.of(context)!.translate('select_status'),
        style: statusTextStyle.copyWith(fontSize: 14),
      ),
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

  Widget _buildMultiSelectDropdown() {
    print('📋 Рендер мультивыбора');
    print('   - statusList: ${statusList.length} элементов');
    print('   - selectedStatusesList: ${selectedStatusesList.length} элементов');

    // ✅ Синхронизируем выбранные статусы с актуальным statusList
    final currentlySelectedIds = selectedStatusesList.map((s) => s.id).toSet();
    final actualSelectedStatuses = statusList
        .where((status) => currentlySelectedIds.contains(status.id))
        .toList();

    print('   - selectedStatusesList IDs: ${selectedStatusesList.map((s) => s.id).toList()}');

    return CustomDropdown<DealStatus>.multiSelectSearch(
      items: statusList,
      initialItems: selectedStatusesList,
      searchHintText: AppLocalizations.of(context)!.translate('search'),
      overlayHeight: 400,
      decoration: CustomDropdownDecoration(
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
                            width: 1,
                          ),
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
              Divider(height: 20, color: const Color(0xFFE5E7EB)),
              _buildListItem(item, isSelected, onItemSelect),
            ],
          );
        }
        return _buildListItem(item, isSelected, onItemSelect);
      },
      headerListBuilder: (context, selectedItems, enabled) {
        if (selectedItems.isEmpty) {
          return Text(
            AppLocalizations.of(context)!.translate('select_status'),
            style: statusTextStyle,
          );
        }

        String statusNames = selectedItems.map((e) => e.title).join(', ');

        return Text(
          statusNames,
          style: statusTextStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
      hintBuilder: (context, hint, enabled) => Text(
        AppLocalizations.of(context)!.translate('select_status'),
        style: statusTextStyle.copyWith(fontSize: 14),
      ),
      onListChanged: (value) {
        print('✏️ Выбрано статусов: ${value.length}');

        print('✏️ onListChanged вызван: ${value.length} статусов');

        // ✅ КРИТИЧНО: Проверяем, действительно ли изменились данные
        final newIds = value.map((s) => s.id).toSet();
        final currentIds = selectedStatusesList.map((s) => s.id).toSet();

        // Если списки идентичны, игнорируем
        if (newIds.length == currentIds.length &&
            newIds.containsAll(currentIds)) {
          print('⏭️ Список не изменился, пропускаем обновление');
          return;
        }

        print('✅ Список изменился, обновляем');

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

  Widget _buildListItem(DealStatus item, bool isSelected, Function() onItemSelect) {
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}