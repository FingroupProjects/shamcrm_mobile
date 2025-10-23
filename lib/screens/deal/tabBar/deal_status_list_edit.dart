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

/// ✅ ФИНАЛЬНОЕ РЕШЕНИЕ - работает с кешем BLoC
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
  bool _hasInitialized = false;
  
  final TextStyle statusTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    print('🟢 DealStatusEditWidget: initState');
    _loadMultiSelectSetting();
    
    // ✅ Запрашиваем статусы если их нет
    final currentState = context.read<DealBloc>().state;
    if (currentState is! DealLoaded) {
      print('📡 Запрашиваем статусы из BLoC');
      context.read<DealBloc>().add(FetchDealStatuses());
    } else {
      print('✅ Статусы уже есть в BLoC: ${currentState.dealStatuses.length}');
      _updateStatusList(currentState.dealStatuses);
    }
  }

  Future<void> _loadMultiSelectSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('managing_deal_status_visibility') ?? false;
    
    print('📋 Режим: ${value ? "МУЛЬТИВЫБОР" : "ОДИНОЧНЫЙ"}');
    
    if (mounted) {
      setState(() {
        isMultiSelectEnabled = value;
      });
    }
  }

  void _updateStatusList(List<DealStatus> newStatuses) {
    if (newStatuses.isEmpty) {
      print('⚠️ _updateStatusList: пустой список');
      return;
    }
    
    print('🔄 _updateStatusList: ${newStatuses.length} статусов');
    
    setState(() {
      statusList = newStatuses;
    });
    
    // Инициализируем выбор только один раз
    if (!_hasInitialized) {
      _initializeSelection();
    }
  }

  void _initializeSelection() {
    if (statusList.isEmpty) {
      print('⚠️ _initializeSelection: statusList пустой');
      return;
    }
    
    if (_hasInitialized) {
      print('⚠️ Уже инициализирован, пропуск');
      return;
    }
    
    print('🔵 _initializeSelection: Начало');
    print('   - statusList: ${statusList.length}');
    print('   - dealStatuses: ${widget.dealStatuses?.map((s) => s.id).toList()}');
    print('   - selectedStatus: ${widget.selectedStatus}');
    
    List<int> targetIds = [];
    
    // ПРИОРИТЕТ 1: dealStatuses от бэкенда
    if (widget.dealStatuses != null && widget.dealStatuses!.isNotEmpty) {
      targetIds = widget.dealStatuses!.map((s) => s.id).toList();
      print('✅ Используем dealStatuses: $targetIds');
    }
    // ПРИОРИТЕТ 2: selectedStatus
    else if (widget.selectedStatus != null && widget.selectedStatus!.isNotEmpty) {
      targetIds = widget.selectedStatus!
          .split(',')
          .map((id) => int.tryParse(id.trim()))
          .whereType<int>()
          .toList();
      print('✅ Используем selectedStatus: $targetIds');
    }
    // ПРИОРИТЕТ 3: Первый статус
    else if (statusList.isNotEmpty) {
      targetIds = [statusList[0].id];
      print('✅ Автовыбор первого: $targetIds');
    }
    
    if (targetIds.isEmpty) {
      print('⚠️ targetIds пустой');
      return;
    }
    
    final selected = statusList.where((s) => targetIds.contains(s.id)).toList();
    
    if (selected.isEmpty) {
      print('❌ Не найдены статусы: $targetIds');
      return;
    }
    
    setState(() {
      selectedStatusesList = selected;
      selectedStatusData = selected.first;
      allSelected = selected.length == statusList.length;
      _hasInitialized = true;
    });
    
    print('✅✅✅ Выбрано ${selected.length}: ${selected.map((s) => s.title).join(", ")}');
    
    // Уведомляем родителя
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('📤 Уведомление родителя');
        widget.onSelectStatus(selected.first);
        if (widget.onSelectMultipleStatuses != null && isMultiSelectEnabled) {
          widget.onSelectMultipleStatuses!(targetIds);
        }
      }
    });
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
        BlocConsumer<DealBloc, DealState>(
          // ✅ КРИТИЧНО: Слушаем ВСЕ изменения состояния
          listener: (context, state) {
            print('👂 Listener: ${state.runtimeType}');
            
            // ✅ Обрабатываем ОБА состояния: DealLoaded И DealDataLoaded
            if (state is DealLoaded) {
              print('📥 DealLoaded: ${state.dealStatuses.length} статусов');
              _updateStatusList(state.dealStatuses);
            }
            // ✅ НОВОЕ: Также обрабатываем DealDataLoaded
            else if (state is DealDataLoaded) {
              print('📥 DealDataLoaded: получаем статусы из кеша');
              // Статусы должны быть в предыдущем DealLoaded
              // Мы просто сохраняем текущий statusList
            }
          },
          builder: (context, state) {
            print('🎨 BUILD: state=${state.runtimeType}, statusList=${statusList.length}');
            
            // Показываем loading только если ДЕЙСТВИТЕЛЬНО загружается
            if (state is DealLoading && statusList.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('status'),
                    style: statusTextStyle,
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ],
              );
            }

            // Показываем ошибку
            if (state is DealError && statusList.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('status'),
                    style: statusTextStyle,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ошибка загрузки статусов',
                    style: statusTextStyle.copyWith(color: Colors.red),
                  ),
                ],
              );
            }

            // ✅ Показываем заглушку только если РЕАЛЬНО нет статусов
            if (statusList.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('status'),
                    style: statusTextStyle,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xffF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Загрузка статусов...',
                      style: statusTextStyle.copyWith(color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            // ✅ ПОКАЗЫВАЕМ DROPDOWN если есть статусы
            print('✅ Рендер dropdown: ${selectedStatusesList.length} выбрано');
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('status'),
                  style: statusTextStyle,
                ),
                const SizedBox(height: 12),
                isMultiSelectEnabled
                    ? _buildMultiSelectDropdown()
                    : _buildSingleSelectDropdown(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSingleSelectDropdown() {
    print('🔨 Single dropdown: ${selectedStatusData?.title}');
    
    return CustomDropdown<DealStatus>.search(
      closeDropDownOnClearFilterSearch: true,
      items: statusList,
      searchHintText: AppLocalizations.of(context)!.translate('search'),
      overlayHeight: 400,
      decoration: CustomDropdownDecoration(
        closedFillColor: const Color(0xffF4F7FD),
        expandedFillColor: Colors.white,
        closedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1),
        closedBorderRadius: BorderRadius.circular(12),
        expandedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1),
        expandedBorderRadius: BorderRadius.circular(12),
      ),
      listItemBuilder: (context, item, isSelected, onItemSelect) {
        return Text(item.title, style: statusTextStyle);
      },
      headerBuilder: (context, selectedItem, enabled) {
        return Text(selectedItem.title, style: statusTextStyle);
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
    print('🔨 Multi dropdown: ${selectedStatusesList.map((s) => s.title).toList()}');
    
    return CustomDropdown<DealStatus>.multiSelectSearch(
      items: statusList,
      initialItems: selectedStatusesList,
      searchHintText: AppLocalizations.of(context)!.translate('search'),
      overlayHeight: 400,
      decoration: CustomDropdownDecoration(
        closedFillColor: const Color(0xffF4F7FD),
        expandedFillColor: Colors.white,
        closedBorder: Border.all(color: Colors.transparent, width: 1),
        closedBorderRadius: BorderRadius.circular(12),
        expandedBorder: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        expandedBorderRadius: BorderRadius.circular(12),
      ),
      listItemBuilder: (context, item, isSelected, onItemSelect) {
        if (statusList.indexOf(item) == 0) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: _toggleSelectAll,
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xff1E2E52), width: 1),
                          borderRadius: BorderRadius.circular(4),
                          color: allSelected ? const Color(0xff1E2E52) : Colors.transparent,
                        ),
                        child: allSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
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
        return Text(statusNames, style: statusTextStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
      },
      hintBuilder: (context, hint, enabled) => Text(
        AppLocalizations.of(context)!.translate('select_status'),
        style: statusTextStyle.copyWith(fontSize: 14),
      ),
      onListChanged: (value) {
        print('✏️ onListChanged: ${value.length}');
        
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
            widget.onSelectMultipleStatuses!(value.map((s) => s.id).toList());
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
                border: Border.all(color: const Color(0xff1E2E52), width: 1),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(item.title, style: statusTextStyle)),
          ],
        ),
      ),
    );
  }
}