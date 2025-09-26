import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/write_off/write_off_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/money/widgets/error_dialog.dart';
import 'package:crm_task_manager/page_2/warehouse/write_off/write_off_card.dart';
import 'package:crm_task_manager/page_2/warehouse/write_off/write_off_create.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WriteOffScreen extends StatefulWidget {
  const WriteOffScreen({super.key, this.organizationId});
  final int? organizationId;

  @override
  State<WriteOffScreen> createState() => _WriteOffScreenState();
}

class _WriteOffScreenState extends State<WriteOffScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  late WriteOffBloc _writeOffBloc;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _writeOffBloc.close();
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
      _writeOffBloc.add(FetchWriteOffs(
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
    _writeOffBloc.add(FetchWriteOffs(
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
    _writeOffBloc.add(const FetchWriteOffs(forceRefresh: true));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void initState() {
    super.initState();
    _writeOffBloc = WriteOffBloc(ApiService())
      ..add(const FetchWriteOffs(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _writeOffBloc,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateWriteOffDocumentScreen(
                      organizationId: widget.organizationId),
                ),
              ).then((_) {
                _writeOffBloc.add(const FetchWriteOffs(forceRefresh: true));
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
            title: localizations!.translate('appbar_write_off') ??
                'Списание',
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
                _writeOffBloc.add(const FetchWriteOffs(forceRefresh: true));
              }
            },
            onClickProfileAvatar: () {},
            clearButtonClickFiltr: (bool p1) {},
            currentFilters: {},
          ),
        ),
        body: BlocListener<WriteOffBloc, WriteOffState>(
          listener: (context, state) {
            if (state is WriteOffLoaded) {
              setState(() {
                _hasReachedMax = state.hasReachedMax;
                _isInitialLoad = false;
                _isLoadingMore = false;
              });
            } else if (state is WriteOffError) {
              setState(() {
                _isInitialLoad = false;
                _isLoadingMore = false;
              });
              if (state.statusCode  == 409) {
                final localizations = AppLocalizations.of(context)!;
                showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: BlocBuilder<WriteOffBloc, WriteOffState>(
            builder: (context, state) {
              if (state is WriteOffLoading) {
                return Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              }

              final currentData = state is WriteOffLoaded ? state.data : [];

              if (currentData.isEmpty && state is WriteOffLoaded) {
                return Center(
                  child: Text(
                    _isSearching
                        ? localizations.translate('nothing_found') ??
                            'Ничего не найдено'
                        : localizations.translate('no_write_offs') ??
                            'Нет документов списания',
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
                    return WriteOffCard(
                      document: currentData[index],
                      onUpdate: () {
                        _writeOffBloc
                            .add(const FetchWriteOffs(forceRefresh: true));
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