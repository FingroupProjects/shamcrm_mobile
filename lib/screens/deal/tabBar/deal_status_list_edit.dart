import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DealStatusEditWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(DealStatus) onSelectStatus;
    final Function(List<int>)? onSelectMultipleStatuses; // ✅ НОВОЕ

  final List<DealStatusById>? dealStatuses;

  DealStatusEditWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
      this.onSelectMultipleStatuses, // ✅ НОВОЕ
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
  bool _isInitialized = false;
  bool allSelected = false; // ✅ НОВОЕ: для "Выделить всё"

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
    context.read<DealBloc>().add(FetchDealStatuses());
  }

  Future<void> _loadMultiSelectSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('managing_deal_status_visibility') ?? false;
    
    //print('DealStatusEditWidget: managing_deal_status_visibility = $value');
    //print('DealStatusEditWidget: Режим = ${value ? "МУЛЬТИВЫБОР" : "ОДИНОЧНЫЙ"}');
    
    if (mounted) {
      setState(() {
        isMultiSelectEnabled = value;
      });
    }
  }

  void _initializeSelectedStatuses() {
    if (_isInitialized || statusList.isEmpty) return;
    
    //print('DealStatusEditWidget: Инициализация выбранных статусов');
    //print('DealStatusEditWidget: widget.selectedStatus = ${widget.selectedStatus}');
    //print('DealStatusEditWidget: widget.dealStatuses = ${widget.dealStatuses?.map((s) => s.id).toList()}');
    //print('DealStatusEditWidget: statusList IDs = ${statusList.map((s) => s.id).toList()}');
    
    List<int> targetIds = [];
    
    if (widget.dealStatuses != null && widget.dealStatuses!.isNotEmpty) {
      //print('DealStatusEditWidget: Используем dealStatuses от бэкенда');
      targetIds = widget.dealStatuses!.map((s) => s.id).toList();
    }
    else if (widget.selectedStatus != null && widget.selectedStatus!.isNotEmpty) {
      //print('DealStatusEditWidget: Используем selectedStatus');
      targetIds = widget.selectedStatus!
          .split(',')
          .map((id) => int.tryParse(id.trim()))
          .where((id) => id != null)
          .cast<int>()
          .toList();
    }
    else if (statusList.length == 1) {
      //print('DealStatusEditWidget: Автовыбор единственного статуса');
      targetIds = [statusList[0].id];
    }
    
   if (targetIds.isNotEmpty) {
    final newSelectedList = statusList
        .where((status) => targetIds.contains(status.id))
        .toList();
    
    if (newSelectedList.isNotEmpty) {
      // ✅ ПРОВЕРКА: Обновляем только если список действительно изменился
      final currentIds = selectedStatusesList.map((s) => s.id).toSet();
      final newIds = newSelectedList.map((s) => s.id).toSet();
      
      if (currentIds.length != newIds.length || 
          !currentIds.containsAll(newIds)) {
        selectedStatusesList = newSelectedList;
        selectedStatusData = newSelectedList.first;
        allSelected = newSelectedList.length == statusList.length;
      }
        
        //print('DealStatusEditWidget: Инициализировано ${selectedStatusesList.length} статус(ов)');
        //print('DealStatusEditWidget: Выбранные ID: ${selectedStatusesList.map((s) => s.id).toList()}');
      } else {
        //print('DealStatusEditWidget: ⚠️ Не найдены статусы с ID: $targetIds');
      }
    }
    
    _isInitialized = true;
  }

  // ✅ НОВОЕ: Функция для выделения/снятия выделения всех статусов
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<DealBloc, DealState>(
          builder: (context, state) {
            if (state is DealLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is DealError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.translate(state.message),
                      style: statusTextStyle.copyWith(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
              return const SizedBox();
            }

            if (state is DealLoaded) {
              statusList = state.dealStatuses;
              _initializeSelectedStatuses();

              return Column(
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
              );
            }
            
            return const SizedBox();
          },
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
          widget.onSelectStatus(value);
          setState(() {
            selectedStatusData = value;
          });
          FocusScope.of(context).unfocus();
        }
      },
    );
  }

  Widget _buildMultiSelectDropdown() {
    //print('DealStatusEditWidget: Рендер мультивыбора');
    //print('DealStatusEditWidget: statusList IDs = ${statusList.map((s) => s.id).toList()}');
    //print('DealStatusEditWidget: selectedStatusesList IDs (старые) = ${selectedStatusesList.map((s) => s.id).toList()}');
    
    // ✅ Пересоздаём список из актуального statusList
    final currentlySelectedIds = selectedStatusesList.map((s) => s.id).toSet();
    final actualSelectedStatuses = statusList
        .where((status) => currentlySelectedIds.contains(status.id))
        .toList();
    
    //print('DealStatusEditWidget: actualSelectedStatuses IDs = ${actualSelectedStatuses.map((s) => s.id).toList()}');
    
    return CustomDropdown<DealStatus>.multiSelectSearch(
      items: statusList,
      initialItems: actualSelectedStatuses,
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
        // ✅ Добавляем "Выделить всех" как первый элемент
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
      // ✅ ИСПРАВЛЕНО: Правильное отображение выбранных статусов
      headerListBuilder: (context, selectedItems, enabled) {
        if (selectedItems.isEmpty) {
          return Text(
            AppLocalizations.of(context)!.translate('select_status'),
            style: statusTextStyle,
          );
        }
        
        // Формируем строку с названиями статусов
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
  print('DealStatusEditWidget: Выбрано статусов: ${value.length}');
  
  // ✅ ОПТИМИЗАЦИЯ: Один setState для всех изменений
  final needsUpdate = selectedStatusesList.length != value.length ||
      !selectedStatusesList.toSet().containsAll(value.toSet());
  
  if (needsUpdate) {
    setState(() {
      selectedStatusesList = value;
      allSelected = value.length == statusList.length;
    });
    
    if (value.isNotEmpty) {
      widget.onSelectStatus(value.first);
      
      if (widget.onSelectMultipleStatuses != null) {
        final selectedIds = value.map((s) => s.id).toList();
        widget.onSelectMultipleStatuses!(selectedIds);
      }
    }
  }
  
},
    );
  }

  // ✅ НОВЫЙ МЕТОД: Красивый элемент списка с чекбоксом
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