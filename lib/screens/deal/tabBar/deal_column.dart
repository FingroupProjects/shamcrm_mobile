import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/screens/deal/deal_cache.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

// Обновите конструктор DealColumn:
class DealColumn extends StatefulWidget {
  final int statusId;
  final String title;
  final void Function(int oldStatusId, int newStatusId) onStatusId;
  final int? managerId;
  final bool isDealScreenTutorialCompleted;
  final int? salesFunnelId; // Добавляем этот параметр
  final int refreshVersion;

  DealColumn({
    Key? key,
    required this.statusId,
    required this.title,
    required this.onStatusId,
    this.managerId,
    required this.isDealScreenTutorialCompleted,
    this.salesFunnelId, // Добавляем в конструктор
    required this.refreshVersion,
  }) : super(key: key);

  @override
  _DealColumnState createState() => _DealColumnState();
}

class _DealColumnState extends State<DealColumn> {
  bool _canCreateDeal = false;
  bool _permissionChecked = false;
  final ApiService _apiService = ApiService();
  late DealBloc _dealBloc;
  late ScrollController _scrollController;

  final GlobalKey keyDealCard = GlobalKey();
  final GlobalKey keyFloatingActionButton = GlobalKey();
  final GlobalKey keyDropdown = GlobalKey();
  List<TargetFocus> targets = [];
  bool _isTutorialShown = false;
  bool _isTutorialInProgress = false;
  int _tutorialStep = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    //print('DealColumn: initState started for statusId: ${widget.statusId}');
    _dealBloc = context.read<DealBloc>();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCreatePermission();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initTutorialTargets();
      _isInitialized = true;
    }
    if (widget.isDealScreenTutorialCompleted &&
        !_isTutorialShown &&
        !_isTutorialInProgress) {
      _startTutorialLogic();
    }
  }

  @override
  void didUpdateWidget(covariant DealColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDealScreenTutorialCompleted !=
            oldWidget.isDealScreenTutorialCompleted &&
        widget.isDealScreenTutorialCompleted &&
        !_isTutorialShown &&
        !_isTutorialInProgress) {
      _startTutorialLogic();
    }
  }

  @override
  void dispose() {
    //print('DealColumn: Disposing for statusId: ${widget.statusId}');
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkCreatePermission() async {
    if (_permissionChecked && _canCreateDeal) {
      //print('DealColumn: Permission already checked and available, skipping');
      return;
    }

    try {
      //print('DealColumn: Checking deal.create permission...');
      final canCreate = await _apiService.hasPermission('deal.create');
      //print('DealColumn: deal.create permission result: $canCreate');
      if (mounted) {
        setState(() {
          _canCreateDeal = canCreate;
          _permissionChecked = true;
        });
        //print('DealColumn: Updated _canCreateDeal: $_canCreateDeal');
        //print('DealColumn: Set _permissionChecked: $_permissionChecked');
      }
    } catch (e) {
      //print('DealColumn: Error checking deal.create permission: $e');
      if (mounted) {
        setState(() {
          _canCreateDeal = false;
          _permissionChecked = true;
        });
      }
    }
  }

  void _initTutorialTargets() {
    targets.clear();
    targets.addAll([
      createTarget(
        identify: "DealCard",
        keyTarget: keyDealCard,
        title: AppLocalizations.of(context)!.translate('dealCard'),
        description:
            AppLocalizations.of(context)!.translate('dealCardDescription'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.below,
        contentPadding: EdgeInsets.only(top: 50),
      ),
      createTarget(
        identify: "Dropdown",
        keyTarget: keyDropdown,
        title: AppLocalizations.of(context)!.translate('statusManagement'),
        description: AppLocalizations.of(context)!
            .translate('statusManagementDescription'),
        align: ContentAlign.bottom,
        context: context,
      ),
      if (_canCreateDeal)
        createTarget(
          identify: "FloatingActionButton",
          keyTarget: keyFloatingActionButton,
          title: AppLocalizations.of(context)!.translate('addDeal'),
          description:
              AppLocalizations.of(context)!.translate('addDealDescription'),
          align: ContentAlign.top,
          context: context,
        ),
    ]);
    //print('DealColumn: Initialized tutorial targets: ${targets.length}');
  }

  void _startTutorialLogic() async {
    if (!_isTutorialShown && !_isTutorialInProgress) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _tutorialStep = 0;
          //showTutorial();
        }
      });
    }
  }

  void showTutorial() async {
    if (_isTutorialInProgress) {
      //print('DealColumn: Tutorial already in progress, skipping');
      return;
    }

    if (targets.isEmpty) {
      //print('DealColumn: No targets available for tutorial, reinitializing');
      _initTutorialTargets();
      if (targets.isEmpty) return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShownDealColumn') ?? false;

    if (isTutorialShown || _isTutorialShown) {
      //print('DealColumn: Tutorial conditions not met');
      return;
    }

    setState(() {
      _isTutorialInProgress = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));

    List<TargetFocus> currentTargets = [];
    bool isLastStep = false;

    switch (_tutorialStep) {
      case 0:
        currentTargets = targets
            .where((t) => t.identify == "DealCard" || t.identify == "Dropdown")
            .toList();
        break;
      case 1:
        if (_canCreateDeal) {
          currentTargets = targets
              .where((t) => t.identify == "FloatingActionButton")
              .toList();
          isLastStep = true;
        }
        break;
    }

    if (_dealBloc.state is DealDataLoaded) {
      final deals = (_dealBloc.state as DealDataLoaded)
          .deals
          .where((deal) => deal.statusId == widget.statusId)
          .toList();
      if (deals.isEmpty && _tutorialStep == 0 && _canCreateDeal) {
        currentTargets =
            targets.where((t) => t.identify == "FloatingActionButton").toList();
        isLastStep = true;
      }
    }

    if (currentTargets.isEmpty) {
      setState(() {
        _isTutorialInProgress = false;
      });
      return;
    }

    TutorialCoachMark(
      targets: currentTargets,
      textSkip: AppLocalizations.of(context)!.translate('skip'),
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontFamily: 'Gilroy',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
          Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
        ],
      ),
      colorShadow: Color(0xff1E2E52),
      onSkip: () {
        prefs.setBool('isTutorialShownDealColumn', true);
        setState(() {
          _isTutorialShown = true;
          _isTutorialInProgress = false;
        });
        _completeTutorialAsync();
        return true;
      },
      onFinish: () async {
        if (isLastStep) {
          await prefs.setBool('isTutorialShownDealColumn', true);
          try {
            await _apiService.markPageCompleted("deals", "index");
            //print('DealColumn: Sent markPageCompleted for deals/index after finishing');
          } catch (e) {
            //print('DealColumn: Error marking page completed on finish: $e');
          }
          setState(() {
            _isTutorialShown = true;
            _isTutorialInProgress = false;
          });
        } else {
          setState(() {
            _tutorialStep++;
            _isTutorialInProgress = false;
          });
          //showTutorial();
        }
      },
    ).show(context: context);
  }

  Future<void> _completeTutorialAsync() async {
    try {
      await _apiService.markPageCompleted("deals", "index");
      //print('DealColumn: Sent markPageCompleted for deals/index after skipping');
    } catch (e) {
      //print('DealColumn: Error marking page completed: $e');
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent <= 0) return;

    final position = _scrollController.position;
    final reachedPaginationThreshold =
        position.pixels >= (position.maxScrollExtent - 200);

    if (reachedPaginationThreshold) {
      final currentState = _dealBloc.state;
      if (currentState is DealDataLoaded) {
        if (!_dealBloc.allDealsFetched &&
            !currentState.isLoadingMore &&
            !_dealBloc.isFetching) {
          _dealBloc
              .add(FetchMoreDeals(widget.statusId, currentState.currentPage));
        }
      }
    }
  }

  void _ensurePaginationCanContinue(DealDataLoaded state, List<Deal> deals) {
    if (!mounted || !_scrollController.hasClients) return;
    if (deals.isEmpty ||
        state.isLoadingMore ||
        _dealBloc.allDealsFetched ||
        _dealBloc.isFetching) {
      return;
    }
    if (_scrollController.position.maxScrollExtent > 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentState = _dealBloc.state;
      if (currentState is! DealDataLoaded) return;
      if (currentState.isLoadingMore ||
          _dealBloc.allDealsFetched ||
          _dealBloc.isFetching) {
        return;
      }
      _dealBloc.add(FetchMoreDeals(widget.statusId, currentState.currentPage));
    });
  }

// В DealColumn добавьте этот метод:
  Future<void> _onRefresh() async {
    // При обновлении заново загружаем сделки
    _dealBloc.add(FetchDealStatuses(salesFunnelId: widget.salesFunnelId));
    _dealBloc
        .add(FetchDeals(widget.statusId, salesFunnelId: widget.salesFunnelId));
    return Future.delayed(Duration(milliseconds: 500));
  }

  Widget _buildDealsList(List<Deal> deals) {
    final currentState = _dealBloc.state;
    final bool showPaginationLoader =
        currentState is DealDataLoaded && currentState.isLoadingMore && deals.isNotEmpty;

    if (deals.isNotEmpty) {
      return RefreshIndicator(
        color: Color(0xff1E2E52),
        backgroundColor: Colors.white,
        onRefresh: _onRefresh,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: deals.length + (showPaginationLoader ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= deals.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: PlayStoreImageLoading(
                    size: 56.0,
                    duration: Duration(milliseconds: 1000),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DealCard(
                key: index == 0 ? keyDealCard : null,
                dropdownKey: index == 0 ? keyDropdown : null,
                deal: deals[index],
                title: widget.title,
                statusId: widget.statusId,
                onStatusUpdated: (oldStatusId, newStatusId) {
                  if (oldStatusId == widget.statusId) {
                    _dealBloc.add(FetchDeals(
                      widget.statusId,
                      salesFunnelId: widget.salesFunnelId,
                    ));
                  }
                },
                onStatusId: (oldStatusId, newStatusId) {
                  widget.onStatusId(oldStatusId, newStatusId);
                },
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      color: Color(0xff1E2E52),
      backgroundColor: Colors.white,
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.4),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .translate('no_deal_in_selected_status'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<DealBloc, DealState>(
        builder: (context, state) {
          if (state is DealLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          } else if (state is DealDataLoaded) {
            final deals = state.deals
                .where((deal) => deal.statusId == widget.statusId)
                .toList();

            _ensurePaginationCanContinue(state, deals);

            if (deals.isNotEmpty) {
              return _buildDealsList(deals);
            }

            return FutureBuilder<List<Deal>>(
              future: DealCache.getDealsForStatus(widget.statusId),
              builder: (context, snapshot) {
                final cachedDeals = snapshot.data ?? const <Deal>[];
                return _buildDealsList(cachedDeals);
              },
            );
          } else if (state is DealError) {
            // Обработка ошибок...
            return const SizedBox();
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: _canCreateDeal
          ? FloatingActionButton(
              key: keyFloatingActionButton,
              onPressed: () {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DealAddScreen(statusId: widget.statusId),
                    ),
                  ).then((_) {
                    _dealBloc.add(FetchDeals(
                      widget.statusId,
                      salesFunnelId: widget.salesFunnelId,
                    ));
                  });
                }
              },
              backgroundColor: Color(0xff1E2E52),
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
