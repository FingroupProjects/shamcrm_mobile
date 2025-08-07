import 'package:crm_task_manager/bloc/call_bloc/call_center_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_event.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/call_center_screen.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/call_type_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/rating_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/status_multi_select_widget.dart';
import 'package:crm_task_manager/models/lead_multi_model.dart';
import 'package:crm_task_manager/models/page_2/call_center_model.dart';
import 'package:crm_task_manager/models/page_2/operator_model.dart';
import 'package:crm_task_manager/page_2/call_center/call_center_item.dart';
import 'package:crm_task_manager/page_2/call_center/call_details_screen.dart';
import 'package:crm_task_manager/page_2/call_center/dashboard_call_center_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CallCenterScreen extends StatefulWidget {
  const CallCenterScreen({Key? key}) : super(key: key);

  @override
  State<CallCenterScreen> createState() => _CallCenterScreenState();
}

class _CallCenterScreenState extends State<CallCenterScreen> {
  CallType? _selectedFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();
  
  // Добавляем PageController для swipe навигации
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  // Массив фильтров для удобного управления
  final List<CallType?> _filterTypes = [null, CallType.incoming, CallType.outgoing, CallType.missed];
  final List<String> _filterLabels = ['Все', 'Входящие', 'Исходящие', 'Пропущенные'];

  List<CallTypeData> _selectedCallTypes = [];
  List<Operator> _selectedOperators = [];
  List<StatusData> _selectedStatuses = [];
  List<RatingData> _selectedRatings = [];
  final TextEditingController _remarkController = TextEditingController();
  List _selectedLeads = [];
  bool? selectedRemarkStatus;
  DateTime? startDate;
  DateTime? endDate;

  bool _areFiltersApplied = false;

  @override
  void initState() {
    super.initState();
    context.read<CallCenterBloc>().add(LoadCalls(callType: null));
    _searchController.addListener(() {
      _onSearch(_searchController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.addListener(_onScroll);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final bloc = context.read<CallCenterBloc>();
      final state = bloc.state;
      if (state is CallCenterLoaded &&
          !bloc.allCallsFetched &&
          !bloc.isLoadingMore) {
        bloc.add(LoadMoreCalls(
          callType: _selectedFilter,
          currentPage: state.currentPage,
        ));
      }
    }
  }

  void _filterCalls(CallType? filter) {
    setState(() {
      _selectedFilter = filter;
      _updateFiltersState();
      context.read<CallCenterBloc>().add(LoadCalls(callType: filter));
    });
  }

  // Новый метод для обработки смены страницы через swipe
  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
      _selectedFilter = _filterTypes[index];
    });
    _filterCalls(_filterTypes[index]);
  }

  // Новый метод для программного переключения страниц при нажатии на кнопку
  void _navigateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });

    _updateFiltersState();

    context.read<CallCenterBloc>().add(LoadCalls(
          callType: _selectedFilter,
          page: 1,
          searchQuery: query,
        ));
  }

  void _resetSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _isSearching = false;
      _focusNode.unfocus();
    });

    _updateFiltersState();

    context.read<CallCenterBloc>().add(LoadCalls(
          callType: _selectedFilter,
          page: 1,
          searchQuery: '',
        ));
  }

  void _onFiltersSelected(Map filters) {
    setState(() {
      _selectedCallTypes = (filters['callTypes'] as List<dynamic>?)
              ?.map(
                  (id) => CallTypeData(id: int.parse(id.toString()), name: ''))
              .toList() ??
          [];
      _selectedOperators = (filters['operators'] as List<dynamic>?)
              ?.map((id) => Operator(
                  id: int.parse(id.toString()),
                  name: '',
                  lastname: '',
                  login: '',
                  email: '',
                  phone: '',
                  image: '',
                  telegramUserId: null,
                  jobTitle: '',
                  fullName: '',
                  isFirstLogin: 0,
                  departmentId: null,
                  uniqueId: '',
                  operatorAvgRating: 0.0))
              .toList() ??
          [];
      _selectedStatuses = (filters['statuses'] as List<dynamic>?)
              ?.map((id) => StatusData(id: int.parse(id.toString()), name: ''))
              .toList() ??
          [];
      _selectedRatings = (filters['ratings'] as List<dynamic>?)
              ?.map((id) => RatingData(id: int.parse(id.toString()), name: ''))
              .toList() ??
          [];
      _selectedLeads = (filters['leads'] as List<dynamic>?)
              ?.map((id) => LeadData(id: int.parse(id.toString()), name: ''))
              .toList() ??
          [];
    });

    _updateFiltersState();

    context
        .read<CallCenterBloc>()
        .add(FilterCalls(filters.cast<String, dynamic>()));
  }

  void _resetFilters() {
    setState(() {
      _selectedFilter = null;
      _searchQuery = '';
      _searchController.clear();
      _isSearching = false;
      _selectedCallTypes = [];
      _selectedOperators = [];
      _selectedStatuses = [];
      _selectedRatings = [];
      _selectedLeads = [];
      selectedRemarkStatus = null;
      startDate = null;
      endDate = null;
      _areFiltersApplied = false;
      context
          .read<CallCenterBloc>()
          .add(ResetFilters());
    });
  }

  bool _hasAnyFiltersApplied() {
    return _selectedCallTypes.isNotEmpty ||
        _selectedOperators.isNotEmpty ||
        _selectedStatuses.isNotEmpty ||
        _selectedRatings.isNotEmpty ||
        _selectedLeads.isNotEmpty ||
        selectedRemarkStatus != null ||
        startDate != null ||
        endDate != null;
  }

  void _updateFiltersState() {
    setState(() {
      _areFiltersApplied = _hasAnyFiltersApplied();
    });
  }

  List<Object> _buildListWithHeaders(List<CallLogEntry> calls) {
    calls.sort((a, b) => b.callDate.compareTo(a.callDate));
    final List<Object> result = [];
    DateTime? lastDate;

    for (var call in calls) {
      final dateOnly =
          DateTime(call.callDate.year, call.callDate.month, call.callDate.day);
      if (lastDate == null || dateOnly != lastDate) {
        final header = _formatDateHeader(call.callDate);
        result.add(header);
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

  // Метод для создания контента страницы
  Widget _buildPageContent() {
    return BlocBuilder<CallCenterBloc, CallCenterState>(
      builder: (context, state) {
        if (state is CallCenterLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            ),
          );
        } else if (state is CallCenterLoaded) {
          final items = _buildListWithHeaders(state.calls);
          if (items.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            controller: _scrollController,
            itemCount: items.length +
                (context.read<CallCenterBloc>().isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                if (context.read<CallCenterBloc>().isLoadingMore) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: PlayStoreImageLoading(
                        size: 80.0,
                        duration: Duration(milliseconds: 1000),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
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
              }
              return const SizedBox.shrink();
            },
          );
        } else if (state is CallCenterError) {
          return Center(
            child: Text(
              state.message,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          );
        } else if (state is CallByIdLoaded) {
          return const Center(
            child: PlayStoreImageLoading(
              size: 80.0,
              duration: Duration(milliseconds: 1000),
            ),
          );
        }
        return _buildEmptyState();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('call_center'),
          style: const TextStyle(
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
        actions: [
          if (_isSearching)
            Container(
              width: 150,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText:
                      AppLocalizations.of(context)!.translate('search_appbar'),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16, color: Colors.black),
                autofocus: true,
              ),
            ),
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(),
            icon: _isSearching
                ? const Icon(Icons.close, color: Colors.black)
                : Image.asset(
                    'assets/icons/AppBar/search.png',
                    width: 24,
                    height: 24,
                  ),
            tooltip: AppLocalizations.of(context)!.translate('search'),
            onPressed: () {
              if (_isSearching) {
                _resetSearch();
              } else {
                setState(() {
                  _isSearching = true;
                });
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    _focusNode.requestFocus();
                  }
                });
              }
            },
          ),
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(),
            icon: Image.asset(
              'assets/icons/MyNavBar/dashboard_call.png',
              width: 24,
              height: 24,
            ),
            tooltip: AppLocalizations.of(context)!.translate('dashboard'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            },
          ),
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(),
            icon: Image.asset(
              'assets/icons/AppBar/filter.png',
              width: 24,
              height: 24,
              color: _areFiltersApplied
                  ? Colors.blue
                  : Colors.black,
            ),
            tooltip: AppLocalizations.of(context)!.translate('filter'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallCenterFilterScreen(
                    onSelectedDataFilter: _onFiltersSelected,
                    onResetFilters: () {
                      setState(() {
                        _selectedCallTypes = [];
                        _selectedOperators = [];
                        _selectedStatuses = [];
                        _selectedRatings = [];
                        _selectedLeads = [];
                        selectedRemarkStatus = null;
                        startDate = null;
                        endDate = null;
                        _areFiltersApplied = false;
                        context
                            .read<CallCenterBloc>()
                            .add(ResetFilters());
                      });
                    },
                    initialCallTypes:
                        _selectedCallTypes.map((c) => c.id.toString()).toList(),
                    initialOperators:
                        _selectedOperators.map((o) => o.id.toString()).toList(),
                    initialStatuses:
                        _selectedStatuses.map((s) => s.id.toString()).toList(),
                    initialRatings:
                        _selectedRatings.map((r) => r.id.toString()).toList(),
                    initialLeads:
                        _selectedLeads.map((l) => l.id.toString()).toList(),
                    initialRemarkStatus: selectedRemarkStatus,
                    initialStartDate: startDate?.toIso8601String(),
                    initialEndDate: endDate?.toIso8601String(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_filterLabels.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index < _filterLabels.length - 1 ? 8 : 0),
                    child: _buildFilterChip(_filterLabels[index], _filterTypes[index], index),
                  );
                }),
              ),
            ),
          ),
          Container(height: 1, color: Colors.grey.shade200),
          Expanded(
            // Заменяем обычный контент на PageView для swipe навигации
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _filterTypes.length,
              itemBuilder: (context, index) {
                // Возвращаем одинаковый контент для всех страниц,
                // так как фильтрация происходит на уровне BLoC
                return _buildPageContent();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, CallType? type, int index) {
    final isSelected = _currentPageIndex == index;
    return GestureDetector(
      onTap: () => _navigateToPage(index),
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
            AppLocalizations.of(context)!.translate('no_calls_found'),
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
    ).then((_) {
      final currentState = context.read<CallCenterBloc>().state;
      int page = 1;
      if (currentState is CallCenterLoaded) {
        page = currentState.currentPage;
      }
      context.read<CallCenterBloc>().add(LoadCalls(
            callType: _selectedFilter,
            page: page,
            searchQuery: _searchQuery,
          ));
    });
  }

  @override
  void dispose() {
    if (_scrollController.hasListeners) {
      _scrollController.removeListener(_onScroll);
    }
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _remarkController.dispose();
    _pageController.dispose(); // Не забываем освободить PageController
    super.dispose();
  }
}