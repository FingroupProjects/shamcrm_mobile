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

  const LeadColumn({
    required this.statusId,
    required this.title,
    required this.onStatusId,
    required this.isLeadScreenTutorialCompleted,
    Key? key,
  }) : super(key: key);

  @override
  _LeadColumnState createState() => _LeadColumnState();
}

class _LeadColumnState extends State<LeadColumn> {
  bool _hasPermissionToAddLead = false;
  bool _isSwitch = false;
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

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
    _checkPermission();
    _loadFeatureState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bloc = context.read<LeadBloc>();
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !bloc.allLeadsFetched) {
      final state = bloc.state;
      if (state is LeadDataLoaded) {
        bloc.add(FetchMoreLeads(widget.statusId, state.currentPage));
      }
    }
  }

  Future<void> _loadFeatureState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSwitch = prefs.getBool('switchContact') ?? false;
    });
  }

  Future<void> _checkPermission() async {
    try {
      final hasPermission = await _apiService.hasPermission('lead.create');
      setState(() {
        _hasPermissionToAddLead = hasPermission;
      });
    } catch (e) {
      setState(() {
        _hasPermissionToAddLead = false;
      });
    }
  }

  Future<void> _completeTutorialAsync() async {
    try {
      await _apiService.markPageCompleted("leads", "index");
    } catch (e) {
      debugPrint('LeadColumn: Error marking page completed: $e');
    }
  }

  Future<void> _onRefresh() async {
    context.read<LeadBloc>().add(FetchLeadStatuses(forceRefresh: true));
    context.read<LeadBloc>().add(FetchLeads(widget.statusId, ignoreCache: true));
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('LeadColumn: Building for statusId: ${widget.statusId}');
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: BlocBuilder<LeadBloc, LeadState>(
          builder: (context, state) {
            debugPrint('LeadColumn: BlocBuilder state: ${state.runtimeType}');

            if (state is LeadLoading) {
              return const Center(
                child: PlayStoreImageLoading(size: 80.0, duration: Duration(milliseconds: 1000)),
              );
            }

            if (state is LeadDataLoaded) {
              final leads = state.leads.where((l) => l.statusId == widget.statusId).toList();
              debugPrint('LeadColumn: Filtered ${leads.length} leads for status ${widget.statusId}');

              if (leads.isNotEmpty) {
                if (!_isInitialized && !_isTutorialShown && !widget.isLeadScreenTutorialCompleted) {
                  _isInitialized = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // _startTutorialLogic();
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: leads.length,
                  itemBuilder: (context, index) {
                    final lead = leads[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: LeadCard(
                        key: index == 0 ? keyLeadCard : null,
                        dropdownStatusKey: index == 0 ? keyStatusDropdown : null,
                        lead: lead,
                        title: widget.title,
                        statusId: widget.statusId,
                        onStatusUpdated: () async {
                          final newStatusId = lead.statusId;
                          if (newStatusId != widget.statusId) {
                            await LeadCache.moveLeadToStatus(lead, widget.statusId, newStatusId);
                            await LeadCache.updateLeadCountTemporary(widget.statusId, newStatusId);
                            context.read<LeadBloc>().add(RestoreCountsFromCache());
                          }
                        },
                        onStatusId: widget.onStatusId,
                      ),
                    );
                  },
                );
              } else {
                if (!_isInitialized && !_isTutorialShown && !widget.isLeadScreenTutorialCompleted) {
                  _isInitialized = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // _startTutorialLogic();
                  });
                }
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.translate('no_lead_in_status'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Gilroy'),
                      ),
                    ),
                  ],
                );
              }
            }

            if (state is LeadError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.translate(state.message),
                      style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox()],
            );
          },
        ),
      ),
    );
  }
}