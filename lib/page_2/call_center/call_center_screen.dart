import 'package:crm_task_manager/bloc/call_bloc/call_center_bloc.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_event.dart';
import 'package:crm_task_manager/bloc/call_bloc/call_center_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/call_center_screen.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/call_type_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/operator_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/rating_multi_select_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/call_center/status_multi_select_widget.dart';
import 'package:crm_task_manager/models/page_2/call_center_model.dart';
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

  List<CallTypeData> _selectedCallTypes = [];
  List<OperatorData> _selectedOperators = [];
  List<StatusData> _selectedStatuses = [];
  List<RatingData> _selectedRatings = [];
  final TextEditingController _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print("Initializing CallCenterScreen");
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
    final pixels = _scrollController.position.pixels;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (pixels >= maxExtent - 100) {
      print("Near end of scroll, checking for LoadMoreCalls");
      final bloc = context.read<CallCenterBloc>();
      final state = bloc.state;
      if (state is CallCenterLoaded && !bloc.allCallsFetched && !bloc.isLoadingMore) {
        if (state.currentPage < state.totalPages) {
          print("Triggering LoadMoreCalls for page ${state.currentPage + 1}");
          bloc.add(LoadMoreCalls(
            callType: _selectedFilter,
            currentPage: state.currentPage,
          ));
        } else {
          print("All pages fetched");
        }
      }
    }
  }

  void _filterCalls(CallType? filter) {
    setState(() {
      print("Filtering calls with type: $filter");
      _selectedFilter = filter;
      context.read<CallCenterBloc>().add(LoadCalls(callType: filter));
    });
  }

  void _onSearch(String query) {
    setState(() {
      print("Search query: $query");
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
      context.read<CallCenterBloc>().add(LoadCalls(
        callType: _selectedFilter,
        page: 1,
        searchQuery: query,
      ));
    });
  }

  void _onFiltersSelected(Map filters) {
    setState(() {
      print("Filters selected: $filters");
      _selectedFilter = filters['callType'] as CallType?;
      _selectedCallTypes = filters['callTypes'] as List<CallTypeData>? ?? [];
      _selectedOperators = filters['operators'] as List<OperatorData>? ?? [];
      _selectedStatuses = filters['statuses'] as List<StatusData>? ?? [];
      _selectedRatings = filters['ratings'] as List<RatingData>? ?? [];
      context.read<CallCenterBloc>().add(LoadCalls(callType: _selectedFilter));
    });
  }

  void _resetFilters() {
    setState(() {
      print("Resetting filters");
      _selectedFilter = null;
      _searchQuery = '';
      _searchController.clear();
      _isSearching = false;
      _selectedCallTypes = [];
      _selectedOperators = [];
      _selectedStatuses = [];
      _selectedRatings = [];
      _remarkController.clear();
      context.read<CallCenterBloc>().add(LoadCalls(callType: null));
    });
  }

  List<Object> _buildListWithHeaders(List<CallLogEntry> calls) {
    print("Building list with headers, call count: ${calls.length}");
    calls.sort((a, b) => b.callDate.compareTo(a.callDate));
    final List<Object> result = [];
    DateTime? lastDate;

    for (var call in calls) {
      final dateOnly = DateTime(call.callDate.year, call.callDate.month, call.callDate.day);
      if (lastDate == null || dateOnly != lastDate) {
        final header = _formatDateHeader(call.callDate);
        print("Adding header: $header");
        result.add(header);
        lastDate = dateOnly;
      }
      print("Adding call: ${call.id}");
      result.add(call);
    }
    print("List built, total items: ${result.length}");
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
                  hintText: AppLocalizations.of(context)!.translate('search_appbar'),
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
              setState(() {
                _isSearching = !_isSearching;
                if (_isSearching) {
                  _focusNode.requestFocus();
                } else {
                  _searchController.clear();
                  _focusNode.unfocus();
                  _resetFilters();
                }
              });
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
            ),
            tooltip: AppLocalizations.of(context)!.translate('filter'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallCenterFilterScreen(
                    onSelectedDataFilter: _onFiltersSelected,
                    onResetFilters: _resetFilters,
                    initialCallTypes: _selectedCallTypes
                        .map((callType) => callType.id.toString())
                        .toList(),
                    initialOperators: _selectedOperators
                        .map((operator) => operator.id.toString())
                        .toList(),
                    initialStatuses: _selectedStatuses
                        .map((status) => status.id.toString())
                        .toList(),
                    initialRatings: _selectedRatings
                        .map((rating) => rating.id.toString())
                        .toList(),
                    initialRemark: _remarkController.text,
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
            child: BlocBuilder<CallCenterBloc, CallCenterState>(
              builder: (context, state) {
                print("Building UI with state: $state");
                if (state is CallCenterLoading) {
                  return const Center(child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: PlayStoreImageLoading(
                                size: 80.0,
                                duration: const Duration(milliseconds: 1000),
                              ),
                            ),);
                } else if (state is CallCenterLoaded) {
                  print("CallCenterLoaded: calls=${state.calls.length}, currentPage=${state.currentPage}, totalPages=${state.totalPages}");
                  final items = _buildListWithHeaders(state.calls);
                  if (items.isEmpty) {
                    print("No items to display after building list");
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: items.length + (state.currentPage < state.totalPages && context.read<CallCenterBloc>().isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= items.length) {
                        if (state.currentPage < state.totalPages && context.read<CallCenterBloc>().isLoadingMore) {
                          print("Rendering loading indicator for page ${state.currentPage + 1}");
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: PlayStoreImageLoading(
                                size: 80.0,
                                duration: const Duration(milliseconds: 1000),
                              ),
                            ),
                          );
                        }
                        print("Index $index out of bounds, returning empty widget");
                        return const SizedBox.shrink();
                      }
                      final item = items[index];
                      if (item is String) {
                        print("Rendering header: $item");
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
                        print("Rendering call item: ${item.id}");
                        return CallLogItem(
                          callEntry: item,
                          onTap: () => _onCallTap(item),
                        );
                      } else {
                        print("Unknown item type at index $index");
                        return const SizedBox.shrink();
                      }
                    },
                  );
                } else if (state is CallCenterError) {
                  print("CallCenterError: ${state.message}");
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
                  print("CallByIdLoaded: call=${state.call.id}, no action needed");
                  return const Center(child: PlayStoreImageLoading(
                                size: 80.0,
                                duration: const Duration(milliseconds: 1000),
                              ),);
                }
                print("Default case: rendering empty state");
                return _buildEmptyState();
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
    print("Navigating to CallDetailsScreen for call: ${call.id}");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallDetailsScreen(callEntry: call),
      ),
    ).then((_) {
      print("Returning to CallCenterScreen, restoring state");
      final currentState = context.read<CallCenterBloc>().state;
      int page = 1;
      if (currentState is CallCenterLoaded) {
        page = currentState.currentPage;
        print("Restoring from CallCenterLoaded, page: $page");
      } else {
        print("Current state is $currentState, using default page: $page");
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
    print("Disposing CallCenterScreen");
    if (_scrollController.hasListeners) {
      _scrollController.removeListener(_onScroll);
    }
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _remarkController.dispose();
    super.dispose();
  }
}