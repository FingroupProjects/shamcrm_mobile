import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/screens/lead/tabBar/contact_list_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_add_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class LeadColumn extends StatefulWidget {
  final int statusId;
  final String title;
  final Function(int) onStatusId;
  final bool isLeadScreenTutorialCompleted;

  LeadColumn({
    required this.statusId,
    required this.title,
    required this.onStatusId,
    required this.isLeadScreenTutorialCompleted,
  });

  @override
  _LeadColumnState createState() => _LeadColumnState();
}

class _LeadColumnState extends State<LeadColumn> {
  bool _hasPermissionToAddLead = false;
  bool _isSwitch = false;
  final ApiService _apiService = ApiService();
  late final LeadBloc _leadBloc;

  List<TargetFocus> targets = [];

  final GlobalKey keyLeadCard = GlobalKey();
  final GlobalKey keyStatusDropdown = GlobalKey();
  final GlobalKey keyFloatingActionButton = GlobalKey();

  bool _isTutorialShown = false; // Единый флаг для туториала
  bool _isTutorialInProgress = false; // Защита от повторного вызова
  int _tutorialStep = 0; // Шаги для порядка показа
  bool _isInitialized = false; // Флаг для отслеживания инициализации

  @override
  void initState() {
    super.initState();
    _leadBloc = LeadBloc(_apiService)..add(FetchLeads(widget.statusId));
    _checkPermission();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initTutorialTargets(); // Переносим сюда

      // Получаем SharedPreferences асинхронно
      final prefs = await SharedPreferences.getInstance();
      _isSwitch = prefs.getBool('switchContact') ?? false;

      // Если туториал LeadScreen завершен, запускаем через 500мс
      if (widget.isLeadScreenTutorialCompleted && !_isTutorialShown && !_isTutorialInProgress) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            _tutorialStep = 0;
            showTutorial();
          }
        });
      }
      _isInitialized = true; // Устанавливаем флаг, чтобы не повторять
    }
  }

  void _initTutorialTargets() {
    targets.clear();
    targets.addAll([
      createTarget(
        identify: "LeadCard",
        keyTarget: keyLeadCard,
        title: AppLocalizations.of(context)!.translate('tutorial_lead_card_title'),
        description: AppLocalizations.of(context)!.translate('tutorial_lead_card_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.below,
        contentPadding: EdgeInsets.only(top: 50),
      ),
      createTarget(
        identify: "StatusDropdown",
        keyTarget: keyStatusDropdown,
        title: AppLocalizations.of(context)!.translate('tutorial_lead_status_title'),
        description: AppLocalizations.of(context)!.translate('tutorial_lead_status_description'),
        align: ContentAlign.bottom,
        context: context,
      ),
      if (_hasPermissionToAddLead)
        createTarget(
          identify: "FloatingActionButton",
          keyTarget: keyFloatingActionButton,
          title: AppLocalizations.of(context)!.translate('tutorial_lead_button_title'),
          description: AppLocalizations.of(context)!.translate('tutorial_lead_button_description'),
          align: ContentAlign.top,
          context: context,
        ),
    ]);
  }

  void showTutorial() async {
    if (_isTutorialInProgress) {
      print('Tutorial already in progress, skipping');
      return;
    }

    if (targets.isEmpty) {
      print('No targets available for tutorial, skipping');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShownLeadColumn') ?? false;

    if (isTutorialShown || _isTutorialShown) {
      print('Tutorial conditions not met');
      return;
    }

    setState(() {
      _isTutorialInProgress = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));

    List<TargetFocus> currentTargets = [];
    bool isLastStep = false;

    switch (_tutorialStep) {
      case 0: // LeadCard и StatusDropdown вместе
        currentTargets = targets
            .where((t) => t.identify == "LeadCard" || t.identify == "StatusDropdown")
            .toList();
        break;
      case 1: // FloatingActionButton
        if (_hasPermissionToAddLead) {
          currentTargets = targets.where((t) => t.identify == "FloatingActionButton").toList();
          isLastStep = true;
        }
        break;
    }

    // Если нет лидов, сразу показываем FAB
    if (_leadBloc.state is LeadDataLoaded) {
      final leads = (_leadBloc.state as LeadDataLoaded).leads.where((lead) => lead.statusId == widget.statusId).toList();
      if (leads.isEmpty && _tutorialStep == 0 && _hasPermissionToAddLead) {
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
        prefs.setBool('isTutorialShownLeadColumn', true);
        setState(() {
          _isTutorialShown = true;
          _isTutorialInProgress = false;
        });
        return true;
      },
      onFinish: () {
        if (isLastStep) {
          prefs.setBool('isTutorialShownLeadColumn', true);
          setState(() {
            _isTutorialShown = true;
            _isTutorialInProgress = false;
          });
        } else {
          setState(() {
            _tutorialStep++;
            _isTutorialInProgress = false;
          });
          showTutorial(); // Переходим к следующему шагу
        }
      },
    ).show(context: context);
  }

  Future<void> _checkPermission() async {
    bool hasPermission = await _apiService.hasPermission('lead.create');
    setState(() {
      _hasPermissionToAddLead = hasPermission;
    });
  }

  Future<void> _onRefresh() async {
    BlocProvider.of<LeadBloc>(context).add(FetchLeadStatuses());
    _leadBloc.add(FetchLeads(widget.statusId));
    return Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _leadBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<LeadBloc, LeadState>(
          builder: (context, state) {
            if (state is LeadLoading) {
              return const Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } else if (state is LeadDataLoaded) {
              final leads = state.leads.where((lead) => lead.statusId == widget.statusId).toList();

              if (leads.isNotEmpty) {
                final ScrollController _scrollController = ScrollController();
                _scrollController.addListener(() {
                  if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
                      !_leadBloc.allLeadsFetched) {
                    _leadBloc.add(FetchMoreLeads(widget.statusId, state.currentPage));
                  }
                });

                return RefreshIndicator(
                  color: Color(0xff1E2E52),
                  backgroundColor: Colors.white,
                  onRefresh: _onRefresh,
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: AlwaysScrollableScrollPhysics(),
                          itemCount: leads.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: LeadCard(
                                key: index == 0 ? keyLeadCard : null,
                                dropdownStatusKey: index == 0 ? keyStatusDropdown : null,
                                lead: leads[index],
                                title: widget.title,
                                statusId: widget.statusId,
                                onStatusUpdated: () {
                                  _leadBloc.add(FetchLeads(widget.statusId));
                                },
                                onStatusId: (StatusLeadId) {
                                  widget.onStatusId(StatusLeadId);
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
                              AppLocalizations.of(context)!.translate('no_lead_in_status'),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Gilroy'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            } else if (state is LeadError) {
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
        floatingActionButton: _hasPermissionToAddLead
            ? FloatingActionButton(
                key: keyFloatingActionButton,
                onPressed: () {
                  if (_isSwitch) {
                    showModalBottomSheet(
                      backgroundColor: Colors.white,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (BuildContext context) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.translate('add_for_current_status'),
                                style: TextStyle(
                                  color: Color(0xff1E2E52),
                                  fontSize: 20,
                                  fontFamily: "Gilroy",
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Divider(color: Color(0xff1E2E52)),
                              ListTile(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.translate('new_lead_in_switch'),
                                      style: TextStyle(
                                        color: Color(0xff1E2E52),
                                        fontSize: 16,
                                        fontFamily: "Gilroy",
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      Icons.add,
                                      color: Color(0xff1E2E52),
                                      size: 25,
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LeadAddScreen(statusId: widget.statusId),
                                    ),
                                  ).then((_) => _leadBloc.add(FetchLeads(widget.statusId)));
                                },
                              ),
                              ListTile(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.translate('import_contact'),
                                      style: TextStyle(
                                        color: Color(0xff1E2E52),
                                        fontSize: 16,
                                        fontFamily: "Gilroy",
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      Icons.contacts,
                                      color: Color(0xff1E2E52),
                                      size: 25,
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ContactsScreen(statusId: widget.statusId),
                                    ),
                                  ).then((_) => _leadBloc.add(FetchLeads(widget.statusId)));
                                },
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeadAddScreen(statusId: widget.statusId),
                      ),
                    ).then((_) => _leadBloc.add(FetchLeads(widget.statusId)));
                  }
                },
                backgroundColor: Color(0xff1E2E52),
                child: Image.asset(
                  'assets/icons/tabBar/add.png',
                  width: 24,
                  height: 24,
                ),
              )
            : null,
      ),
    );
  }
}