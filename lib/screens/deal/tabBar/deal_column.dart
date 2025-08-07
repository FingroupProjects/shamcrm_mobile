import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_add_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class DealColumn extends StatefulWidget {
  final int statusId;
  final String title;
  final Function(int) onStatusId;
  final int? managerId;
  final bool isDealScreenTutorialCompleted;

  DealColumn({
    required this.statusId,
    required this.title,
    required this.onStatusId,
    this.managerId,
    required this.isDealScreenTutorialCompleted,
  });

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
    _dealBloc = DealBloc(_apiService)..add(FetchDeals(widget.statusId));
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
    if (widget.isDealScreenTutorialCompleted && !_isTutorialShown && !_isTutorialInProgress) {
      _startTutorialLogic();
    }
  }

  @override
  void didUpdateWidget(covariant DealColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDealScreenTutorialCompleted != oldWidget.isDealScreenTutorialCompleted &&
        widget.isDealScreenTutorialCompleted &&
        !_isTutorialShown &&
        !_isTutorialInProgress) {
      _startTutorialLogic();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _dealBloc.close();
    super.dispose();
  }

  Future<void> _checkCreatePermission() async {
    if (_permissionChecked && _canCreateDeal) {
      print('DealColumn: Permission already checked and available, skipping');
      return;
    }

    try {
      print('DealColumn: Checking deal.create permission...');
      final canCreate = await _apiService.hasPermission('deal.create');
      print('DealColumn: deal.create permission result: $canCreate');
      if (mounted) {
        setState(() {
          _canCreateDeal = canCreate;
          _permissionChecked = true;
        });
        print('DealColumn: Updated _canCreateDeal: $_canCreateDeal');
        print('DealColumn: Set _permissionChecked: $_permissionChecked');
      }
    } catch (e) {
      print('DealColumn: Error checking deal.create permission: $e');
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
        description: AppLocalizations.of(context)!.translate('dealCardDescription'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.below,
        contentPadding: EdgeInsets.only(top: 50),
      ),
      createTarget(
        identify: "Dropdown",
        keyTarget: keyDropdown,
        title: AppLocalizations.of(context)!.translate('statusManagement'),
        description: AppLocalizations.of(context)!.translate('statusManagementDescription'),
        align: ContentAlign.bottom,
        context: context,
      ),
      if (_canCreateDeal)
        createTarget(
          identify: "FloatingActionButton",
          keyTarget: keyFloatingActionButton,
          title: AppLocalizations.of(context)!.translate('addDeal'),
          description: AppLocalizations.of(context)!.translate('addDealDescription'),
          align: ContentAlign.top,
          context: context,
        ),
    ]);
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
      print('DealColumn: Tutorial already in progress, skipping');
      return;
    }

    if (targets.isEmpty) {
      print('DealColumn: No targets available for tutorial, reinitializing');
      _initTutorialTargets();
      if (targets.isEmpty) return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShownDealColumn') ?? false;

    if (isTutorialShown || _isTutorialShown) {
      print('DealColumn: Tutorial conditions not met');
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
          currentTargets = targets.where((t) => t.identify == "FloatingActionButton").toList();
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
        currentTargets = targets.where((t) => t.identify == "FloatingActionButton").toList();
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
            print('DealColumn: Sent markPageCompleted for deals/index after finishing');
          } catch (e) {
            print('DealColumn: Error marking page completed on finish: $e');
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
      print('DealColumn: Sent markPageCompleted for deals/index after skipping');
    } catch (e) {
      print('DealColumn: Error marking page completed: $e');
    }
  }

  Future<void> _onRefresh() async {
    BlocProvider.of<DealBloc>(context).add(FetchDealStatuses());
    _dealBloc.add(FetchDeals(widget.statusId));
    return Future.delayed(Duration(milliseconds: 1));
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final currentState = _dealBloc.state;
      if (currentState is DealDataLoaded) {
        if (!_dealBloc.allDealsFetched) {
          _dealBloc.add(FetchMoreDeals(widget.statusId, currentState.currentPage));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ DealColumn: Rendering - statusId: ${widget.statusId}, _canCreateDeal: $_canCreateDeal, _permissionChecked: $_permissionChecked');
    return BlocProvider.value(
      value: _dealBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<DealBloc, DealState>(
          builder: (context, state) {
            print('🏗️ DealColumn: BlocBuilder - state: ${state.runtimeType}');
            if (state is DealLoading) {
              return const Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } else if (state is DealDataLoaded) {
              final deals = state.deals.where((deal) => deal.statusId == widget.statusId).toList();
              print('📋 DealColumn: DealDataLoaded - deals count: ${deals.length} for statusId: ${widget.statusId}');
              if (deals.isNotEmpty) {
                return RefreshIndicator(
                  color: Color(0xff1E2E52),
                  backgroundColor: Colors.white,
                  onRefresh: _onRefresh,
                  child: Column(
                    children: [
                      SizedBox(height: 15),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: AlwaysScrollableScrollPhysics(),
                          itemCount: deals.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: DealCard(
                                key: index == 0 ? keyDealCard : null,
                                dropdownKey: index == 0 ? keyDropdown : null,
                                deal: deals[index],
                                title: widget.title,
                                statusId: widget.statusId,
                                onStatusUpdated: () {
                                  _dealBloc.add(FetchDeals(widget.statusId));
                                },
                                onStatusId: (StatusDealId) {
                                  widget.onStatusId(StatusDealId);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return RefreshIndicator(
                  backgroundColor: Colors.white,
                  color: Color(0xff1E2E52),
                  onRefresh: _onRefresh,
                  child: ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.translate('no_deal_in_selected_status'),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Gilroy'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            } else if (state is DealError) {
              print('❌ DealColumn: DealError: ${state.message}');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.translate(state.message),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 3),
                  ),
                );
              });
            }
            return Container();
          },
        ),
        floatingActionButton: _canCreateDeal
            ? FloatingActionButton(
                key: keyFloatingActionButton,
                onPressed: () {
                  print('➕ DealColumn: FloatingActionButton pressed');
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DealAddScreen(statusId: widget.statusId),
                      ),
                    ).then((_) {
                      _dealBloc.add(FetchDeals(widget.statusId));
                    });
                  }
                },
                backgroundColor: Color(0xff1E2E52),
                child: Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }
}