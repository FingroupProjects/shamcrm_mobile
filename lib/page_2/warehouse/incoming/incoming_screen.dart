import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_state.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/incoming_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'incoming_document_create_screen.dart';

class IncomingScreen extends StatefulWidget {
  final int? organizationId;

  const IncomingScreen({this.organizationId, super.key});

  @override
  State<IncomingScreen> createState() => _IncomingScreenState();
}

class _IncomingScreenState extends State<IncomingScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  late IncomingBloc _incomingBloc;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  @override
  void initState() {
    super.initState();
    _incomingBloc = IncomingBloc(ApiService())..add(const FetchIncoming(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _incomingBloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedMax) {
      setState(() {
        _isLoadingMore = true;
      });
      _incomingBloc.add(FetchIncoming(
        forceRefresh: false,
        filters: _currentFilters,
      ));
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    _currentFilters['query'] = query;
    _incomingBloc.add(FetchIncoming(
      forceRefresh: true,
      filters: _currentFilters,
    ));
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _currentFilters = {};
      _isInitialLoad = true;
      _hasReachedMax = false;
    });
    _incomingBloc.add(const FetchIncoming(forceRefresh: true));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _incomingBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBarPage2(
            title: localizations!.translate('appbar_incoming') ?? 'Приходы',
            showSearchIcon: true,
            showFilterIcon: false,
            showFilterOrderIcon: false,
            onChangedSearchInput: _onSearch,
            textEditingController: _searchController,
            focusNode: _focusNode,
            clearButtonClick: (value) {
              if (!value) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                _incomingBloc.add(const FetchIncoming(forceRefresh: true));
              }
            },
            onClickProfileAvatar: () {},
            clearButtonClickFiltr: (bool p1) {},
            currentFilters: {},
          ),
        ),
        body: BlocListener<IncomingBloc, IncomingState>(
  listener: (context, state) {
    if (!mounted) return;
    
    if (state is IncomingLoaded) {
      setState(() {
        _hasReachedMax = state.hasReachedMax;
        _isInitialLoad = false;
        _isLoadingMore = false;
      });
    } else if (state is IncomingError) {
      setState(() {
        _isInitialLoad = false;
        _isLoadingMore = false;
      });
      _showSnackBar(state.message, false);
    } else if (state is IncomingCreateSuccess) {
      _showSnackBar(state.message, true);
    } else if (state is IncomingCreateError) {
      _showSnackBar(state.message, false);
    } else if (state is IncomingUpdateSuccess) {
      _showSnackBar(state.message, true);
    } else if (state is IncomingUpdateError) {
      _showSnackBar(state.message, false);
    } else if (state is IncomingDeleteSuccess) {
      // Показываем SnackBar только если мы находимся на IncomingScreen
      // (т.е. если диалог уже закрыт и мы вернулись сюда)
      _showSnackBar(state.message, true);
      
      // Обновляем список после успешного удаления
      _incomingBloc.add(const FetchIncoming(forceRefresh: true));
    }
  },
          child: BlocBuilder<IncomingBloc, IncomingState>(
            builder: (context, state) {
              if (state is IncomingLoading) {
                return Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: const Duration(milliseconds: 1000),
                  ),
                );
              }

              final currentData = state is IncomingLoaded ? state.data : [];

              if (currentData.isEmpty && state is IncomingLoaded) {
                return Center(
                  child: Text(
                    _isSearching
                        ? localizations!.translate('nothing_found') ?? 'Ничего не найдено'
                        : localizations!.translate('no_incoming') ?? 'Нет приходов',
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
                    return IncomingCard(
                      document: currentData[index],
                      onUpdate: () {
                        _incomingBloc.add(const FetchIncoming(forceRefresh: true));
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          key: const Key('create_incoming_button'),
          onPressed: () async {
            if (mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IncomingDocumentCreateScreen(
                    organizationId: widget.organizationId,
                  ),
                ),
              );

              if (result == true && mounted) {
                _incomingBloc.add(const FetchIncoming(forceRefresh: true));
              }
            }
          },
          backgroundColor: const Color(0xff1E2E52),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}