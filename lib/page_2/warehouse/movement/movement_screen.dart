import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/warehouse/movement/movement_card.dart';
import 'package:crm_task_manager/page_2/warehouse/movement/movement_create.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovementScreen extends StatefulWidget {
  const MovementScreen({super.key, this.organizationId});
  final int? organizationId;

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  late MovementBloc _movementBloc;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  @override
  void initState() {
    super.initState();
    _movementBloc = MovementBloc(ApiService());
    
    // Добавляем слушатель скролла только если виджет смонтирован
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.addListener(_onScroll);
        _movementBloc.add(const FetchMovements(forceRefresh: true));
      }
    });
  }

  @override
  void dispose() {
    // Сначала удаляем слушатели
    _scrollController.removeListener(_onScroll);
    
    // Затем освобождаем ресурсы
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    
    // В конце закрываем BLoC
    _movementBloc.close();
    
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedMax) {
      setState(() {
        _isLoadingMore = true;
      });
      
      _movementBloc.add(FetchMovements(
        forceRefresh: false,
        filters: _currentFilters,
      ));
    }
  }

  void _onSearch(String query) {
    if (!mounted) return;
    
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    
    _currentFilters['query'] = query;
    _movementBloc.add(FetchMovements(
      forceRefresh: true,
      filters: _currentFilters,
    ));
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _currentFilters = {};
      _isInitialLoad = true;
      _hasReachedMax = false;
    });
    
    _movementBloc.add(const FetchMovements(forceRefresh: true));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted || !context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocProvider<MovementBloc>(
      create: (context) => _movementBloc,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (!mounted) return;
            
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateMovementDocumentScreen(
                    organizationId: widget.organizationId),
              ),
            );
            
            // Проверяем, что виджет всё ещё смонтирован после возвращения
            if (mounted && result == true) {
              _movementBloc.add(const FetchMovements(forceRefresh: true));
            }
          },
          backgroundColor: const Color(0xff1E2E52),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBarPage2(
            title: localizations?.translate('appbar_movement') ?? 'Перемещение',
            showSearchIcon: true,
            showFilterIcon: false,
            showFilterOrderIcon: false,
            onChangedSearchInput: _onSearch,
            textEditingController: _searchController,
            focusNode: _focusNode,
            clearButtonClick: (value) {
              if (!mounted) return;
              
              if (!value) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                _movementBloc.add(const FetchMovements(forceRefresh: true));
              }
            },
            onClickProfileAvatar: () {},
            clearButtonClickFiltr: (bool p1) {},
            currentFilters: {},
          ),
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<MovementBloc, MovementState>(
              listener: (context, state) {
                // Критическая проверка mounted
                if (!mounted) return;
                
                if (state is MovementLoaded) {
                  if (mounted) {
                    setState(() {
                      _hasReachedMax = state.hasReachedMax;
                      _isInitialLoad = false;
                      _isLoadingMore = false;
                    });
                  }
                } else if (state is MovementError) {
                  if (mounted) {
                    setState(() {
                      _isInitialLoad = false;
                      _isLoadingMore = false;
                    });
                    
                    // Безопасный показ SnackBar через addPostFrameCallback
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && context.mounted) {
                        _showSnackBar(state.message, false);
                      }
                    });
                  }
                } else if (state is MovementCreateSuccess) {
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && context.mounted) {
                        _showSnackBar(state.message, true);
                        _movementBloc.add(const FetchMovements(forceRefresh: true));
                      }
                    });
                  }
                } else if (state is MovementDeleteSuccess) {
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && context.mounted) {
                        _showSnackBar(state.message, true);
                        _movementBloc.add(const FetchMovements(forceRefresh: true));
                      }
                    });
                  }
                } else if (state is MovementRestoreSuccess) {
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && context.mounted) {
                        _showSnackBar(state.message, true);
                        _movementBloc.add(const FetchMovements(forceRefresh: true));
                      }
                    });
                  }
                }
              },
            ),
          ],
          child: BlocBuilder<MovementBloc, MovementState>(
            builder: (context, state) {
              if (state is MovementLoading && _isInitialLoad) {
                return Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: const Duration(milliseconds: 1000),
                  ),
                );
              }

              final currentData = state is MovementLoaded ? state.data : <dynamic>[];

              if (currentData.isEmpty && state is MovementLoaded) {
                return Center(
                  child: Text(
                    _isSearching
                        ? (localizations?.translate('nothing_found') ?? 'Ничего не найдено')
                        : (localizations?.translate('no_movements') ?? 'Нет документов перемещения'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: const Color(0xff1E2E52),
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: currentData.length + (_hasReachedMax ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index >= currentData.length) {
                      return _isLoadingMore
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: PlayStoreImageLoading(
                                  size: 80.0,
                                  duration: const Duration(milliseconds: 1000),
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                    
                    return MovementCard(
                      document: currentData[index],
                      onUpdate: () {
                        if (mounted) {
                          _movementBloc.add(const FetchMovements(forceRefresh: true));
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}