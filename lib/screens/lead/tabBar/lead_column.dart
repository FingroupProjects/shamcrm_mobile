import 'package:crm_task_manager/screens/lead/lead_cache.dart';
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
  final ScrollController _scrollController = ScrollController();

  List<TargetFocus> targets = [];
  final GlobalKey keyLeadCard = GlobalKey();
  final GlobalKey keyStatusDropdown = GlobalKey();
  final GlobalKey keyFloatingActionButton = GlobalKey();

  bool _isTutorialShown = false;
  bool _isTutorialInProgress = false;
  int _tutorialStep = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _leadBloc = LeadBloc(_apiService)..add(FetchLeads(widget.statusId));
    _checkPermission();
    _loadFeatureState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_leadBloc.allLeadsFetched) {
        _leadBloc.add(FetchMoreLeads(
            widget.statusId, (_leadBloc.state as LeadDataLoaded).currentPage));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _leadBloc.close();
    super.dispose();
  }

  Future<void> _loadFeatureState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSwitch = prefs.getBool('switchContact') ?? false;
    });
  }

  Future<void> _checkPermission() async {
    try {
      bool hasPermission = await _apiService.hasPermission('lead.create');
      setState(() {
        _hasPermissionToAddLead = hasPermission;
      });
    } catch (e) {
      print('LeadColumn: Error checking lead.create permission: $e');
      setState(() {
        _hasPermissionToAddLead = false;
      });
    }
  }

  // void _initTutorialTargets() {
  //   targets.clear();
  //   targets.addAll([
  //     createTarget(
  //       identify: "LeadCard",
  //       keyTarget: keyLeadCard,
  //       title: AppLocalizations.of(context)!.translate('tutorial_lead_card_title'),
  //       description: AppLocalizations.of(context)!.translate('tutorial_lead_card_description'),
  //       align: ContentAlign.bottom,
  //       context: context,
  //       contentPosition: ContentPosition.below,
  //       contentPadding: EdgeInsets.only(top: 50),
  //     ),
  //     createTarget(
  //       identify: "StatusDropdown",
  //       keyTarget: keyStatusDropdown,
  //       title: AppLocalizations.of(context)!.translate('tutorial_lead_status_title'),
  //       description: AppLocalizations.of(context)!.translate('tutorial_lead_status_description'),
  //       align: ContentAlign.bottom,
  //       context: context,
  //     ),
  //     if (_hasPermissionToAddLead)
  //       createTarget(
  //         identify: "FloatingActionButton",
  //         keyTarget: keyFloatingActionButton,
  //         title: AppLocalizations.of(context)!.translate('tutorial_lead_button_title'),
  //         description: AppLocalizations.of(context)!.translate('tutorial_lead_button_description'),
  //         align: ContentAlign.top,
  //         context: context,
  //       ),
  //   ]);
  // }

  // void _startTutorialLogic() async {
  //   if (!_isTutorialShown && !_isTutorialInProgress) {
  //     Future.delayed(Duration(milliseconds: 500), () {
  //       if (mounted) {
  //         _tutorialStep = 0;
  //         showTutorial();
  //       }
  //     });
  //   }
  // }

  // void showTutorial() async {
  //   if (_isTutorialInProgress) {
  //     return;
  //   }

  //   if (targets.isEmpty) {
  //     _initTutorialTargets();
  //     if (targets.isEmpty) return;
  //   }

  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   bool isTutorialShown = prefs.getBool('isTutorialShownLeadColumn') ?? false;

  //   if (isTutorialShown || _isTutorialShown) {
  //     return;
  //   }

  //   setState(() {
  //     _isTutorialInProgress = true;
  //   });
  //   await Future.delayed(const Duration(milliseconds: 500));

  //   List<TargetFocus> currentTargets = [];
  //   bool isLastStep = false;

  //   switch (_tutorialStep) {
  //     case 0:
  //       currentTargets = targets
  //           .where((t) => t.identify == "LeadCard" || t.identify == "StatusDropdown")
  //           .toList();
  //       break;
  //     case 1:
  //       if (_hasPermissionToAddLead) {
  //         currentTargets = targets.where((t) => t.identify == "FloatingActionButton").toList();
  //         isLastStep = true;
  //       }
  //       break;
  //   }

  //   if (_leadBloc.state is LeadDataLoaded) {
  //     final leads = (_leadBloc.state as LeadDataLoaded).leads.where((lead) => lead.statusId == widget.statusId).toList();
  //     if (leads.isEmpty && _tutorialStep == 0 && _hasPermissionToAddLead) {
  //       currentTargets = targets.where((t) => t.identify == "FloatingActionButton").toList();
  //       isLastStep = true;
  //     }
  //   }

  //   if (currentTargets.isEmpty) {
  //     setState(() {
  //       _isTutorialInProgress = false;
  //     });
  //     return;
  //   }

  //   TutorialCoachMark(
  //     targets: currentTargets,
  //     textSkip: AppLocalizations.of(context)!.translate('skip'),
  //     textStyleSkip: TextStyle(
  //       color: Colors.white,
  //       fontFamily: 'Gilroy',
  //       fontSize: 20,
  //       fontWeight: FontWeight.w600,
  //       shadows: [
  //         Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
  //         Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
  //         Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
  //         Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
  //       ],
  //     ),
  //     colorShadow: Color(0xff1E2E52),
  //     onSkip: () {
  //       prefs.setBool('isTutorialShownLeadColumn', true);
  //       setState(() {
  //         _isTutorialShown = true;
  //         _isTutorialInProgress = false;
  //       });
  //       _completeTutorialAsync();
  //       return true;
  //     },
  //     onFinish: () async {
  //       if (isLastStep) {
  //         await prefs.setBool('isTutorialShownLeadColumn', true);
  //         try {
  //           await _apiService.markPageCompleted("leads", "index");
  //         } catch (e) {
  //           print('LeadColumn: Error marking page completed on finish: $e');
  //         }
  //         setState(() {
  //           _isTutorialShown = true;
  //           _isTutorialInProgress = false;
  //         });
  //       } else {
  //         setState(() {
  //           _tutorialStep++;
  //           _isTutorialInProgress = false;
  //         });
  //         showTutorial();
  //       }
  //     },
  //   ).show(context: context);
  // }

  Future<void> _completeTutorialAsync() async {
    try {
      await _apiService.markPageCompleted("leads", "index");
    } catch (e) {
      print('LeadColumn: Error marking page completed on skip: $e');
    }
  }

  Future<void> _onRefresh() async {
    BlocProvider.of<LeadBloc>(context).add(FetchLeadStatuses());
    _leadBloc.add(FetchLeads(widget.statusId));
    return Future.delayed(Duration(milliseconds: 1));
  }

 @override
Widget build(BuildContext context) {
  print('LeadColumn: Building widget for statusId: ${widget.statusId}');
  return BlocProvider.value(
    value: _leadBloc,
    child: Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<LeadBloc, LeadState>(
        builder: (context, state) {
          print('LeadColumn: BlocBuilder state: ${state.runtimeType}');
          if (state is LeadLoading) {
            return const Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: Duration(milliseconds: 1000),
              ),
            );
          } else if (state is LeadDataLoaded) {
            final leads = state.leads
                .where((lead) => lead.statusId == widget.statusId)
                .toList();
            print(
                'LeadColumn: LeadDataLoaded, leads count for statusId ${widget.statusId}: ${leads.length}');

            if (leads.isNotEmpty) {
              if (!_isInitialized &&
                  !_isTutorialShown &&
                  !widget.isLeadScreenTutorialCompleted) {
                _isInitialized = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // _startTutorialLogic();
                });
              }
              return Column(
                children: [
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: leads.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: LeadCard(
                            key: index == 0 ? keyLeadCard : null,
                            dropdownStatusKey:
                                index == 0 ? keyStatusDropdown : null,
                            lead: leads[index],
                            title: widget.title,
                            statusId: widget.statusId,
                            onStatusUpdated: () async {
                              print('LeadColumn: Lead status updated for lead: ${leads[index].id}');
                              final newStatusId = leads[index].statusId;
                              if (newStatusId != widget.statusId) {
                                await LeadCache.moveLeadToStatus(
                                  leads[index],
                                  widget.statusId,
                                  newStatusId,
                                );
                                print('LeadColumn: Moved lead ${leads[index].id} from status ${widget.statusId} to $newStatusId in cache');
                                await LeadCache.updateLeadCountTemporary(widget.statusId, newStatusId);
                                final currentBloc = BlocProvider.of<LeadBloc>(context);
                                currentBloc.add(RestoreCountsFromCache());
                              }
                            },
                            onStatusId: (StatusLeadId) {
                              print(
                                  'LeadColumn: onStatusId called with id: $StatusLeadId');
                              widget.onStatusId(StatusLeadId);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else {
              if (!_isInitialized &&
                  !_isTutorialShown &&
                  !widget.isLeadScreenTutorialCompleted) {
                _isInitialized = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // _startTutorialLogic();
                });
              }
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .translate('no_lead_in_status'),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          } else if (state is LeadError) {
            print('LeadColumn: LeadError state: ${state.message}');
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
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox()],
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [SizedBox()],
          );
        },
      ),
      floatingActionButton: _hasPermissionToAddLead
          ? FloatingActionButton(
              key: keyFloatingActionButton,
              onPressed: () {
                print('LeadColumn: FloatingActionButton pressed');
                if (_isSwitch) {
                  showModalBottomSheet(
                    backgroundColor: Colors.white,
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (BuildContext context) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .translate('add_for_current_status'),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .translate('new_lead_in_switch'),
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
                                    builder: (context) => LeadAddScreen(
                                        statusId: widget.statusId),
                                  ),
                                ).then((_) => _leadBloc
                                    .add(FetchLeads(widget.statusId)));
                              },
                            ),
                            ListTile(
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .translate('import_contact'),
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
                                    builder: (context) => ContactsScreen(
                                        statusId: widget.statusId),
                                  ),
                                ).then((_) => _leadBloc
                                    .add(FetchLeads(widget.statusId)));
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
                      builder: (context) =>
                          LeadAddScreen(statusId: widget.statusId),
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