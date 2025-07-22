import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:crm_task_manager/page_2/call_center/call_center_item.dart';
import 'package:crm_task_manager/page_2/call_center/call_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CallCenterScreen extends StatefulWidget {
  const CallCenterScreen({Key? key}) : super(key: key);

  @override
  State<CallCenterScreen> createState() => _CallCenterScreenState();
}

class _CallCenterScreenState extends State<CallCenterScreen> {
  List<CallLogEntry> _allCalls = [];
  List<CallLogEntry> _filteredCalls = [];
  CallType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    _allCalls = [
      CallLogEntry(
        id: '1',
        leadName: 'Алексей Иванов',
        phoneNumber: '+7 (999) 123-45-67',
        callDate: DateTime.now().subtract(const Duration(minutes: 15)),
        callType: CallType.incoming,
        duration: const Duration(minutes: 2, seconds: 28),
      ),
      CallLogEntry(
        id: '2',
        leadName: 'Мария Петрова',
        phoneNumber: '+7 (999) 987-65-43',
        callDate: DateTime.now().subtract(const Duration(hours: 2)),
        callType: CallType.missed,
      ),
      CallLogEntry(
        id: '3',
        leadName: 'Дмитрий Сидоров',
        phoneNumber: '+7 (999) 555-44-33',
        callDate: DateTime.now().subtract(const Duration(hours: 5)),
        callType: CallType.outgoing,
        duration: const Duration(minutes: 12, seconds: 45),
      ),
      CallLogEntry(
        id: '4',
        leadName: 'Елена Козлова',
        phoneNumber: '+7 (999) 777-88-99',
        callDate: DateTime.now().subtract(const Duration(days: 1)),
        callType: CallType.incoming,
        duration: const Duration(minutes: 3, seconds: 12),
      ),
      CallLogEntry(
        id: '5',
        leadName: 'Сергей Морозов',
        phoneNumber: '+7 (999) 222-11-00',
        callDate: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
        callType: CallType.missed,
      ),
    ];
    _filteredCalls = List.from(_allCalls);
  }

  void _filterCalls(CallType? filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == null) {
        _filteredCalls = List.from(_allCalls);
      } else {
        _filteredCalls = _allCalls.where((call) => call.callType == filter).toList();
      }
    });
  }

  List<Object> _buildListWithHeaders(List<CallLogEntry> calls) {
    calls.sort((a, b) => b.callDate.compareTo(a.callDate));
    final List<Object> result = [];
    DateTime? lastDate;

    for (var call in calls) {
      final dateOnly = DateTime(call.callDate.year, call.callDate.month, call.callDate.day);
      if (lastDate == null || dateOnly != lastDate) {
        result.add(_formatDateHeader(call.callDate));
        lastDate = dateOnly;
      }
      result.add(call);
    }
    return result;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(callDate).inDays;

    if (difference == 0) return 'Сегодня';
    if (difference == 1) return 'Вчера';

    return DateFormat('d MMMM', 'ru').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildListWithHeaders(_filteredCalls);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Колл центр',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Фильтры
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('Все', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Входящие', CallType.incoming),
                  const SizedBox(width: 8),
                  _buildFilterChip('Исходящие', CallType.outgoing),
                  const SizedBox(width: 8),
                  _buildFilterChip('Пропущенные', CallType.missed),
                ],
              ),
            ),
          ),
          Container(height: 1, color: Colors.grey.shade200),

          Expanded(
            child: items.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item is String) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text(
                            item,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        );
                      } else if (item is CallLogEntry) {
                        return CallLogItem(
                          callEntry: item,
                          onTap: () => _onCallTap(item),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, CallType? type) {
    final isSelected = _selectedFilter == type;
    return GestureDetector(
      onTap: () => _filterCalls(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Звонков не найдено',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

void _onCallTap(CallLogEntry call) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CallDetailsScreen(callEntry: call),
    ),
  );
}
}
