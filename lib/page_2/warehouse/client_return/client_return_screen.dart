import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_return/client_return_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/money/money_income/money_income_screen.dart';
import 'package:crm_task_manager/page_2/money/widgets/error_dialog.dart';
import 'package:crm_task_manager/page_2/warehouse/client_return/client_return_card.dart';
import 'package:crm_task_manager/page_2/warehouse/client_return/client_return_create.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientReturnScreen extends StatefulWidget {
  const ClientReturnScreen({super.key, this.organizationId});
  final int? organizationId;

  @override
  State<ClientReturnScreen> createState() => _ClientReturnScreenState();
}

class _ClientReturnScreenState extends State<ClientReturnScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  late ClientReturnBloc _clientReturnBloc;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _clientReturnBloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedMax) {
      setState(() {
        _isLoadingMore = true;
      });
      _clientReturnBloc.add(FetchClientReturns(
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
    _clientReturnBloc.add(FetchClientReturns(
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
    _clientReturnBloc.add(const FetchClientReturns(forceRefresh: true));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void initState() {
    super.initState();
    _clientReturnBloc = ClientReturnBloc(ApiService())
      ..add(const FetchClientReturns(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _clientReturnBloc,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateClientReturnDocumentScreen(
                      organizationId: widget.organizationId),
                ),
              ).then((_) {
                _clientReturnBloc.add(const FetchClientReturns(forceRefresh: true));
              });
            }
          },
          backgroundColor: const Color(0xff1E2E52),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBarPage2(
            title: localizations!.translate('appbar_client_returns') ??
                'Возврат от клиента',
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
                _clientReturnBloc.add(const FetchClientReturns(forceRefresh: true));
              }
            },
            onClickProfileAvatar: () {},
            clearButtonClickFiltr: (bool p1) {},
            currentFilters: {},
          ),
        ),
        body: BlocListener<ClientReturnBloc, ClientReturnState>(
          listener: (context, state) {
            if (state is ClientReturnLoaded) {
              setState(() {
                _hasReachedMax = state.hasReachedMax;
                _isInitialLoad = false;
                _isLoadingMore = false;
              });
            } else if (state is ClientReturnError) {
              setState(() {
                _isInitialLoad = false;
                _isLoadingMore = false;
              });
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            }
          },
          child: BlocBuilder<ClientReturnBloc, ClientReturnState>(
            builder: (context, state) {
              if (state is ClientReturnLoading) {
                return Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              }

              final currentData = state is ClientReturnLoaded ? state.data : [];

              if (currentData.isEmpty && state is ClientReturnLoaded) {
                return Center(
                  child: Text(
                    _isSearching
                        ? localizations.translate('nothing_found') ??
                            'Ничего не найдено'
                        : localizations.translate('no_returns') ??
                            'Нет возвратов',
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
                                  duration: Duration(milliseconds: 1000),
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                    return ClientReturnCard(
                      document: currentData[index],
                      onUpdate: () {
                        _clientReturnBloc
                            .add(const FetchClientReturns(forceRefresh: true));
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