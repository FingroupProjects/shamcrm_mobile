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

  LeadColumn({
    required this.statusId,
    required this.title,
    required this.onStatusId,
  });

  @override
  _LeadColumnState createState() => _LeadColumnState();
}

class _LeadColumnState extends State<LeadColumn> {
  bool _hasPermissionToAddLead = false;
  bool _isSwitch = false;
  final ApiService _apiService = ApiService();
  late final LeadBloc _leadBloc;

final GlobalKey keyLeadCard = GlobalKey();
final GlobalKey keyFloatingActionButton = GlobalKey();
  List<TargetFocus> targets = [];
  
  bool _isLeadCardTutorialShown = false; 
  bool _isFabTutorialShown = false; 



@override
void initState() {
  super.initState();
  _leadBloc = LeadBloc(_apiService)..add(FetchLeads(widget.statusId));
  _checkPermission();
  _loadFeatureState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    setState(() {
      _initTutorialTargets();
    });
  });
}

void _initTutorialTargets() {
  targets = [
    TargetFocus(
      identify: "LeadCard",
      keyTarget: keyLeadCard,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              Text(
                "Карточка лида",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 20.0,
                  fontFamily: 'Gilroy',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  "Это карточка лида. Здесь вы можете просматривать и управлять лидами.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    TargetFocus(
      identify: "FloatingActionButton",
      keyTarget: keyFloatingActionButton,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              Text(
                "Добавить лида",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 20.0,
                  fontFamily: 'Gilroy',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  "Нажмите «Добавить клиента» и заполните основные данные: имя, телефон, источник лида и ответственного менеджера. Чем больше информации — тем проще работать с клиентом.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ];
}


Future<void> _loadFeatureState() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {
    _isSwitch = prefs.getBool('switchContact') ?? false;
    _isLeadCardTutorialShown = prefs.getBool('isLeadCardTutorialShow') ?? false;
    _isFabTutorialShown = prefs.getBool('isFabTutorialShow') ?? false;
  });
}

bool _isLeadCardTutorialInProgress = false;
bool _isFabTutorialInProgress = false;

void showTutorial(String tutorialType) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
      await Future.delayed(const Duration(seconds: 1));

  if (tutorialType == "LeadCard" && !_isLeadCardTutorialShown && !_isLeadCardTutorialInProgress) {
    _isLeadCardTutorialInProgress = true; 
    TutorialCoachMark(
      targets: [targets.firstWhere((t) => t.identify == "LeadCard")],
      textSkip: 'Пропустить',
      colorShadow: Color(0xff1E2E52),
      onFinish: () {
        prefs.setBool('isLeadCardTutorialShow', true);
        setState(() {
          _isLeadCardTutorialShown = true;
        });
        _isLeadCardTutorialInProgress = false;
      },
    ).show(context: context);
  } else if (tutorialType == "FloatingActionButton" && !_isFabTutorialShown && !_isFabTutorialInProgress) {
    _isFabTutorialInProgress = true;
    TutorialCoachMark(
      targets: [targets.firstWhere((t) => t.identify == "FloatingActionButton")],
      textSkip: 'Пропустить',
      colorShadow: Color(0xff1E2E52),
      onFinish: () {
        prefs.setBool('isFabTutorialShow', true);
        setState(() {
          _isFabTutorialShown = true;
        });
        _isFabTutorialInProgress = false; 
      },
    ).show(context: context);
  }
}

  @override
  void dispose() {
    _leadBloc.close();
    super.dispose();
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

              if (!_isLeadCardTutorialShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showTutorial("LeadCard");
                });
              }

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
            } 
            else {

               if (!_isFabTutorialShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showTutorial("FloatingActionButton");
                });
              }

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
